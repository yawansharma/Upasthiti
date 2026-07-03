import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'main.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';

const Color _kSAAccent = Color(0xFF8A2A2A);
final String _kDb = AppwriteService.databaseId;

class SecurityAdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;

  const SecurityAdminHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
  });

  @override
  State<SecurityAdminHomePage> createState() =>
      _SecurityAdminHomePageState();
}

class _SecurityAdminHomePageState extends State<SecurityAdminHomePage> {
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(35)),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            _AuditLogsTab(adminId: widget.adminId),
                            _AnomaliesTab(adminId: widget.adminId),
                            _AccessControlTab(adminId: widget.adminId),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kSAAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Security Admin",
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
              color: _kSAAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kSAAccent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              "SA",
              style: TextStyle(
                color: _kSAAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout,
                color: Colors.white70, size: 20),
            tooltip: "Logout",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (Icons.history_outlined, "Audit Logs"),
      (Icons.warning_amber_outlined, "Anomalies"),
      (Icons.manage_accounts_outlined, "Access"),
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
                          ? _kSAAccent
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
                        color: selected ? _kSAAccent : Colors.grey),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected ? _kSAAccent : Colors.grey,
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: _kSAAccent),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text("Logout",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Audit Logs
// ─────────────────────────────────────────────────────────────────────────────

class _AuditLogsTab extends StatefulWidget {
  final String adminId;
  const _AuditLogsTab({required this.adminId});

  @override
  State<_AuditLogsTab> createState() => _AuditLogsTabState();
}

class _AuditLogsTabState extends State<_AuditLogsTab> {
  List<models.Document> _logs = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    try {
      final queries = <String>[
        Query.orderDesc('timestamp'),
        Query.limit(1000),
      ];
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
      if (mounted) {
        setState(() {
          _logs = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<models.Document> get _filtered {
    if (_searchQuery.isEmpty) return _logs;
    final q = _searchQuery.toLowerCase();
    return _logs.where((doc) {
      final d = doc.data;
      return (d['userId']?.toString().toLowerCase().contains(q) ??
              false) ||
          (d['userName']?.toString().toLowerCase().contains(q) ??
              false) ||
          (d['className']?.toString().toLowerCase().contains(q) ??
              false);
    }).toList();
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
          colorScheme:
              const ColorScheme.light(primary: _kSAAccent),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search by student or class…",
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon:
                        const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: _kSAAccent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _startDate != null
                        ? _kSAAccent.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _startDate != null
                          ? _kSAAccent.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color: _startDate != null
                          ? _kSAAccent
                          : Colors.grey),
                ),
              ),
              if (_startDate != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _fetchLogs();
                  },
                  child: const Icon(Icons.close,
                      size: 16, color: _kSAAccent),
                ),
              ],
            ],
          ),
        ),
        if (_loading)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kSAAccent)))
        else if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_outlined,
                        size: 70, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No logs found",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black45)),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: _kSAAccent,
              onRefresh: _fetchLogs,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _buildLogTile(_filtered[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogTile(models.Document doc) {
    final d = doc.data;
    final status = d['adminVerifiedStatus'] as String? ?? 'Pending';
    final inGeo = d['isWithinGeofence'] as bool? ?? true;
    final userName = d['userName'] as String? ??
        d['userId'] as String? ??
        '—';
    final className = d['className'] as String? ??
        d['classId'] as String? ??
        '—';

    String timeStr = '—';
    try {
      final ts = DateTime.parse(d['timestamp'] as String).toLocal();
      timeStr = DateFormat('dd MMM, HH:mm').format(ts);
    } catch (_) {}

    Color statusColor;
    switch (status) {
      case 'Present':
        statusColor = Colors.green.shade600;
        break;
      case 'Absent':
        statusColor = Colors.red.shade400;
        break;
      default:
        statusColor = Colors.grey.shade500;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !inGeo
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87)),
                Text(className,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!inGeo) ...[
                    const Icon(Icons.location_off_outlined,
                        size: 12, color: Colors.orange),
                    const SizedBox(width: 3),
                  ],
                  Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Anomalies (geofence violations)
// ─────────────────────────────────────────────────────────────────────────────

class _AnomaliesTab extends StatefulWidget {
  final String adminId;
  const _AnomaliesTab({required this.adminId});

  @override
  State<_AnomaliesTab> createState() => _AnomaliesTabState();
}

class _AnomaliesTabState extends State<_AnomaliesTab> {
  List<models.Document> _anomalies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnomalies();
  }

  Future<void> _fetchAnomalies() async {
    setState(() => _loading = true);
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: [
          Query.equal('isWithinGeofence', false),
          Query.orderDesc('timestamp'),
          Query.limit(500),
        ],
      );
      if (mounted) {
        setState(() {
          _anomalies = result.documents;
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
          child: CircularProgressIndicator(color: _kSAAccent));
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${_anomalies.length} geofence violation${_anomalies.length == 1 ? '' : 's'} detected",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        if (_anomalies.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 70, color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    Text("No anomalies detected",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      "All attendance records are within geofence boundaries.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: _kSAAccent,
              onRefresh: _fetchAnomalies,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _anomalies.length,
                itemBuilder: (_, i) =>
                    _buildAnomalyCard(_anomalies[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnomalyCard(models.Document doc) {
    final d = doc.data;
    final userName = d['userName'] as String? ??
        d['userId'] as String? ??
        '—';
    final userId = d['userId'] as String? ?? '—';
    final className = d['className'] as String? ??
        d['classId'] as String? ??
        '—';
    final status =
        d['adminVerifiedStatus'] as String? ?? 'Unknown';
    final entryType = d['entryStatus'] as String? ?? '';

    String timeStr = '—';
    try {
      final ts = DateTime.parse(d['timestamp'] as String).toLocal();
      timeStr =
          DateFormat('dd MMM yyyy, HH:mm').format(ts);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.orange.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_off_outlined,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87)),
                    Text(userId,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
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
                child: const Text(
                  "OUTSIDE FENCE",
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _infoChip(Icons.class_outlined, className),
                const SizedBox(width: 12),
                _infoChip(Icons.access_time_outlined, timeStr),
                if (entryType.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _infoChip(Icons.info_outline, entryType),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Marked status: $status",
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Access Control
// ─────────────────────────────────────────────────────────────────────────────

class _AccessControlTab extends StatefulWidget {
  final String adminId;
  const _AccessControlTab({required this.adminId});

  @override
  State<_AccessControlTab> createState() => _AccessControlTabState();
}

class _AccessControlTabState extends State<_AccessControlTab> {
  List<models.Document> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all'; // all | student | admin | other

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [Query.orderAsc('name'), Query.limit(2000)],
      );
      if (mounted) {
        setState(() {
          _users = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<models.Document> get _filtered {
    var list = _users;
    if (_roleFilter != 'all') {
      if (_roleFilter == 'admin') {
        list = list
            .where((d) =>
                d.data['role'] == 'admin' ||
                d.data['role'] == 'dean' ||
                d.data['role'] == 'officeAdmin' ||
                d.data['role'] == 'eventAdmin' ||
                d.data['role'] == 'hrAdmin' ||
                d.data['role'] == 'securityAdmin')
            .toList();
      } else if (_roleFilter == 'student') {
        list = list
            .where((d) =>
                d.data['role'] == 'student' ||
                d.data['role'] == null ||
                d.data['role'] == '')
            .toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((d) =>
              (d.data['name']?.toString().toLowerCase().contains(q) ??
                  false) ||
              (d.data['username']
                      ?.toString()
                      .toLowerCase()
                      .contains(q) ??
                  false))
          .toList();
    }
    return list;
  }

  Future<void> _toggleStatus(models.Document doc) async {
    final d = doc.data;
    final currentStatus = d['status'] as String? ?? 'active';
    final newStatus =
        currentStatus == 'disabled' ? 'active' : 'disabled';
    final name = d['name'] as String? ?? 'this user';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(newStatus == 'disabled'
            ? "Disable Account"
            : "Enable Account"),
        content: Text(newStatus == 'disabled'
            ? "Disable $name's account? They will not be able to log in."
            : "Re-enable $name's account?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'disabled'
                  ? Colors.red
                  : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
                newStatus == 'disabled' ? "Disable" : "Enable"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
        data: {'status': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Account ${newStatus == 'disabled' ? 'disabled' : 'enabled'}.")));
        _fetchUsers();
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
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Search by name or ID…",
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon:
                      const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: _kSAAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['all', 'student', 'admin']
                    .map((f) {
                  final sel = _roleFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _roleFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? _kSAAccent
                              : _kSAAccent
                                  .withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? _kSAAccent
                                : _kSAAccent
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : _kSAAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kSAAccent)))
        else
          Expanded(
            child: RefreshIndicator(
              color: _kSAAccent,
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (_, i) =>
                    _buildUserTile(_filtered[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserTile(models.Document doc) {
    final d = doc.data;
    final name = d['name'] as String? ?? '—';
    final username = d['username'] as String? ?? '—';
    final role = d['role'] as String? ?? 'student';
    final status = d['status'] as String? ?? 'active';
    final isDisabled = status == 'disabled';

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'admin':
      case 'dean':
        roleColor = const Color(0xFF7A6A8A);
        roleLabel = role == 'dean' ? 'Dean' : 'Admin';
        break;
      case 'officeAdmin':
        roleColor = const Color(0xFF8A6A6A);
        roleLabel = 'Office';
        break;
      case 'eventAdmin':
        roleColor = const Color(0xFF3D6B8A);
        roleLabel = 'Events';
        break;
      case 'hrAdmin':
        roleColor = const Color(0xFF8A7A2A);
        roleLabel = 'HR';
        break;
      case 'securityAdmin':
        roleColor = _kSAAccent;
        roleLabel = 'Security';
        break;
      default:
        roleColor = AppTheme.kGreen;
        roleLabel = 'Student';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.grey.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDisabled
              ? Colors.grey.shade200
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            profilePictureId: d['profilePictureId'] as String?,
            fallbackName: name,
            radius: 20,
            backgroundColor:
                roleColor.withValues(alpha: 0.1),
            foregroundColor: roleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDisabled
                              ? Colors.grey
                              : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: roleColor),
                      ),
                    ),
                  ],
                ),
                Text(username,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleStatus(doc),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDisabled
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                isDisabled ? "Enable" : "Disable",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDisabled
                      ? Colors.green.shade600
                      : Colors.red.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
