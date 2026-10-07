import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'services/leave_service.dart';
import 'leave_request_page.dart';

class LeaveManagementPage extends StatefulWidget {
  final String userId;
  final String userName;
  final int userLevel;

  const LeaveManagementPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userLevel,
  });

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<models.Document> _myRequests = [];
  List<models.Document> _pendingApprovals = [];
  bool _loadingMy = true;
  bool _loadingApprovals = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyRequests();
    _fetchApprovals();
  }

  Future<void> _fetchMyRequests() async {
    try {
      final res = await LeaveService.getMyRequests(widget.userId);
      if (mounted) {
        setState(() {
          _myRequests = res.documents;
          _loadingMy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  Future<void> _fetchApprovals() async {
    try {
      // Hierarchy: Level 1 is top admin, Level 3 is class-level.
      // A Level 3 admin submits to Level 2; Level 2 submits to Level 1.
      // So if I am Level 2, I approve requests from Level 3 (approverLevel == 2).
      // approverLevel in document is the level of the person WHO SHOULD APPROVE.
      final res = await LeaveService.getPendingRequests(
        widget.userLevel,
        approverId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _pendingApprovals = res;
          _loadingApprovals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingApprovals = false);
    }
  }

  Future<void> _handleAction(String docId, String status) async {
    try {
      await LeaveService.updateStatus(
        docId,
        status,
        widget.userName,
        actionById: widget.userId,
      );
      _fetchApprovals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request $status")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
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
        title: Text("Leave System",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.kGreen,
          labelColor: AppTheme.kGreen,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "My Requests"),
            Tab(text: "Approvals"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeaveRequestPage(
                userId: widget.userId,
                userName: widget.userName,
                userLevel: widget.userLevel,
              ),
            ),
          );
          if (res == true) _fetchMyRequests();
        },
        backgroundColor: AppTheme.kGreen,
        icon: const Icon(Icons.add),
        label: const Text("Request Leave"),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyRequestsTab(),
            _buildApprovalsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_loadingMy) return _loading();
    if (_myRequests.isEmpty) return _empty("No requests yet.");

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _myRequests.length,
      itemBuilder: (context, i) {
        final doc = _myRequests[i];
        final data = doc.data;
        return _requestCard(data, isApproval: false);
      },
    );
  }

  Widget _buildApprovalsTab() {
    if (_loadingApprovals) return _loading();
    if (_pendingApprovals.isEmpty) return _empty("No pending approvals.");

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingApprovals.length,
      itemBuilder: (context, i) {
        final doc = _pendingApprovals[i];
        final data = doc.data;
        return Column(
          children: [
            _requestCard(data, isApproval: true, docId: doc.$id),
          ],
        );
      },
    );
  }

  Widget _requestCard(Map<String, dynamic> data,
      {required bool isApproval, String? docId}) {
    final status = data['status'] ?? 'pending';
    final type = data['leaveType'] ?? 'Medical';
    final start = DateTime.parse(data['startDate']);
    final end = DateTime.parse(data['endDate']);

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'denied':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(data['createdAt'])),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(isApproval ? "From: ${data['userName']}" : type,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            if (isApproval)
              Text("Type: $type",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Reason: ${data['reason']}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (isApproval && status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction(docId!, 'denied'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Deny"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction(docId!, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Center(
      child: CircularProgressIndicator(color: AppTheme.kGreen));

  Widget _empty(String msg) => Center(
        child: Text(msg, style: const TextStyle(color: Colors.grey)),
      );
}

