import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';

class AdminApprovalRequestsPage extends StatefulWidget {
  final String? adminDepartment;

  const AdminApprovalRequestsPage({super.key, this.adminDepartment});

  @override
  State<AdminApprovalRequestsPage> createState() => _AdminApprovalRequestsPageState();
}

class _AdminApprovalRequestsPageState extends State<AdminApprovalRequestsPage> {
  List<models.Document> _pendingRequests = [];
  bool _isLoading = true;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _sub = AppwriteService.realtime
        .subscribe(['databases.${AppwriteService.databaseId}.collections.users.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchRequests();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    try {
      // In-memory filter fallback approach for safety if index is missing
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [
          Query.limit(5000), // Get recent users and filter
        ],
      );
      
      if (mounted) {
        setState(() {
          _pendingRequests = result.documents.where((doc) {
            final data = doc.data;
            final isPending = data['status'] == 'pending';
            final isStudent = data['role'] == 'student' || data['role'] == null || data['role'] == '';
            final matchDept = widget.adminDepartment == null || widget.adminDepartment!.isEmpty || data['department'] == widget.adminDepartment;
            return isPending && isStudent && matchDept;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(models.Document doc) async {
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        documentId: doc.$id,
        data: {'status': 'active'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student approved successfully.')),
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(models.Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Decline Request"),
        content: const Text("Are you sure you want to decline and delete this registration? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Decline & Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AppwriteService.databases.deleteDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: 'users',
          documentId: doc.$id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration declined and record deleted.')),
          );
          _fetchRequests();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete record: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Pending Registrations",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
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
                    : _pendingRequests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _pendingRequests.length,
                            itemBuilder: (context, index) => _buildRequestCard(_pendingRequests[index]),
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
          Icon(Icons.how_to_reg, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            "All Caught Up!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no pending registration requests for your department.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(models.Document doc) {
    final data = doc.data;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  profilePictureId: data['profilePictureId'],
                  fallbackName: data['name'] ?? 'Unknown',
                  radius: 26,
                  backgroundColor: AppTheme.kGreen.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.kGreen,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown Name',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "ID: ${data['username']}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "PENDING",
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['department'] ?? 'No Department Specified',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(doc),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Decline"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(doc),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


