import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, Center;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'services/admin_presence_service.dart';
import 'services/export_service.dart';
import 'components/user_avatar.dart';
import 'components/admin_presence_card.dart';
import 'office_admin_student_attendance_page.dart';
import 'main.dart';

const _kOAAccent = Color(0xFF8A6A6A);
final _kDb = AppwriteService.databaseId;
final _kProfileBucket = AppwriteService.profileBucketId;
const _kFaceBase = AppwriteService.mlBackendBase;

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

class OfficeAdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;
  final String adminDepartment;

  const OfficeAdminHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
    required this.adminDepartment,
  });

  @override
  State<OfficeAdminHomePage> createState() => _OfficeAdminHomePageState();
}

class _OfficeAdminHomePageState extends State<OfficeAdminHomePage> {
  int _selectedTab = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _OverviewTab(
          adminId: widget.adminId,
          adminName: widget.adminName,
          department: widget.adminDepartment),
      _AdminsTab(adminId: widget.adminId, adminName: widget.adminName),
      _StudentsTab(department: widget.adminDepartment),
      _ReportsTab(department: widget.adminDepartment),
      _BiometricsTab(department: widget.adminDepartment, adminId: widget.adminId),
      _VerificationTab(),
      _AuditTrailTab(adminId: widget.adminId),
    ];
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header bar ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kOAAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kOAAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      "OFFICE ADMIN",
                      style: TextStyle(
                          color: _kOAAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.adminName,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 20),
                    tooltip: "Logout",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // ── Tab content ──────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _kOAAccent,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle:
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Overview"),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: "Admins"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: "Students"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart),
              label: "Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint),
              activeIcon: Icon(Icons.fingerprint),
              label: "Biometrics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.verified_outlined),
              activeIcon: Icon(Icons.verified),
              label: "Verify"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: "Audit"),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final String adminId;
  final String adminName;
  final String department;
  const _OverviewTab(
      {required this.adminId,
      required this.adminName,
      required this.department});
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  int _totalStudents = 0;
  int _enrolledBio = 0;
  int _todayEntries = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final queries = <String>[
        Query.equal('role', 'student'),
        Query.equal('status', 'active'),
        if (widget.department.isNotEmpty)
          Query.equal('department', widget.department),
        Query.limit(5000),
      ];
      final studentsResult = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: queries,
      );
      final students = studentsResult.documents;
      final enrolled =
          students.where((d) {
            final pid = d.data['profilePictureId'] as String?;
            return pid != null && pid.isNotEmpty;
          }).length;

      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();
      final startOfTomorrow =
          DateTime(today.year, today.month, today.day + 1).toIso8601String();
      final logsResult = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: [
          Query.greaterThanEqual('timestamp', startOfDay),
          Query.lessThan('timestamp', startOfTomorrow),
          Query.limit(1),
        ],
      );

      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          _enrolledBio = enrolled;
          _todayEntries = logsResult.total;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kOAAccent))
          : RefreshIndicator(
              color: _kOAAccent,
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTheme.sheetHandle,
                    AdminPresenceCard(
                      adminId: widget.adminId,
                      adminName: widget.adminName,
                      role: 'officeAdmin',
                      level: 0,
                      department: widget.department,
                      accent: _kOAAccent,
                      onSignedOut: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text("Overview",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Text(widget.department.isNotEmpty
                        ? widget.department
                        : "All Departments",
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            Icons.people_alt_outlined,
                            "$_totalStudents",
                            "Active Students",
                            const Color(0xFF4E7A8A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _statCard(
                            Icons.fingerprint,
                            "$_enrolledBio",
                            "Enrolled Biometrics",
                            _kOAAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            Icons.check_circle_outline,
                            "$_todayEntries",
                            "Today's Entries",
                            const Color(0xFF6A8A73),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _statCard(
                            Icons.person_off_outlined,
                            "${_totalStudents - _enrolledBio}",
                            "Needs Enrollment",
                            Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text("Quick Tips",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    _tipTile(Icons.people_outline, "Students",
                        "View per-student attendance history."),
                    _tipTile(Icons.insert_chart_outlined, "Reports",
                        "Export attendance data as CSV or Excel."),
                    _tipTile(Icons.fingerprint, "Biometrics",
                        "View, update, or delete student face data."),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _tipTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kOAAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kOAAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Students
// ─────────────────────────────────────────────────────────────────────────────

class _StudentsTab extends StatefulWidget {
  final String department;
  const _StudentsTab({required this.department});
  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  List<models.Document> _students = [];
  bool _loading = true;
  String _search = '';

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [
          Query.equal('role', 'student'),
          Query.equal('status', 'active'),
          if (widget.department.isNotEmpty)
            Query.equal('department', widget.department),
          Query.limit(25),
        ],
      );
      if (mounted) {
        setState(() {
          _students = result.documents;
          _hasMore = result.documents.length == 25;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _students.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final lastId = _students.last.$id;
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [
          Query.equal('role', 'student'),
          Query.equal('status', 'active'),
          if (widget.department.isNotEmpty)
            Query.equal('department', widget.department),
          Query.limit(25),
          Query.cursorAfter(lastId),
        ],
      );
      if (mounted) {
        setState(() {
          _students.addAll(result.documents);
          _hasMore = result.documents.length == 25;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<models.Document> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((d) {
      final name = (d.data['name'] ?? '').toString().toLowerCase();
      final id = (d.data['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sheetHandle,
                Text("Students",
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search by name or ID...",
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.black38, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: _kOAAccent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kOAAccent))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _kOAAccent,
                        onRefresh: _fetchStudents,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: _filtered.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator(color: _kOAAccent)),
                              );
                            }
                            return _buildStudentCard(_filtered[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(models.Document doc) {
    final data = doc.data;
    final name = data['name'] as String? ?? 'Unknown';
    final id = data['username'] as String? ?? '';
    final dept = data['department'] as String? ?? '';
    final picId = data['profilePictureId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            UserAvatar(
              profilePictureId: picId,
              fallbackName: name,
              radius: 24,
              backgroundColor: _kOAAccent.withValues(alpha: 0.1),
              foregroundColor: _kOAAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                  Text("ID: $id",
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  if (dept.isNotEmpty)
                    Text(dept,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OfficeAdminStudentAttendancePage(
                    studentId: id,
                    studentName: name,
                    profilePictureId: picId,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOAAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.history_outlined, size: 14),
              label: const Text("History"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("No students found",
              style: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.black45)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Reports
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  final String department;
  const _ReportsTab({required this.department});
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  List<models.Document> _classes = [];
  models.Document? _selectedClass;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loadingClasses = true;
  bool _exporting = false;
  String? _lastSavedPath;

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
        queries: [Query.limit(500)],
      );
      if (mounted) {
        setState(() {
          _classes = result.documents;
          _loadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
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
            colorScheme:
                const ColorScheme.light(primary: _kOAAccent)),
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

  // Fetch attendance logs and student names for the report
  Future<List<List<String>>> _buildReportData() async {
    if (_selectedClass == null || _startDate == null || _endDate == null) {
      return [];
    }
    final classId = _selectedClass!.$id;
    final start =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
            .toIso8601String();
    final end =
        DateTime(_endDate!.year, _endDate!.month, _endDate!.day + 1)
            .toIso8601String();

    final logsResult = await AppwriteService.databases.listDocuments(
      databaseId: _kDb,
      collectionId: 'attendance_logs',
      queries: [
        Query.equal('classId', classId),
        Query.greaterThanEqual('timestamp', start),
        Query.lessThan('timestamp', end),
        Query.orderAsc('timestamp'),
        Query.limit(5000),
      ],
    );

    final logs = logsResult.documents;
    if (logs.isEmpty) return [];

    // Batch-fetch student names
    final userIds =
        logs.map((d) => d.data['userId'] as String? ?? '').toSet().toList();
    final nameMap = <String, String>{};
    for (int i = 0; i < userIds.length; i += 100) {
      final chunk = userIds.skip(i).take(100).toList();
      try {
        final usersResult = await AppwriteService.databases.listDocuments(
          databaseId: _kDb,
          collectionId: 'users',
          queries: [Query.equal('username', chunk), Query.limit(100)],
        );
        for (final u in usersResult.documents) {
          final uid = u.data['username'] as String? ?? '';
          final name = u.data['name'] as String? ?? uid;
          if (uid.isNotEmpty) nameMap[uid] = name;
        }
      } catch (_) {}
    }

    final rows = <List<String>>[];
    final fmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm:ss');
    for (final log in logs) {
      final d = log.data;
      final userId = d['userId'] as String? ?? '';
      DateTime? ts;
      try {
        ts = DateTime.parse(d['timestamp'] as String);
      } catch (_) {}
      rows.add([
        nameMap[userId] ?? userId,
        userId,
        d['className'] as String? ?? '',
        ts != null ? fmt.format(ts) : '',
        ts != null ? timeFmt.format(ts) : '',
        d['adminVerifiedStatus'] as String? ?? 'Pending',
        d['entryStatus'] as String? ?? '',
        (d['isWithinGeofence'] as bool? ?? false) ? 'Yes' : 'No',
      ]);
    }
    return rows;
  }

  Future<void> _export(String format) async {
    if (_selectedClass == null) {
      _snack("Please select a class first.");
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack("Please select a date range.");
      return;
    }
    setState(() => _exporting = true);
    try {
      const columns = [
        'Student Name',
        'Student ID',
        'Class',
        'Date',
        'Time',
        'Status',
        'Entry Type',
        'In Geofence',
      ];
      final rows = await _buildReportData();
      if (rows.isEmpty) {
        _snack("No attendance records found for the selected filters.");
        setState(() => _exporting = false);
        return;
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      String? savedPath;

      if (format == 'csv') {
        const conv = ListToCsvConverter();
        final csv = conv.convert([columns, ...rows]);
        savedPath = await ExportService.saveText(
          content: csv,
          fileName: 'attendance_$ts.csv',
        );
      } else if (format == 'excel') {
        final excel = Excel.createExcel();
        final sheet = excel['Attendance'];
        // Header row with bold style
        final headerStyle = CellStyle(bold: true);
        for (int c = 0; c < columns.length; c++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
          cell.value = TextCellValue(columns[c]);
          cell.cellStyle = headerStyle;
        }
        // Data rows
        for (int r = 0; r < rows.length; r++) {
          for (int c = 0; c < rows[r].length; c++) {
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: c, rowIndex: r + 1))
                .value = TextCellValue(rows[r][c]);
          }
        }
        final bytes = excel.save()!;
        savedPath = await ExportService.saveBytes(
          bytes: Uint8List.fromList(bytes),
          fileName: 'attendance_$ts.xlsx',
        );
      } else if (format == 'pdf') {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text("Attendance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[columns, ...rows],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ];
            },
          ),
        );
        savedPath = await ExportService.saveBytes(
          bytes: await pdf.save(),
          fileName: 'attendance_$ts.pdf',
        );
      }

      if (mounted) {
        setState(() {
          _lastSavedPath = savedPath;
          _exporting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _snack("Export failed: $e");
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _showAbsentees() async {
    if (_selectedClass == null) {
      _snack("Please select a class first.");
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack("Please select a date range.");
      return;
    }
    
    final classId = _selectedClass!.$id;
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day).toIso8601String();
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day + 1).toIso8601String();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kOAAccent)),
    );

    try {
      final logsResult = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: [
          Query.equal('classId', classId),
          Query.greaterThanEqual('timestamp', start),
          Query.lessThan('timestamp', end),
          Query.limit(5000),
        ],
      );

      final presentIds = logsResult.documents.map((d) => d.data['userId'] as String? ?? '').toSet();
      final allStudentIds = List<String>.from(_selectedClass!.data['studentIds'] ?? []);
      final absentees = allStudentIds.where((id) => !presentIds.contains(id)).toList();

      if (mounted) Navigator.pop(context); // close loader

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Absentees (${absentees.length})", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: absentees.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.orange),
                  title: Text(absentees[i], style: GoogleFonts.poppins()),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: _kOAAccent)))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        _snack("Failed to fetch absentees: $e");
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.sheetHandle,
            Text("Reports",
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text("Generate attendance reports for any class.",
                style: TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 24),

            // Class selector
            Text("Class",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            _loadingClasses
                ? const LinearProgressIndicator(color: _kOAAccent)
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<models.Document?>(
                        value: _selectedClass,
                        hint: Text("Select a class",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500)),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text("— Select class —",
                                  style: TextStyle(fontSize: 14))),
                          ..._classes.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c.data['className'] as String? ??
                                      c.$id,
                                  style:
                                      const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedClass = v),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // Date range selector
            Text("Date Range",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _startDate != null
                      ? _kOAAccent.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _startDate != null
                        ? _kOAAccent.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_outlined,
                        size: 20,
                        color: _startDate != null
                            ? _kOAAccent
                            : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startDate != null
                            ? "${DateFormat('dd MMM yyyy').format(_startDate!)}  –  ${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : '...'}"
                            : "Tap to select date range",
                        style: TextStyle(
                          fontSize: 14,
                          color: _startDate != null
                              ? _kOAAccent
                              : Colors.grey,
                          fontWeight: _startDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
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
                            size: 16, color: _kOAAccent),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Export buttons
            if (_exporting)
              const Center(
                  child: CircularProgressIndicator(color: _kOAAccent))
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _export('csv'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217346),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 20),
                  label: Text("Export as CSV",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _export('excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6EBC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.file_present_outlined, size: 20),
                  label: Text("Export as Excel",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _export('pdf'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: Text("Export as PDF",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAbsentees,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                icon: const Icon(Icons.person_off_outlined, size: 20),
                label: Text("View Absentees",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            // Saved file path
            if (_lastSavedPath != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("File saved successfully",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.green.shade700)),
                          const SizedBox(height: 2),
                          Text(
                            _lastSavedPath!,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _lastSavedPath!));
                        _snack("Path copied to clipboard.");
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      color: Colors.green.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Biometrics
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricsTab extends StatefulWidget {
  final String department;
  final String adminId;
  const _BiometricsTab({required this.department, required this.adminId});
  @override
  State<_BiometricsTab> createState() => _BiometricsTabState();
}

class _BiometricsTabState extends State<_BiometricsTab> {
  List<models.Document> _students = [];
  bool _loading = true;
  String _search = '';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [
          Query.equal('role', 'student'),
          Query.equal('status', 'active'),
          if (widget.department.isNotEmpty)
            Query.equal('department', widget.department),
          Query.limit(5000),
        ],
      );
      if (mounted) {
        setState(() {
          _students = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<models.Document> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((d) {
      final name = (d.data['name'] ?? '').toString().toLowerCase();
      final id = (d.data['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── View biometric photo ─────────────────────────────────────────────────
  Future<void> _viewBiometric(models.Document doc) async {
    final fileId = doc.data['profilePictureId'] as String?;
    if (fileId == null || fileId.isEmpty) {
      _snack("No biometric enrolled for this student.");
      return;
    }
    Uint8List? bytes;
    try {
      bytes = await AppwriteService.storage.getFileView(
        bucketId: _kProfileBucket,
        fileId: fileId,
      );
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bytes != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.memory(bytes,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover),
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.broken_image_outlined,
                    size: 80, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                doc.data['name'] as String? ?? 'Student',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Update biometric photo ───────────────────────────────────────────────
  Future<void> _updateBiometric(models.Document doc) async {
    final username = doc.data['username'] as String? ?? '';
    if (username.isEmpty) return;

    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: _kOAAccent),
            SizedBox(width: 20),
            Text("Updating biometric..."),
          ],
        ),
      ),
    );

    try {
      // 1. Register face on backend — abort if it doesn't actually succeed,
      // so we never claim "updated" while the face model is stale.
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_kFaceBase/register-face'));
      req.fields['username'] = username;
      req.files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: 'photo.jpg'));
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        if (mounted) {
          Navigator.of(context).pop();
          _snack("Face registration failed (status ${streamed.statusCode}): $body");
        }
        return;
      }

      // 2. Delete old file from storage
      final oldFileId = doc.data['profilePictureId'] as String?;
      if (oldFileId != null && oldFileId.isNotEmpty) {
        try {
          await AppwriteService.storage.deleteFile(
              bucketId: _kProfileBucket, fileId: oldFileId);
        } catch (_) {}
      }

      // 3. Upload new file
      final newFile = await AppwriteService.storage.createFile(
        bucketId: _kProfileBucket,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
            bytes: bytes, filename: 'bio_${username}_update.jpg'),
      );

      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
        data: {'profilePictureId': newFile.$id},
      );

      try {
        await AppwriteService.databases.createDocument(
          databaseId: _kDb,
          collectionId: 'office_admin_audit_log',
          documentId: ID.unique(),
          data: {
            'adminId': widget.adminId,
            'action': oldFileId != null && oldFileId.isNotEmpty ? 'update' : 'enroll',
            'studentUsername': username,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        _snack("Biometric updated successfully.");
        _fetchStudents();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _snack("Update failed: $e");
      }
    }
  }

  // ── Delete biometric ─────────────────────────────────────────────────────
  Future<void> _deleteBiometric(models.Document doc) async {
    final username = doc.data['username'] as String? ?? '';
    final name = doc.data['name'] as String? ?? username;
    final fileId = doc.data['profilePictureId'] as String?;
    if (fileId == null || fileId.isEmpty) {
      _snack("No biometric enrolled.");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Biometric"),
        content: Text(
            "Remove biometric data for $name? They will need to re-enroll."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600),
              child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      // Delete from storage
      await AppwriteService.storage.deleteFile(
          bucketId: _kProfileBucket, fileId: fileId);
    } catch (_) {}

    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
        data: {'profilePictureId': null},
      );

      try {
        await AppwriteService.databases.createDocument(
          databaseId: _kDb,
          collectionId: 'office_admin_audit_log',
          documentId: ID.unique(),
          data: {
            'adminId': widget.adminId,
            'action': 'delete',
            'studentUsername': username,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {}
      _snack("Biometric deleted.");
      _fetchStudents();
    } catch (e) {
      _snack("Failed to update record: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final enrolledCount =
        filtered.where((d) {
          final pid = d.data['profilePictureId'] as String?;
          return pid != null && pid.isNotEmpty;
        }).length;

    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sheetHandle,
                Row(
                  children: [
                    Expanded(
                      child: Text("Biometrics",
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kOAAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("$enrolledCount enrolled",
                          style: const TextStyle(
                              color: _kOAAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search students...",
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.black38, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: _kOAAccent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kOAAccent))
                : filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _kOAAccent,
                        onRefresh: _fetchStudents,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildBioCard(filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(models.Document doc) {
    final data = doc.data;
    final name = data['name'] as String? ?? 'Unknown';
    final id = data['username'] as String? ?? '';
    final picId = data['profilePictureId'] as String?;
    final isEnrolled = picId != null && picId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  profilePictureId: picId,
                  fallbackName: name,
                  radius: 24,
                  backgroundColor: _kOAAccent.withValues(alpha: 0.1),
                  foregroundColor: _kOAAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                          overflow: TextOverflow.ellipsis),
                      Text("ID: $id",
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isEnrolled
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isEnrolled
                            ? Colors.green.shade200
                            : Colors.orange.shade200),
                  ),
                  child: Text(
                    isEnrolled ? "Enrolled" : "Not Enrolled",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEnrolled
                            ? Colors.green.shade700
                            : Colors.orange.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isEnrolled)
                  Expanded(
                    child: _actionBtn(
                      Icons.visibility_outlined,
                      "View",
                      Colors.grey.shade700,
                      Colors.grey.shade100,
                      () => _viewBiometric(doc),
                    ),
                  ),
                if (isEnrolled) const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    isEnrolled
                        ? Icons.refresh_rounded
                        : Icons.add_a_photo_outlined,
                    isEnrolled ? "Update" : "Enroll",
                    const Color(0xFF4E7A8A),
                    const Color(0xFF4E7A8A).withValues(alpha: 0.08),
                    () => _updateBiometric(doc),
                  ),
                ),
                if (isEnrolled) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionBtn(
                      Icons.delete_outline_rounded,
                      "Delete",
                      Colors.red.shade600,
                      Colors.red.shade50,
                      () => _deleteBiometric(doc),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color fg, Color bg,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fingerprint, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("No students found",
              style: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.black45)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Verification (Attendance Approval)
// ─────────────────────────────────────────────────────────────────────────────

class _VerificationTab extends StatefulWidget {
  @override
  State<_VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<_VerificationTab> {
  List<models.Document> _pendingLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: [
          Query.equal('adminVerifiedStatus', 'Pending'),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );
      if (mounted) setState(() { _pendingLogs = res.documents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        documentId: docId,
        data: {'adminVerifiedStatus': status},
      );
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sheetHandle,
                Text("Verify Attendance", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator(color: _kOAAccent))
              : _pendingLogs.isEmpty ? const Center(child: Text("No pending logs."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _pendingLogs.length,
                  itemBuilder: (ctx, i) {
                    final d = _pendingLogs[i].data;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text("${d['className']} - ${d['userId']}"),
                        subtitle: Text(d['timestamp'].toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(_pendingLogs[i].$id, 'Verified')),
                            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(_pendingLogs[i].$id, 'Rejected')),
                          ],
                        ),
                      ),
                    );
                  }
                )
          )
        ]
      )
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 5 — Audit Trail
// ─────────────────────────────────────────────────────────────────────────────

class _AuditTrailTab extends StatefulWidget {
  final String adminId;
  const _AuditTrailTab({required this.adminId});
  @override
  State<_AuditTrailTab> createState() => _AuditTrailTabState();
}

class _AuditTrailTabState extends State<_AuditTrailTab> {
  List<models.Document> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'office_admin_audit_log',
        queries: [
          Query.equal('adminId', widget.adminId),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );
      if (mounted) setState(() { _logs = res.documents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sheetHandle,
                Text("Audit Trail", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator(color: _kOAAccent))
              : _logs.isEmpty ? const Center(child: Text("No audit logs found."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final d = _logs[i].data;
                    return Card(
                      child: ListTile(
                        title: Text("${d['action'].toString().toUpperCase()} - ${d['studentUsername']}"),
                        subtitle: Text(d['timestamp'].toString()),
                      ),
                    );
                  }
                )
          )
        ]
      )
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab — Admins (create L1/L2/L3, assign parent, set boundary, export activity)
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kDepartments = [
  "School of Computing (SoC)",
  "School of Electrical & Electronics Engineering (SEEE)",
  "School of Mechanical Engineering (SoME)",
  "School of Civil Engineering (SoCE)",
  "School of Chemical & Biotechnology (SCBT)",
  "School of Law",
  "School of Management (SoM)",
  "School of Arts, Sciences, Humanities & Education (SASHE)",
];

String _roleLevelLabel(String? role, dynamic level) {
  if (role == 'admin') {
    switch (level) {
      case 1:
        return 'Institution Admin';
      case 2:
        return 'Head of Department';
      case 3:
        return 'Team Leader';
      default:
        return 'Admin';
    }
  }
  switch (role) {
    case 'officeAdmin':
      return 'Office Admin';
    case 'eventAdmin':
      return 'Event Admin';
    case 'hrAdmin':
      return 'HR Admin';
    case 'securityAdmin':
      return 'Security Admin';
    default:
      return role ?? 'Admin';
  }
}

class _AdminsTab extends StatefulWidget {
  final String adminId;
  final String adminName;
  const _AdminsTab({required this.adminId, required this.adminName});
  @override
  State<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<_AdminsTab> {
  List<models.Document> _admins = [];
  bool _loading = true;

  List<models.Document> get _l1s =>
      _admins.where((d) => d.data['level'] == 1 && d.data['status'] != 'disabled').toList();
  List<models.Document> get _l2s =>
      _admins.where((d) => d.data['level'] == 2 && d.data['status'] != 'disabled').toList();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [
          Query.equal('role', 'admin'),
          Query.limit(500),
        ],
      );
      if (mounted) {
        setState(() {
          _admins = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Create L1/L2/L3 with parent assignment ─────────────────────────────
  void _showCreateSheet() {
    const roleLabels = ['Institution Admin', 'Head of Department', 'Team Leader'];
    const roleShort = ['Institution', 'Dept. Head', 'Team Leader'];
    const levels = [1, 2, 3];
    const roleIcons = [
      Icons.account_balance_outlined,
      Icons.domain_outlined,
      Icons.class_outlined,
    ];

    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedDept = _kDepartments.first;
    int selectedIdx = 0;
    models.Document? selectedParent;
    Map<String, dynamic>? selectedBoundary;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final level = levels[selectedIdx];
          final parents = level == 2
              ? _l1s
              : level == 3
                  ? _l2s
                  : <models.Document>[];
          final needsParent = level == 2 || level == 3;
          // Reset parent selection when it no longer belongs to the list.
          if (selectedParent != null && !parents.any((p) => p.$id == selectedParent!.$id)) {
            selectedParent = null;
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: AppTheme.sheetHandle),
                  Text("Onboard Admin",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Create a hierarchy admin and assign who they report to.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 18),

                  // Role selector
                  Row(
                    children: List.generate(3, (i) {
                      final selected = selectedIdx == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? _kOAAccent : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: selected
                                      ? _kOAAccent
                                      : Colors.grey.shade200,
                                  width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Icon(roleIcons[i],
                                    size: 20,
                                    color:
                                        selected ? Colors.white : _kOAAccent),
                                const SizedBox(height: 5),
                                Text(roleShort[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: selected
                                            ? Colors.white
                                            : _kOAAccent)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Admin Username (ID)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: 'Initial Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedDept,
                    decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: _kDepartments
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child:
                                Text(d, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedDept = v!),
                  ),

                  // Parent picker
                  if (needsParent) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<models.Document>(
                      isExpanded: true,
                      value: selectedParent,
                      decoration: InputDecoration(
                          labelText: level == 2
                              ? 'Reports to (Institution Admin)'
                              : 'Reports to (Head of Department)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      items: parents
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  "${p.data['name'] ?? p.data['username']} · ${p.data['department'] ?? ''}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedParent = v),
                    ),
                    if (parents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          level == 2
                              ? 'No Institution Admins exist yet. Create one first.'
                              : 'No Heads of Department exist yet. Create one first.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Institution Admins report to the Dean.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ),

                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked =
                          await _openBoundaryPicker(selectedBoundary);
                      if (picked != null) {
                        setSheetState(() => selectedBoundary = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: selectedBoundary != null
                                  ? _kOAAccent.withValues(alpha: 0.5)
                                  : Colors.red.shade300),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.my_location,
                              size: 18,
                              color: selectedBoundary != null
                                  ? _kOAAccent
                                  : Colors.red.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedBoundary != null
                                  ? "Location set · ${(selectedBoundary!['radiusMeters'] as num).toStringAsFixed(0)} m radius"
                                  : "Set this admin's presence location (required)",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: selectedBoundary != null
                                      ? _kOAAccent
                                      : Colors.red.shade400,
                                  fontWeight: selectedBoundary != null
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (usernameCtrl.text.trim().isEmpty ||
                                  passCtrl.text.trim().isEmpty) {
                                _snack('Username and password are required.');
                                return;
                              }
                              if (needsParent && selectedParent == null) {
                                _snack('Please choose who this admin reports to.');
                                return;
                              }
                              if (selectedBoundary == null) {
                                _snack(
                                    "Please set this admin's presence location before creating their ID.");
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                final exists = await AppwriteService.databases
                                    .listDocuments(
                                  databaseId: _kDb,
                                  collectionId: 'users',
                                  queries: [
                                    Query.equal(
                                        'username', usernameCtrl.text.trim()),
                                  ],
                                );
                                if (exists.documents.isNotEmpty) {
                                  setSheetState(() => saving = false);
                                  _snack('Username already exists.');
                                  return;
                                }

                                final docData = <String, dynamic>{
                                  'username': usernameCtrl.text.trim(),
                                  'name': nameCtrl.text.trim().isNotEmpty
                                      ? nameCtrl.text.trim()
                                      : usernameCtrl.text.trim(),
                                  'password': AppwriteService.hashPassword(
                                      passCtrl.text.trim()),
                                  'role': 'admin',
                                  'level': level,
                                  'department': selectedDept,
                                  'status': 'active',
                                  'managedClasses': <String>[],
                                  'createdAt': DateTime.now().toIso8601String(),
                                };
                                if (needsParent && selectedParent != null) {
                                  docData['parentAdminId'] =
                                      selectedParent!.data['username'];
                                  docData['parentAdminName'] =
                                      selectedParent!.data['name'] ??
                                          selectedParent!.data['username'];
                                }
                                docData['presenceBoundary'] =
                                    jsonEncode(selectedBoundary);

                                await AppwriteService.databases.createDocument(
                                  databaseId: _kDb,
                                  collectionId: 'users',
                                  documentId: ID.unique(),
                                  data: docData,
                                );

                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _fetch();
                                _snack('${roleLabels[selectedIdx]} onboarded.');
                              } catch (e) {
                                setSheetState(() => saving = false);
                                _snack('Error: $e');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kOAAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text("Create ${roleShort[selectedIdx]}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reassign an existing admin's parent ────────────────────────────────
  Future<void> _editParent(models.Document doc) async {
    final level = doc.data['level'];
    if (level == 1) {
      _snack('Institution Admins report to the Dean — no parent to set.');
      return;
    }
    final parents = level == 2 ? _l1s : _l2s;
    if (parents.isEmpty) {
      _snack(level == 2
          ? 'No Institution Admins to assign.'
          : 'No Heads of Department to assign.');
      return;
    }
    final currentParentId = doc.data['parentAdminId'] as String?;
    models.Document? chosen = parents.firstWhere(
      (p) => p.data['username'] == currentParentId,
      orElse: () => parents.first,
    );

    final result = await showDialog<models.Document>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(level == 2 ? 'Assign Institution Admin' : 'Assign Head of Department'),
        content: StatefulBuilder(
          builder: (dctx, setD) => DropdownButtonFormField<models.Document>(
            isExpanded: true,
            value: chosen,
            items: parents
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        "${p.data['name'] ?? p.data['username']} · ${p.data['department'] ?? ''}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setD(() => chosen = v),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kOAAccent),
            onPressed: () => Navigator.pop(dctx, chosen),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'users',
        documentId: doc.$id,
        data: {
          'parentAdminId': result.data['username'],
          'parentAdminName': result.data['name'] ?? result.data['username'],
        },
      );
      _fetch();
      _snack('Reporting line updated.');
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _openBoundaryPicker(
      Map<String, dynamic>? existing) async {
    LatLng pos;
    if (existing != null) {
      pos = LatLng((existing['lat'] as num).toDouble(),
          (existing['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    double radius =
        existing != null ? (existing['radiusMeters'] as num).toDouble() : 100.0;
    LatLng current = pos;
    final mapController = MapController();
    if (!mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: _kOAAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text("Set Presence Boundary",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (_, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) => setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: _kOAAccent.withValues(alpha: 0.18),
                              borderColor: _kOAAccent,
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.radio_button_checked,
                                    size: 13, color: _kOAAccent),
                                const SizedBox(width: 6),
                                Text("Radius: ${radius.toStringAsFixed(0)} m",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor: _kOAAccent,
                                    onChanged: (v) => setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kOAAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx, {
                                    'lat': current.latitude,
                                    'lng': current.longitude,
                                    'radiusMeters': radius,
                                  }),
                                  child: const Text("Confirm Boundary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Export admin activity to Excel ─────────────────────────────────────
  Future<void> _exportActivity() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: const ColorScheme.light(primary: _kOAAccent)),
        child: child!,
      ),
    );
    if (range == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _kOAAccent)),
    );

    try {
      final startKey = AdminPresenceService.dateKey(range.start);
      final endKey = AdminPresenceService.dateKey(range.end);
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: AdminPresenceService.logsCollection,
        queries: [
          Query.greaterThanEqual('date', startKey),
          Query.lessThanEqual('date', endKey),
          Query.orderAsc('date'),
          Query.limit(5000),
        ],
      );

      if (res.documents.isEmpty) {
        if (mounted) Navigator.pop(context);
        _snack('No admin activity found for the selected range.');
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Admin Activity'];
      excel.setDefaultSheet('Admin Activity');
      const headers = [
        'Admin Name',
        'Admin ID',
        'Role / Level',
        'Reports To',
        'Department',
        'Date',
        'Login Time',
        'Presence Time',
        'Sign-out Time',
        'Status',
        'In Geofence',
        'Face Verified',
      ];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      String fmt(String? iso) {
        if (iso == null || iso.isEmpty) return '';
        try {
          return DateFormat('hh:mm a').format(DateTime.parse(iso));
        } catch (_) {
          return '';
        }
      }

      for (final d in res.documents) {
        final m = d.data;
        sheet.appendRow([
          TextCellValue(m['adminName'] as String? ?? ''),
          TextCellValue(m['adminId'] as String? ?? ''),
          TextCellValue(_roleLevelLabel(m['role'] as String?, m['level'])),
          TextCellValue(m['parentAdminId'] as String? ?? ''),
          TextCellValue(m['department'] as String? ?? ''),
          TextCellValue(m['date'] as String? ?? ''),
          TextCellValue(fmt(m['loginTime'] as String?)),
          TextCellValue(fmt(m['presenceTime'] as String?)),
          TextCellValue(fmt(m['signOutTime'] as String?)),
          TextCellValue((m['status'] as String?)?.isNotEmpty == true
              ? m['status'] as String
              : 'Not reported'),
          TextCellValue((m['isWithinGeofence'] as bool? ?? false) ? 'Yes' : 'No'),
          TextCellValue((m['faceVerified'] as bool? ?? false) ? 'Yes' : 'No'),
        ]);
      }
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');

      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final savedPath = await ExportService.saveBytes(
        bytes: Uint8List.fromList(bytes),
        fileName: 'admin_activity_$ts.xlsx',
      );

      if (mounted) Navigator.pop(context);
      _snack(savedPath != null
          ? 'Saved: admin_activity_$ts.xlsx'
          : 'Export cancelled.');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _snack('Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kOAAccent,
        foregroundColor: Colors.white,
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Onboard Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
      width: double.infinity,
      decoration: AppTheme.bottomSheet,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sheetHandle,
                Row(
                  children: [
                    Expanded(
                      child: Text("Admin Management",
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                    IconButton(
                      onPressed: _exportActivity,
                      tooltip: 'Export admin activity',
                      icon: const Icon(Icons.download_rounded, color: _kOAAccent),
                    ),
                  ],
                ),
                Text(
                  'Each admin has their own presence location — set via ⋮ on their card, or when onboarding a new one.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kOAAccent))
                : _admins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text("No hierarchy admins yet",
                                style: GoogleFonts.poppins(
                                    fontSize: 15, color: Colors.black45)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _kOAAccent,
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                          itemCount: _admins.length,
                          itemBuilder: (ctx, i) => _adminCard(_admins[i]),
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _adminCard(models.Document doc) {
    final data = doc.data;
    final name = data['name'] as String? ?? data['username'] as String? ?? '';
    final level = data['level'];
    final parent = data['parentAdminName'] as String? ?? data['parentAdminId'] as String?;
    final isDisabled = data['status'] == 'disabled';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _kOAAccent.withValues(alpha: 0.12),
              child: Text('L${level ?? '?'}',
                  style: const TextStyle(
                      color: _kOAAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                  Text(_roleLevelLabel(data['role'] as String?, level),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  Text(
                    level == 1
                        ? 'Reports to: Dean'
                        : (parent != null && parent.isNotEmpty
                            ? 'Reports to: $parent'
                            : 'Reports to: — (unassigned)'),
                    style: TextStyle(
                        fontSize: 11,
                        color: (level != 1 && (parent == null || parent.isEmpty))
                            ? Colors.orange.shade700
                            : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (isDisabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Disabled',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                switch (v) {
                  case 'location':
                    _setAdminLocation(doc);
                    break;
                  case 'parent':
                    _editParent(doc);
                    break;
                  case 'status':
                    _toggleStatus(doc);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'location',
                  child: Row(children: [
                    Icon(Icons.my_location, size: 18, color: _kOAAccent),
                    SizedBox(width: 10),
                    Text('Set location'),
                  ]),
                ),
                if (level != 1)
                  const PopupMenuItem(
                    value: 'parent',
                    child: Row(children: [
                      Icon(Icons.account_tree_outlined,
                          size: 18, color: _kOAAccent),
                      SizedBox(width: 10),
                      Text('Edit reporting line'),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'status',
                  child: Row(children: [
                    Icon(isDisabled ? Icons.check_circle_outline : Icons.block,
                        size: 18,
                        color: isDisabled ? Colors.green : Colors.red),
                    const SizedBox(width: 10),
                    Text(isDisabled ? 'Enable' : 'Disable'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAdminLocation(models.Document doc) async {
    final name = doc.data['name'] as String? ?? doc.data['username'] as String? ?? 'admin';
    Map<String, dynamic>? existing;
    final raw = doc.data['presenceBoundary'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map && d['lat'] != null && d['lng'] != null && d['radiusMeters'] != null) {
          existing = {
            'lat': (d['lat'] as num).toDouble(),
            'lng': (d['lng'] as num).toDouble(),
            'radiusMeters': (d['radiusMeters'] as num).toDouble(),
          };
        }
      } catch (_) {}
    }
    final picked = await _openBoundaryPicker(existing);
    if (picked == null) return;
    try {
      await AdminPresenceService.setAdminBoundary(
        adminDocId: doc.$id,
        lat: picked['lat'],
        lng: picked['lng'],
        radiusMeters: picked['radiusMeters'],
      );
      _fetch();
      _snack("Location set for $name.");
    } catch (e) {
      _snack('Failed to set location: $e');
    }
  }

  Future<void> _toggleStatus(models.Document doc) async {
    final data = doc.data;
    final currentStatus = data['status'] as String? ?? 'active';
    final newStatus = currentStatus == 'disabled' ? 'active' : 'disabled';
    final name = data['name'] as String? ?? 'this admin';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(newStatus == 'disabled' ? "Disable Admin" : "Enable Admin"),
        content: Text(newStatus == 'disabled'
            ? "Disable $name's account? They will not be able to log in."
            : "Re-enable $name's account?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'disabled' ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(newStatus == 'disabled' ? "Disable" : "Enable",
                style: const TextStyle(color: Colors.white)),
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
      _fetch();
      _snack(newStatus == 'disabled' ? 'Admin disabled.' : 'Admin enabled.');
    } catch (e) {
      _snack('Failed: $e');
    }
  }
}
