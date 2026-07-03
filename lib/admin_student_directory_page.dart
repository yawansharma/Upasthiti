import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';

class AdminStudentDirectoryPage extends StatefulWidget {
  final String? adminDepartment;
  final String adminId;
  final List<models.Document> classes;
  final bool showInviteButton;
  final void Function(models.Document studentDoc)? onViewAttendance;

  const AdminStudentDirectoryPage({
    super.key,
    this.adminDepartment,
    required this.adminId,
    required this.classes,
    this.showInviteButton = true,
    this.onViewAttendance,
  });

  @override
  State<AdminStudentDirectoryPage> createState() => _AdminStudentDirectoryPageState();
}

class _AdminStudentDirectoryPageState extends State<AdminStudentDirectoryPage> {
  List<models.Document> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [
          Query.limit(5000),
        ],
      );
      
      if (mounted) {
        setState(() {
          _students = result.documents.where((doc) {
            final data = doc.data;
            final isActive = data['status'] == 'active';
            final isStudent = data['role'] == 'student' || data['role'] == null || data['role'] == '';
            
            final adminDept = widget.adminDepartment?.toLowerCase() ?? '';
            final userDept = (data['department'] as String?)?.toLowerCase() ?? '';
            final matchDept = adminDept.isEmpty || userDept.contains(adminDept);
            
            return isActive && isStudent && matchDept;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteStudent(models.Document studentDoc) async {
    if (widget.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You don't have any classes to invite to.")));
      return;
    }

    models.Document? selectedClass;
    
    if (widget.classes.length == 1) {
      selectedClass = widget.classes.first;
    } else {
      selectedClass = await showDialog<models.Document>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Select Class to Invite"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.classes.length,
                itemBuilder: (context, index) {
                  final c = widget.classes[index];
                  final name = c.data['className'] ?? c.$id;
                  return ListTile(
                    leading: const Icon(Icons.class_, color: AppTheme.kGreen),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          );
        }
      );
    }
    
    if (selectedClass == null) return;
    
    try {
      final data = selectedClass.data;
      final boundaryStr = data['boundary']?.toString() ?? '{}';
      Map<String, dynamic> boundary;
      try {
        boundary = jsonDecode(boundaryStr);
      } catch (_) {
        boundary = {};
      }
      
      List<dynamic> invited = boundary['invitedStudents'] ?? [];
      final studentId = studentDoc.data['username'] as String;
      
      // Also check if they are already in the class
      List<dynamic> currentStudents = data['studentIds'] ?? [];
      if (currentStudents.contains(studentId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student is already in this class.")));
        }
        return;
      }

      if (!invited.contains(studentId)) {
        invited.add(studentId);
        boundary['invitedStudents'] = invited;
        
        await AppwriteService.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: 'classes',
          documentId: selectedClass.$id,
          data: {
            'boundary': jsonEncode(boundary),
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invited ${studentDoc.data['name']} to ${selectedClass.data['className']}!")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student is already invited to this class.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to invite student.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((doc) {
      final name = (doc.data['name'] ?? '').toString().toLowerCase();
      final user = (doc.data['username'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || user.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Student Directory",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search students...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.kGreen))
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildStudentCard(filtered[index]),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            "No Students Found",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(models.Document doc) {
    final data = doc.data;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: UserAvatar(
          profilePictureId: data['profilePictureId'],
          fallbackName: data['name'] ?? 'Unknown',
          radius: 24,
          backgroundColor: AppTheme.kGreen.withValues(alpha: 0.1),
          foregroundColor: AppTheme.kGreen,
        ),
        title: Text(
          data['name'] ?? 'Unknown Name',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "ID: ${data['username']}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _detailRow(Icons.school_outlined, "Department", data['department'] ?? 'None'),
          const SizedBox(height: 12),
          _detailRow(Icons.location_on_outlined, "Location", "${data['latitude'] ?? 'N/A'}, ${data['longitude'] ?? 'N/A'}"),
          const SizedBox(height: 12),
          _detailRow(Icons.verified_user_outlined, "Status", (data['status'] ?? 'Unknown').toString().toUpperCase()),
          const SizedBox(height: 16),
          if (widget.showInviteButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _inviteStudent(doc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text("Invite to Class", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (widget.onViewAttendance != null) ...[
            if (widget.showInviteButton) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onViewAttendance!(doc),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8A6A6A),
                  side: const BorderSide(color: Color(0xFF8A6A6A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.history_outlined, size: 18),
                label: const Text("View Attendance", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6A8A73)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}


