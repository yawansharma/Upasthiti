import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, Center;
import 'dart:typed_data';
import 'dart:convert';

import 'app_theme.dart';
import 'main.dart';
import 'services/appwrite_service.dart';
import 'services/leave_service.dart';
import 'services/export_service.dart';
import 'components/user_avatar.dart';
import 'components/admin_presence_card.dart';

const Color _kHRAccent = Color(0xFF8A7A2A);
final String _kDb = AppwriteService.databaseId;

class HrAdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;
  final String adminDepartment;

  const HrAdminHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
    required this.adminDepartment,
  });

  @override
  State<HrAdminHomePage> createState() => _HrAdminHomePageState();
}

class _HrAdminHomePageState extends State<HrAdminHomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            AdminPresenceCard(
              adminId: widget.adminId,
              adminName: widget.adminName,
              role: 'hrAdmin',
              level: 0,
              department: widget.adminDepartment,
              accent: _kHRAccent,
              requiresLogoutVerification: true,
              onSignedOut: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(35)),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            _HRDashboardTab(
                                adminId: widget.adminId,
                                adminDepartment: widget.adminDepartment,
                                onNavigate: (i) => setState(() => _tabIndex = i)),
                            _HRApprovalsTab(
                                adminId: widget.adminId,
                                adminDepartment: widget.adminDepartment),
                            _HRLeaveTab(
                                adminId: widget.adminId,
                                adminName: widget.adminName),
                            _HRReportsTab(
                                adminId: widget.adminId,
                                adminDepartment: widget.adminDepartment),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kHRAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_alt_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HR Admin",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.adminName,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kHRAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kHRAccent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              "HR",
              style: TextStyle(
                color: _kHRAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
            label: const Text("Logout",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (Icons.dashboard_outlined, "Dashboard"),
      (Icons.how_to_reg_outlined, "Approvals"),
      (Icons.event_busy_outlined, "Leave"),
      (Icons.bar_chart_outlined, "Reports"),
    ];
    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? _kHRAccent
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tabs[i].$1,
                        size: 20,
                        color: selected ? _kHRAccent : Colors.grey),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kHRAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kHRAccent),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _HRDashboardTab extends StatefulWidget {
  final String adminId;
  final String adminDepartment;
  final ValueChanged<int> onNavigate;

  const _HRDashboardTab(
      {required this.adminId,
      required this.adminDepartment,
      required this.onNavigate});

  @override
  State<_HRDashboardTab> createState() => _HRDashboardTabState();
}

class _HRDashboardTabState extends State<_HRDashboardTab> {
  int _pendingLeave = 0;
  int _pendingRegistrations = 0;
  int _totalStudents = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final results = await Future.wait([
        AppwriteService.databases.listDocuments(
          databaseId: _kDb,
          collectionId: 'leave_requests',
          queries: [Query.equal('status', 'pending'), Query.limit(1)],
        ),
        AppwriteService.databases.listDocuments(
          databaseId: _kDb,
          collectionId: 'users',
          queries: [
            Query.equal('status', 'pending'),
            Query.equal('role', 'student'),
            Query.limit(1),
          ],
        ),
        AppwriteService.databases.listDocuments(
          databaseId: _kDb,
          collectionId: 'users',
          queries: [
            Query.equal('role', 'student'),
            Query.limit(1),
          ],
        ),
      ]);
      if (mounted) {
        setState(() {
          _pendingLeave = results[0].total;
          _pendingRegistrations = results[1].total;
          _totalStudents = results[2].total;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kHRAccent));
    }
    return RefreshIndicator(
      color: _kHRAccent,
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "Overview",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "$_pendingLeave",
                  "Pending Leave",
                  Icons.event_busy_outlined,
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  "$_pendingRegistrations",
                  "Pending Approvals",
                  Icons.how_to_reg_outlined,
                  Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statCard(
            "$_totalStudents",
            "Total Students",
            Icons.school_outlined,
            _kHRAccent,
            wide: true,
          ),
          const SizedBox(height: 28),
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _actionCard(
            Icons.event_busy_outlined,
            "Review Leave Requests",
            "Approve or reject pending leave requests",
            Colors.orange.shade600,
            onTap: () => widget.onNavigate(2),
          ),
          const SizedBox(height: 10),
          _actionCard(
            Icons.how_to_reg_outlined,
            "Student Registrations",
            "Approve new student registration requests",
            Colors.blue.shade600,
            onTap: () => widget.onNavigate(1),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color,
      {bool wide = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: color)),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 10),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black87)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
    );
  }

  Widget _actionCard(
      IconData icon, String title, String subtitle, Color color,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Approvals (student registrations)
// ─────────────────────────────────────────────────────────────────────────────

class _HRApprovalsTab extends StatefulWidget {
  final String adminId;
  final String adminDepartment;

  const _HRApprovalsTab(
      {required this.adminId, required this.adminDepartment});

  @override
  State<_HRApprovalsTab> createState() => _HRApprovalsTabState();
}

class _HRApprovalsTabState extends State<_HRApprovalsTab> {
  List<models.Document> _pending = [];
  bool _loading = true;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _sub = AppwriteService.realtime.subscribe(
        ['databases.$_kDb.collections.users.documents']);
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
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [Query.limit(5000)],
      );
      if (mounted) {
        setState(() {
          _pending = result.documents.where((doc) {
            final d = doc.data;
            final isPending = d['status'] == 'pending';
            final isStudent = d['role'] == 'student' ||
                d['role'] == null ||
                d['role'] == '';
            return isPending && isStudent;
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(models.Document doc) async {
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
        data: {'status': 'active'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student approved.')));
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reject(models.Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Decline Registration"),
        content: const Text(
            "Decline and permanently delete this registration?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Decline"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AppwriteService.databases.deleteDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration declined.')));
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kHRAccent));
    }
    if (_pending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.how_to_reg,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              Text("All caught up!",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Text("No pending student registrations.",
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kHRAccent,
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pending.length,
        itemBuilder: (_, i) => _buildCard(_pending[i]),
      ),
    );
  }

  Widget _buildCard(models.Document doc) {
    final d = doc.data;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                profilePictureId: d['profilePictureId'],
                fallbackName: d['name'] ?? 'Unknown',
                radius: 24,
                backgroundColor: _kHRAccent.withValues(alpha: 0.1),
                foregroundColor: _kHRAccent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text("ID: ${d['username'] ?? '—'}",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("PENDING",
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if ((d['department'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(d['department'] as String,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(doc),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text("Decline"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(doc),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kHRAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Leave Requests
// ─────────────────────────────────────────────────────────────────────────────

class _HRLeaveTab extends StatefulWidget {
  final String adminId;
  final String adminName;
  const _HRLeaveTab({required this.adminId, required this.adminName});

  @override
  State<_HRLeaveTab> createState() => _HRLeaveTabState();
}

class _HRLeaveTabState extends State<_HRLeaveTab> {
  List<models.Document> _leaves = [];
  bool _loading = true;
  String _filter = 'all'; // all | pending | approved | rejected

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _loading = true);
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'leave_requests',
        queries: [Query.orderDesc('createdAt'), Query.limit(500)],
      );
      if (mounted) {
        setState(() {
          _leaves = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<models.Document> get _filtered {
    if (_filter == 'all') return _leaves;
    return _leaves
        .where((d) => d.data['status'] == _filter)
        .toList();
  }

  Future<void> _updateStatus(models.Document doc, String status) async {
    try {
      await LeaveService.updateStatus(
        doc.$id,
        status,
        widget.adminName,
        actionById: widget.adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Leave request $status.')));
        _fetchLeaves();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))));
        _fetchLeaves();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kHRAccent));
    }
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _kHRAccent,
                  onRefresh: _fetchLeaves,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildLeaveCard(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['all', 'pending', 'approved', 'rejected'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel
                      ? _kHRAccent
                      : _kHRAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? _kHRAccent
                        : _kHRAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  f[0].toUpperCase() + f.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _kHRAccent,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaveCard(models.Document doc) {
    final d = doc.data;
    final status = d['status'] as String? ?? 'pending';
    final leaveType = d['leaveType'] as String? ?? '—';
    final userName = d['userName'] as String? ?? d['userId'] as String? ?? '—';
    final reason = d['reason'] as String? ?? '';
    final isPending = status == 'pending';
    // Mirror LeaveService.updateStatus's own authorization rule: only an
    // unassigned request or one explicitly routed to this HR admin can
    // actually be actioned here. Everything else is view-only.
    final approverId = d['approverId'] as String?;
    final canAct = approverId == null ||
        approverId.isEmpty ||
        approverId == widget.adminId;

    String dateRange = '—';
    try {
      final start = DateTime.parse(d['startDate'] as String);
      final end = DateTime.parse(d['endDate'] as String);
      dateRange =
          "${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM yyyy').format(end)}";
    } catch (_) {}

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green.shade600;
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        break;
      default:
        statusColor = Colors.orange.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87)),
                    Text(leaveType,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.grey),
              const SizedBox(width: 5),
              Text(dateRange,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPending && !canAct) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    "Routed to another approver — view only.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],
          if (isPending && canAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(doc, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Reject",
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(doc, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Approve",
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No leave requests",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Reports (Attendance Export)
// ─────────────────────────────────────────────────────────────────────────────

class _HRReportsTab extends StatefulWidget {
  final String adminId;
  final String adminDepartment;

  const _HRReportsTab(
      {required this.adminId, required this.adminDepartment});

  @override
  State<_HRReportsTab> createState() => _HRReportsTabState();
}

class _HRReportsTabState extends State<_HRReportsTab> {
  List<Map<String, String>> _classes = [];
  String? _selectedClassId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _exporting = false;
  String? _lastExportPath;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'classes',
        queries: [Query.limit(100)],
      );
      if (mounted) {
        setState(() {
          _classes = result.documents
              .map((d) => {
                    'id': d.$id,
                    'name': d.data['name'] as String? ?? d.$id,
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final queries = <String>[
        Query.orderDesc('timestamp'),
        Query.limit(5000),
      ];
      if (_selectedClassId != null) {
        queries.add(Query.equal('classId', _selectedClassId!));
      }
      if (_startDate != null) {
        queries.add(Query.greaterThanEqual(
            'timestamp', _startDate!.toIso8601String()));
      }
      if (_endDate != null) {
        final end = _endDate!.add(const Duration(days: 1));
        queries.add(Query.lessThan('timestamp', end.toIso8601String()));
      }

      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: queries,
      );

      final timestamp =
          DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

      if (format == 'csv') {
        final rows = [
          [
            'Student ID',
            'Student Name',
            'Class',
            'Status',
            'Entry Type',
            'Geofence',
            'Timestamp'
          ],
          ...result.documents.map((doc) {
            final d = doc.data;
            return [
              d['userId'] ?? '',
              d['userName'] ?? '',
              d['className'] ?? d['classId'] ?? '',
              d['adminVerifiedStatus'] ?? '',
              d['entryStatus'] ?? '',
              d['isWithinGeofence'] == true ? 'Yes' : 'No',
              d['timestamp'] ?? '',
            ];
          }),
        ];
        final csv =
            const ListToCsvConverter().convert(rows.cast<List>());
        await ExportService.showExportOptions(
          context,
          bytes: Uint8List.fromList(utf8.encode(csv)),
          fileName: 'hr_attendance_$timestamp.csv',
        );
      } else {
        final excel = Excel.createExcel();
        final sheet = excel['Attendance'];
        final headers = [
          'Student ID',
          'Student Name',
          'Class',
          'Status',
          'Entry Type',
          'Geofence',
          'Timestamp'
        ];
        sheet.appendRow(
            headers.map((h) => TextCellValue(h)).toList());
        for (final doc in result.documents) {
          final d = doc.data;
          sheet.appendRow([
            TextCellValue(d['userId']?.toString() ?? ''),
            TextCellValue(d['userName']?.toString() ?? ''),
            TextCellValue(d['className']?.toString() ??
                d['classId']?.toString() ??
                ''),
            TextCellValue(
                d['adminVerifiedStatus']?.toString() ?? ''),
            TextCellValue(d['entryStatus']?.toString() ?? ''),
            TextCellValue(
                d['isWithinGeofence'] == true ? 'Yes' : 'No'),
            TextCellValue(d['timestamp']?.toString() ?? ''),
          ]);
        }
        final bytes = excel.encode();
        if (bytes != null) {
          await ExportService.showExportOptions(
            context,
            bytes: Uint8List.fromList(bytes),
            fileName: 'hr_attendance_$timestamp.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
        }
      }

      if (mounted) {
        setState(() {
          _exporting = false;
          _lastExportPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _exporting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kHRAccent),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Export Attendance",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          "Filter and download attendance records as CSV or Excel.",
          style:
              TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        // Class filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedClassId,
              hint: Text("All Classes",
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text("All Classes",
                        style: TextStyle(fontSize: 13))),
                ..._classes.map((c) => DropdownMenuItem(
                      value: c['id'],
                      child: Text(c['name']!,
                          style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: (v) =>
                  setState(() => _selectedClassId = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Date range
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _startDate != null
                  ? _kHRAccent.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _startDate != null
                    ? _kHRAccent.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: _startDate != null
                        ? _kHRAccent
                        : Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _startDate != null
                        ? "${DateFormat('dd MMM yyyy').format(_startDate!)} – "
                            "${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : '...'}"
                        : "Select date range (optional)",
                    style: TextStyle(
                      fontSize: 13,
                      color: _startDate != null
                          ? _kHRAccent
                          : Colors.grey,
                    ),
                  ),
                ),
                if (_startDate != null)
                  GestureDetector(
                    onTap: () => setState(
                        () {
                          _startDate = null;
                          _endDate = null;
                        }),
                    child: const Icon(Icons.close,
                        size: 16, color: _kHRAccent),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (_exporting)
          const Center(
              child: CircularProgressIndicator(color: _kHRAccent))
        else ...[
          ElevatedButton.icon(
            onPressed: () => _export('csv'),
            icon: const Icon(Icons.table_rows_outlined, size: 18),
            label: const Text("Export as CSV"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kHRAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _export('xlsx'),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text("Export as Excel"),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kHRAccent,
              side: const BorderSide(color: _kHRAccent),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
        if (_lastExportPath != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Export complete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(
                        _lastExportPath!.split('/').last,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _lastExportPath!));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Path copied!')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  color: Colors.green,
                  tooltip: "Copy path",
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
