import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'services/leave_service.dart';
import 'services/admin_hierarchy_service.dart';

class LeaveRequestPage extends StatefulWidget {
  final String userId;
  final String userName;
  final int userLevel;

  const LeaveRequestPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userLevel,
  });

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final _reasonCtrl = TextEditingController();
  String _selectedType = "Medical";
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  final List<String> _leaveTypes = [
    "Medical",
    "Casual",
    "Paid leave",
    "LTC - tour leave"
  ];

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a reason")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Logic: Request goes to person at Level X - 1 (lower number = higher rank)
      final approvers = await AdminHierarchyService.resolveApprovers(
        requesterId: widget.userId,
        requesterLevel: widget.userLevel,
      );
      if (approvers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No approver could be found for your account yet "
                "(you may not be assigned to a supervisor). Contact your "
                "institution admin before submitting leave.",
              ),
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      await LeaveService.submitRequest(
        userId: widget.userId,
        userName: widget.userName,
        leaveType: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonCtrl.text.trim(),
        approverLevel: widget.userLevel - 1,
        approverId: approvers.first,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Leave request submitted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit request: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.kGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.kDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text("Request Leave",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Leave Category"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _leaveTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel("Duration"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.kGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}",
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.edit, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel("Reason for Leave"),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: "Enter details here...",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppTheme.kGreen),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Submit Request",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
    );
  }
}

