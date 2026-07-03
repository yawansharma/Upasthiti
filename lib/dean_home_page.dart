import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border, Center;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dean_login.dart';
import 'admin_home_page.dart';
import 'admin_hierarchy_views.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'services/admin_hierarchy_service.dart';
import 'services/leave_service.dart';
import 'distribution/dean_distribution_tab.dart';
import 'components/user_avatar.dart';

// ---------------------------------------------------------------------------
// THEME CONSTANTS FOR DEAN
// ---------------------------------------------------------------------------
const Color kDeanDark = Color(0xFF10121C);
const Color kDeanPanel = Color(0xFF1A1C29);
const Color kDeanGold = Color(0xFFD4AF37);
const Color kDeanBg = Color(0xFFF8F9FB);

class DeanHomePage extends StatefulWidget {
  const DeanHomePage({super.key});

  @override
  State<DeanHomePage> createState() => _DeanHomePageState();
}

class _DeanHomePageState extends State<DeanHomePage> {
  int _currentIndex = 0;
  int _prevIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeanDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tabTitle(),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: kDeanGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: kDeanGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                "EXECUTIVE CONTROL",
                style: GoogleFonts.poppins(
                    color: kDeanGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                decoration: const BoxDecoration(
                  color: kDeanBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(35)),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final isNewTab =
                                child.key == ValueKey(_currentIndex);
                            final isMovingRight =
                                _currentIndex > _prevIndex;
                            final beginOffset = isNewTab
                                ? Offset(isMovingRight ? 1.0 : -1.0, 0.0)
                                : Offset(
                                    isMovingRight ? -1.0 : 1.0, 0.0);
                            return SlideTransition(
                              position: Tween<Offset>(
                                      begin: beginOffset,
                                      end: Offset.zero)
                                  .animate(animation),
                              child: child,
                            );
                          },
                          child: _buildCurrentTab(),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -5))
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _navItem(0, Icons.people_alt, "Personnel"),
                              _navItem(1, Icons.inventory_2_outlined, "Distribution"),
                              _navItem(2, Icons.bar_chart_rounded, "Reports"),
                              _navItem(3, Icons.settings, "More"),
                            ],
                          ),
                        ),
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

  String _tabTitle() {
    switch (_currentIndex) {
      case 0:
        return "Admin Personnel";
      case 1:
        return "Distribution";
      case 2:
        return "Admin Reports";
      case 3:
        return "System Settings";
      default:
        return "Dashboard";
    }
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildPersonnelTab(key: const ValueKey(0));
      case 1:
        return const DeanDistributionTab(key: ValueKey(1));
      case 2:
        return const _DeanReportsTab(key: ValueKey(2));
      case 3:
        return _buildMoreTab(key: const ValueKey(3));
      default:
        return const SizedBox(key: ValueKey(0));
    }
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _prevIndex = _currentIndex;
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kDeanDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? kDeanGold : Colors.grey.shade400,
                size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: kDeanGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelTab({required Key key}) {
    return _AdminListTab(key: key);
  }

  Widget _buildMoreTab({required Key key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: kDeanPanel,
            child: const Icon(Icons.shield, color: kDeanGold, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
            child: Text("Dean / Super Admin",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        Center(
            child: Text("Executive Level",
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13))),
        const SizedBox(height: 32),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.cloud_sync, color: Colors.blue, size: 20),
            ),
            title: const Text("Migrate Legacy Data",
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Link unowned classes to Super Admin",
                style: TextStyle(fontSize: 12)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _runDataMigration(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kDeanGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.event_note_rounded,
                  color: kDeanGold, size: 20),
            ),
            title: const Text("Leave Approvals",
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Institution Admins' leave requests",
                style: TextStyle(fontSize: 12)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _DeanLeaveApprovalsPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.red, size: 20),
            ),
            title: const Text("Logout Securely",
                style: TextStyle(fontWeight: FontWeight.w600)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DeanLoginPage()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _runDataMigration(BuildContext ctx) async {
    final statusNotifier = ValueNotifier("Scanning database...");
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ValueListenableBuilder<String>(
            valueListenable: statusNotifier,
            builder: (_, value, __) => Row(
              children: [
                const CircularProgressIndicator(color: kDeanGold),
                const SizedBox(width: 20),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      int updatedClasses = 0;
      int updatedLogs = 0;

      statusNotifier.value = "Migrating classes...";
      final classDocs = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'classes',
        queries: [Query.limit(5000)],
      );
      for (final doc in classDocs.documents) {
        final data = doc.data;
        if (data['createdBy'] == null ||
            data['createdBy'].toString().isEmpty) {
          await AppwriteService.databases.updateDocument(
            databaseId: '6a2c10dc000d5e50f314',
            collectionId: 'classes',
            documentId: doc.$id,
            data: {'createdBy': 'dean_master', 'adminName': 'Master Dean'},
          );
          updatedClasses++;
        }
      }

      statusNotifier.value = "Migrating attendance logs...";
      final logDocs = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'attendance_logs',
        queries: [Query.limit(5000)],
      );
      for (final doc in logDocs.documents) {
        final data = doc.data;
        if (data['adminId'] == null ||
            data['adminId'].toString().isEmpty) {
          await AppwriteService.databases.updateDocument(
            databaseId: '6a2c10dc000d5e50f314',
            collectionId: 'attendance_logs',
            documentId: doc.$id,
            data: {'adminId': 'dean_master'},
          );
          updatedLogs++;
        }
      }

      statusNotifier.value = "Checking for orphaned class assignments...";
      final orphaned = <Map<String, String>>[];
      for (final doc in classDocs.documents) {
        final assignments = AdminHierarchyService.readAssignments(doc.data);
        final className = doc.data['className'] as String? ?? 'Class';
        for (final entry in [
          (id: assignments.headAdminId, role: 'Head admin'),
          (id: assignments.supervisorId, role: 'Supervisor'),
        ]) {
          final danglingId = entry.id;
          if (danglingId == null || danglingId.isEmpty) continue;
          final user = await AdminHierarchyService.findUserByUsername(
            danglingId,
          );
          if (user == null || user.data['status'] == 'disabled') {
            orphaned.add({
              'className': className,
              'role': entry.role,
              'danglingId': danglingId,
            });
          }
        }
      }

      if (mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
                'Migration Complete: $updatedClasses classes, $updatedLogs logs assigned to Master.')));
      }
      if (orphaned.isNotEmpty && mounted) {
        await showDialog<void>(
          context: ctx,
          builder: (c) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Orphaned Class Assignments Found"),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${orphaned.length} class assignment${orphaned.length == 1 ? '' : 's'} "
                    "point at a disabled or deleted admin. These weren't "
                    "auto-migrated — reassign them via each admin's normal "
                    "assignment flow:",
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: orphaned.length,
                      itemBuilder: (_, i) {
                        final o = orphaned[i];
                        return ListTile(
                          dense: true,
                          title: Text(o['className']!),
                          subtitle: Text(
                              "${o['role']} — dangling id: ${o['danglingId']}"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Migration Error: $e')));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// DEAN LEAVE APPROVALS PAGE
// ---------------------------------------------------------------------------
class _DeanLeaveApprovalsPage extends StatefulWidget {
  const _DeanLeaveApprovalsPage();

  @override
  State<_DeanLeaveApprovalsPage> createState() =>
      _DeanLeaveApprovalsPageState();
}

class _DeanLeaveApprovalsPageState extends State<_DeanLeaveApprovalsPage> {
  List<models.Document> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await LeaveService.getPendingRequests(0, approverId: 'dean');
      if (mounted) {
        setState(() {
          _requests = res;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(String docId, String status) async {
    try {
      await LeaveService.updateStatus(docId, status, 'Dean', actionById: 'dean');
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Request $status")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeanDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Leave Approvals",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kDeanGold))
            : _requests.isEmpty
                ? Center(
                    child: Text("No pending Institution Admin leave requests.",
                        style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final data = _requests[i].data;
                      final start = DateTime.parse(data['startDate']);
                      final end = DateTime.parse(data['endDate']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("From: ${data['userName']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text("Type: ${data['leaveType']}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text(
                                "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}",
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text("Reason: ${data['reason']}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _act(_requests[i].$id, 'denied'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side:
                                            const BorderSide(color: Colors.red),
                                      ),
                                      child: const Text("Deny"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _act(_requests[i].$id, 'approved'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kDeanGold,
                                        foregroundColor: kDeanDark,
                                      ),
                                      child: const Text("Approve"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEAN REPORTS TAB
// ---------------------------------------------------------------------------
class _DeanReportsTab extends StatefulWidget {
  const _DeanReportsTab({super.key});

  @override
  State<_DeanReportsTab> createState() => _DeanReportsTabState();
}

class _DeanReportsTabState extends State<_DeanReportsTab> {
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  // Raw data
  List<models.Document> _admins = [];
  List<models.Document> _classes = [];
  List<models.Document> _logs = [];

  // Aggregated
  late Map<String, int> _classesPerAdmin;    // adminId → class count
  late Map<String, int> _logsPerAdmin;       // adminId → log count
  late Map<String, int> _logsPerClass;       // classId → log count
  late Map<String, int> _adminsPerDept;      // dept → admin count
  late Map<String, int> _classesPerDept;     // dept → class count
  late Map<String, int> _studentsPerDept;    // dept → enrolled student count
  late Map<String, int> _logsPerDept;        // dept → log count

  static const _kDb = '6a2c10dc000d5e50f314';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final adminsRes = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'users',
        queries: [
          Query.equal('role', ['admin', 'officeAdmin', 'eventAdmin', 'hrAdmin', 'securityAdmin']),
          Query.limit(500),
        ],
      );
      final classesRes = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'classes',
        queries: [Query.limit(500)],
      );
      final logsRes = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'attendance_logs',
        queries: [Query.limit(5000)],
      );

      _admins = adminsRes.documents;
      _classes = classesRes.documents;
      _logs = logsRes.documents;
      _aggregate();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _aggregate() {
    _classesPerAdmin = {};
    _logsPerAdmin = {};
    _logsPerClass = {};
    _adminsPerDept = {};
    _classesPerDept = {};
    _studentsPerDept = {};
    _logsPerDept = {};

    // Admin → dept mapping
    final Map<String, String> adminDept = {
      for (final a in _admins)
        (a.data['username'] as String? ?? a.$id): (a.data['department'] as String? ?? 'Unassigned'),
    };

    for (final c in _classes) {
      final adminId = c.data['createdBy'] as String? ?? '';
      final dept = adminDept[adminId] ?? c.data['department'] as String? ?? 'Unassigned';
      final students = (c.data['studentIds'] as List<dynamic>? ?? []).length;

      _classesPerAdmin[adminId] = (_classesPerAdmin[adminId] ?? 0) + 1;
      _classesPerDept[dept] = (_classesPerDept[dept] ?? 0) + 1;
      _studentsPerDept[dept] = (_studentsPerDept[dept] ?? 0) + students;
    }

    for (final l in _logs) {
      final adminId = l.data['adminId'] as String? ?? '';
      final classId = l.data['classId'] as String? ?? '';
      final dept = adminDept[adminId] ?? 'Unassigned';

      _logsPerAdmin[adminId] = (_logsPerAdmin[adminId] ?? 0) + 1;
      _logsPerClass[classId] = (_logsPerClass[classId] ?? 0) + 1;
      _logsPerDept[dept] = (_logsPerDept[dept] ?? 0) + 1;
    }

    for (final a in _admins) {
      final dept = a.data['department'] as String? ?? 'Unassigned';
      _adminsPerDept[dept] = (_adminsPerDept[dept] ?? 0) + 1;
    }
  }

  String _levelLabel(dynamic level) {
    switch (level) {
      case 1: return 'Institution Admin';
      case 2: return 'Head of Department';
      case 3: return 'Team Leader';
      default: return 'Special Role';
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'officeAdmin': return 'Office Admin';
      case 'eventAdmin': return 'Event Admin';
      case 'hrAdmin': return 'HR Admin';
      case 'securityAdmin': return 'Security Admin';
      default: return 'Admin';
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      if (!Platform.isWindows && !(await Permission.storage.request().isGranted)) {
        await Permission.manageExternalStorage.request();
      }

      final excel = Excel.createExcel();

      // ── Sheet 1: Admin Overview ────────────────────────────────────
      final s1 = excel['Admin Overview'];
      excel.setDefaultSheet('Admin Overview');

      final h1 = [
        'Admin Name', 'Admin ID', 'Role / Level', 'Department',
        'Status', 'Last Login', 'Classes Managed', 'Total Attendance Logs',
      ];
      s1.appendRow(h1.map((v) => TextCellValue(v)).toList());

      for (final a in _admins) {
        final d = a.data;
        final id = d['username'] as String? ?? a.$id;
        final role = d['role'] as String?;
        final level = d['level'];
        final roleLabel = (role == 'admin' && level != null)
            ? _levelLabel(level)
            : _roleLabel(role);
        final raw = d['lastLogin'] as String?;
        final lastLogin = raw != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw))
            : 'Never';

        s1.appendRow([
          TextCellValue(d['name'] as String? ?? id),
          TextCellValue(id),
          TextCellValue(roleLabel),
          TextCellValue(d['department'] as String? ?? 'Unassigned'),
          TextCellValue(d['status'] as String? ?? 'active'),
          TextCellValue(lastLogin),
          IntCellValue(_classesPerAdmin[id] ?? 0),
          IntCellValue(_logsPerAdmin[id] ?? 0),
        ]);
      }

      // ── Sheet 2: Department Summary ────────────────────────────────
      final s2 = excel['Department Summary'];
      final h2 = [
        'Department', 'Total Admins', 'Total Classes',
        'Students Enrolled', 'Total Attendance Logs',
      ];
      s2.appendRow(h2.map((v) => TextCellValue(v)).toList());

      final allDepts = {
        ..._adminsPerDept.keys,
        ..._classesPerDept.keys,
      }.toList()..sort();

      for (final dept in allDepts) {
        s2.appendRow([
          TextCellValue(dept),
          IntCellValue(_adminsPerDept[dept] ?? 0),
          IntCellValue(_classesPerDept[dept] ?? 0),
          IntCellValue(_studentsPerDept[dept] ?? 0),
          IntCellValue(_logsPerDept[dept] ?? 0),
        ]);
      }

      // ── Sheet 3: Class Breakdown ───────────────────────────────────
      final s3 = excel['Class Breakdown'];
      final h3 = [
        'Class Name', 'Class Code', 'Managed By (Admin ID)',
        'Admin Level', 'Department', 'Students Enrolled', 'Total Logs',
      ];
      s3.appendRow(h3.map((v) => TextCellValue(v)).toList());

      final Map<String, String> adminDept = {
        for (final a in _admins)
          (a.data['username'] as String? ?? a.$id): (a.data['department'] as String? ?? 'Unassigned'),
      };
      final Map<String, dynamic> adminLevel = {
        for (final a in _admins)
          (a.data['username'] as String? ?? a.$id): a.data['level'],
      };

      for (final c in _classes) {
        final d = c.data;
        final adminId = d['createdBy'] as String? ?? '';
        final dept = adminDept[adminId] ?? 'Unassigned';
        final level = adminLevel[adminId];
        final students = (d['studentIds'] as List<dynamic>? ?? []).length;

        s3.appendRow([
          TextCellValue(d['className'] as String? ?? ''),
          TextCellValue(d['classCode'] as String? ?? ''),
          TextCellValue(adminId),
          TextCellValue(level != null ? _levelLabel(level) : 'Unknown'),
          TextCellValue(dept),
          IntCellValue(students),
          IntCellValue(_logsPerClass[c.$id] ?? 0),
        ]);
      }

      // Remove the default blank sheet Excel creates
      excel.delete('Sheet1');

      // Save file
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');

      final dir = Platform.isWindows
          ? Directory('${Platform.environment['USERPROFILE']}\\Downloads')
          : await getExternalStorageDirectory();
      if (dir == null) throw Exception('Could not find downloads directory');

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${dir.path}/dean_admin_report_$timestamp.xlsx';
      await File(path).writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: dean_admin_report_$timestamp.xlsx'),
            backgroundColor: kDeanDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeanGold));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allDepts = {
      ..._adminsPerDept.keys,
      ..._classesPerDept.keys,
    }.toList()..sort();

    return RefreshIndicator(
      onRefresh: _load,
      color: kDeanGold,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ── Summary cards ──────────────────────────────────────────
          Row(
            children: [
              _SummaryCard(label: 'Total Admins', value: '${_admins.length}', icon: Icons.manage_accounts),
              const SizedBox(width: 12),
              _SummaryCard(label: 'Total Classes', value: '${_classes.length}', icon: Icons.class_outlined),
              const SizedBox(width: 12),
              _SummaryCard(label: 'Attendance Logs', value: '${_logs.length}', icon: Icons.fact_check_outlined),
            ],
          ),
          const SizedBox(height: 24),

          // ── Export button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _exportExcel,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDeanGold,
                foregroundColor: kDeanDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _exporting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kDeanDark))
                  : const Icon(Icons.download_rounded),
              label: Text(
                _exporting ? 'Generating Excel...' : 'Download Excel Report',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '3 sheets: Admin Overview · Department Summary · Class Breakdown',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── Department breakdown ───────────────────────────────────
          Text('By Department',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...allDepts.map((dept) {
            final admCount = _adminsPerDept[dept] ?? 0;
            final clsCount = _classesPerDept[dept] ?? 0;
            final logCount = _logsPerDept[dept] ?? 0;
            final stuCount = _studentsPerDept[dept] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kDeanGold.withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatPill(label: 'Admins', value: admCount, color: const Color(0xFF7A6A8A)),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Classes', value: clsCount, color: const Color(0xFF4E7A8A)),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Students', value: stuCount, color: kDeanGold),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Logs', value: logCount, color: Colors.green.shade700),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),

          // ── Admin list ─────────────────────────────────────────────
          Text('Admin Activity',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._admins.map((a) {
            final d = a.data;
            final id = d['username'] as String? ?? a.$id;
            final role = d['role'] as String?;
            final level = d['level'];
            final roleLabel = (role == 'admin' && level != null)
                ? _levelLabel(level)
                : _roleLabel(role);
            final classes = _classesPerAdmin[id] ?? 0;
            final logs = _logsPerAdmin[id] ?? 0;
            final status = d['status'] as String? ?? 'active';
            final isDisabled = status == 'disabled';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kDeanGold.withValues(alpha: 0.12),
                    child: Text(
                      (d['name'] as String? ?? id).isNotEmpty
                          ? (d['name'] as String? ?? id)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: kDeanDark, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'] as String? ?? id,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(roleLabel,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$classes classes',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$logs logs',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  if (isDisabled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Disabled',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade700,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: kDeanDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: kDeanGold, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$value $label',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// ADMIN LIST COMPONENT
// ---------------------------------------------------------------------------
class _AdminListTab extends StatefulWidget {
  const _AdminListTab({super.key});

  @override
  State<_AdminListTab> createState() => _AdminListTabState();
}

class _AdminListTabState extends State<_AdminListTab> {
  List<models.Document> _admins = [];
  bool _loading = true;
  RealtimeSubscription? _sub;

  final List<String> departments = [
    "School of Computing (SoC)",
    "School of Electrical & Electronics Engineering (SEEE)",
    "School of Mechanical Engineering (SoME)",
    "School of Civil Engineering (SoCE)",
    "School of Chemical & Biotechnology (SCBT)",
    "School of Law",
    "School of Management (SoM)",
    "School of Arts, Sciences, Humanities & Education (SASHE)"
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _sub = AppwriteService.realtime
        .subscribe(['databases.6a2c10dc000d5e50f314.collections.users.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchAdmins();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'users',
        queries: [
          Query.equal('role', [
            'admin',
            'officeAdmin',
            'eventAdmin',
            'hrAdmin',
            'securityAdmin',
          ]),
          Query.limit(500),
        ],
      );
      if (mounted) {
        setState(() {
          _admins = result.documents;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('_fetchAdmins error: $e');
    }
  }

  void _showAddAdminSheet() {
    const roleValues = [
      'admin', 'admin', 'admin',
      'officeAdmin', 'eventAdmin', 'hrAdmin', 'securityAdmin',
    ];
    const levelValues = [1, 2, 3, 0, 0, 0, 0];
    const roleLabels = [
      'Institution Admin', 'Dept. Head (HoD)', 'Team Leader',
      'Office Admin', 'Event Admin', 'HR Admin', 'Security Admin',
    ];
    const roleShort = ['L1', 'L2', 'L3', 'Office', 'Event', 'HR', 'Security'];
    const roleSubtitles = [
      'L1 — Full institutional oversight',
      'L2 — Department management',
      'L3 — Class-level control',
      'Biometrics & attendance records',
      'Exclusive event hosting & QR scanning',
      'Leave requests & registration approvals',
      'Audit logs & access control',
    ];
    const roleIcons = [
      Icons.account_balance_outlined,
      Icons.domain_outlined,
      Icons.class_outlined,
      Icons.manage_accounts_outlined,
      Icons.event_outlined,
      Icons.people_alt_outlined,
      Icons.security_outlined,
    ];
    const roleColors = [
      Color(0xFF6A8A73),
      Color(0xFF4E7A8A),
      Color(0xFF7A6A8A),
      Color(0xFF8A6A6A),
      Color(0xFF3D6B8A),
      Color(0xFF8A7A2A),
      Color(0xFF8A2A2A),
    ];
    const roleNeedsDept = [true, true, true, true, false, true, false];

    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedDept = departments.first;
    int selectedIdx = 0;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final color = roleColors[selectedIdx];
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Onboard New Admin",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Select a role, then fill in the details.",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 20),

                  // ─── Role type selector ────────────────────────────────
                  Text("Admin Role",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final selected = selectedIdx == i;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 72,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? roleColors[i]
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? roleColors[i]
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcons[i],
                                    size: 20,
                                    color: selected
                                        ? Colors.white
                                        : roleColors[i]),
                                const SizedBox(height: 5),
                                Text(
                                  roleShort[i],
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? Colors.white
                                          : roleColors[i]),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Description of selected role
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(roleIcons[selectedIdx], size: 15, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            roleSubtitles[selectedIdx],
                            style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ─── Form fields ───────────────────────────────────────
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Admin Username (ID)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: 'Initial Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),

                  // Department — only for roles that need it
                  if (roleNeedsDept[selectedIdx]) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedDept,
                      decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      items: departments
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedDept = v!),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (usernameCtrl.text.trim().isEmpty ||
                                  passCtrl.text.trim().isEmpty) return;
                              setSheetState(() => saving = true);

                              try {
                                final exists = await AppwriteService.databases
                                    .listDocuments(
                                  databaseId: '6a2c10dc000d5e50f314',
                                  collectionId: 'users',
                                  queries: [
                                    Query.equal('username',
                                        usernameCtrl.text.trim()),
                                  ],
                                );
                                if (exists.documents.isNotEmpty) {
                                  setSheetState(() => saving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Username already exists.')));
                                  }
                                  return;
                                }

                                final docData = <String, dynamic>{
                                  'username': usernameCtrl.text.trim(),
                                  'name': nameCtrl.text.trim().isNotEmpty
                                      ? nameCtrl.text.trim()
                                      : usernameCtrl.text.trim(),
                                  'password': passCtrl.text.trim(),
                                  'role': roleValues[selectedIdx],
                                  'status': 'active',
                                  'createdAt':
                                      DateTime.now().toIso8601String(),
                                };
                                if (roleValues[selectedIdx] == 'admin') {
                                  docData['level'] =
                                      levelValues[selectedIdx];
                                  docData['managedClasses'] = <String>[];
                                }
                                if (roleNeedsDept[selectedIdx]) {
                                  docData['department'] = selectedDept;
                                }

                                await AppwriteService.databases
                                    .createDocument(
                                  databaseId: '6a2c10dc000d5e50f314',
                                  collectionId: 'users',
                                  documentId: ID.unique(),
                                  data: docData,
                                );

                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _fetchAdmins();
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(
                                              '${roleLabels[selectedIdx]} onboarded.')));
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              "Create ${roleLabels[selectedIdx]}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns true once [adminDoc] owns no classes (as head admin or
  /// supervisor), prompting the Dean to reassign any it still owns first.
  /// Returns false if the Dean cancels while classes are still owned.
  Future<bool> _ensureNoOwnedClasses(models.Document adminDoc) async {
    final username = adminDoc.data['username'] as String? ?? '';
    while (true) {
      final owned = await AdminHierarchyService.findOwnedClasses(username);
      if (owned.isEmpty) return true;
      if (!mounted) return false;

      final chosenId = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Reassign Classes First"),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${adminDoc.data['name'] ?? username} still owns "
                  "${owned.length} class${owned.length == 1 ? '' : 'es'}. "
                  "Reassign each one before suspending or deleting this "
                  "account.",
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: owned.length,
                    itemBuilder: (_, i) {
                      final classDoc = owned[i];
                      final data = classDoc.data;
                      final assignments =
                          AdminHierarchyService.readAssignments(data);
                      final role = assignments.headAdminId == username
                          ? "Head admin"
                          : "Supervisor";
                      return ListTile(
                        dense: true,
                        title: Text(data['className'] as String? ?? 'Class'),
                        subtitle: Text(role),
                        trailing: TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogCtx, classDoc.$id),
                          child: const Text("Reassign"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );

      if (chosenId == null) return false;
      if (!mounted) return false;

      final classDoc = owned.firstWhere((d) => d.$id == chosenId);
      await showClassStaffAssignmentSheet(
        context: context,
        classDoc: classDoc,
        l1AdminId: classDoc.data['createdBy'] as String? ?? '',
        isDean: true,
      );
      // Loop back and re-check ownership after the reassignment.
    }
  }

  void _showAdminDetails(models.Document doc) {
    final data = doc.data;
    final bool isActive = data['status'] != 'disabled';
    final passCtrl =
        TextEditingController(text: data['password'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    profilePictureId: data['profilePictureId'] as String?,
                    fallbackName: data['name'] as String? ?? '?',
                    radius: 24,
                    backgroundColor: kDeanDark,
                    foregroundColor: kDeanGold,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            data['name'] as String? ??
                                data['username'] as String? ??
                                'Admin',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                            "${data['department'] ?? 'No Dept'} Ã¢â‚¬Â¢ ${data['username']}",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(isActive ? "ACTIVE" : "DISABLED",
                        style: TextStyle(
                            color:
                                isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Admin Controls",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminHomePage(
                            adminName: data['name'] as String? ??
                                data['username'] as String? ??
                                '',
                            adminId: data['username'] as String? ?? '',
                            isDean: true,
                            adminLevel: 1, // Dean always gets Level 1
                          ),
                        ));
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text("Enter Supervision Mode",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeanGold,
                    foregroundColor: kDeanDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Override Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: kDeanDark),
                    onPressed: () async {
                      if (passCtrl.text.trim().isEmpty) return;
                      await AppwriteService.databases.updateDocument(
                        databaseId: '6a2c10dc000d5e50f314',
                        collectionId: 'users',
                        documentId: doc.$id,
                        data: {'password': passCtrl.text.trim()},
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Password overridden.')));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    isActive
                        ? Icons.block
                        : Icons.check_circle_outline,
                    color: isActive ? Colors.orange : Colors.green),
                title: Text(
                    isActive
                        ? "Suspend Account"
                        : "Reactivate Account",
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    isActive
                        ? "Admin will not be able to log in."
                        : "Restore full admin access.",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500)),
                onTap: () async {
                  if (isActive) {
                    final canProceed = await _ensureNoOwnedClasses(doc);
                    if (!canProceed) return;
                  }
                  await AppwriteService.databases.updateDocument(
                    databaseId: '6a2c10dc000d5e50f314',
                    collectionId: 'users',
                    documentId: doc.$id,
                    data: {
                      'status': isActive ? 'disabled' : 'active'
                    },
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _fetchAdmins();
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever,
                    color: Colors.red),
                title: const Text("Delete Administrator",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red)),
                subtitle: Text(
                    "Permanently remove this admin record.",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade300)),
                onTap: () async {
                  final canProceed = await _ensureNoOwnedClasses(doc);
                  if (!canProceed || !mounted) return;
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text("Confirm Deletion"),
                      content: const Text(
                          "This action cannot be undone. Delete this admin?"),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(c, false),
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text("Delete")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await AppwriteService.databases.deleteDocument(
                      databaseId: '6a2c10dc000d5e50f314',
                      collectionId: 'users',
                      documentId: doc.$id,
                    );
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _fetchAdmins();
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // â"€â"€ Level colour/icon/label helpers â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  static const _levelMeta = {
    1: (
      color: Color(0xFF6A8A73),   // sage green
      icon: Icons.account_balance_outlined,
      label: "Level 1",
      scope: "Institution control",
    ),
    2: (
      color: Color(0xFF4E7A8A),   // teal-blue
      icon: Icons.domain_outlined,
      label: "Level 2",
      scope: "Department oversight",
    ),
    3: (
      color: Color(0xFF7A6A8A),   // muted violet
      icon: Icons.class_outlined,
      label: "Level 3",
      scope: "Class management",
    ),
  };

  static const _specialRoleMeta = {
    'officeAdmin': (
      color: Color(0xFF8A6A6A),
      icon: Icons.manage_accounts_outlined,
      label: "Office Admin",
      badge: "OA",
      scope: "Biometrics & records",
    ),
    'eventAdmin': (
      color: Color(0xFF3D6B8A),
      icon: Icons.event_outlined,
      label: "Event Admin",
      badge: "EA",
      scope: "Event hosting",
    ),
    'hrAdmin': (
      color: Color(0xFF8A7A2A),
      icon: Icons.people_alt_outlined,
      label: "HR Admin",
      badge: "HR",
      scope: "Leave & approvals",
    ),
    'securityAdmin': (
      color: Color(0xFF8A2A2A),
      icon: Icons.security_outlined,
      label: "Security Admin",
      badge: "SA",
      scope: "Audit & access control",
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kDeanDark,
        foregroundColor: kDeanGold,
        onPressed: _showAddAdminSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Onboard Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kDeanDark))
          : _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No Administrators Found",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ],
                  ),
                )
              : _buildGroupedList(),
    );
  }

  Widget _buildGroupedList() {
    final Map<int, List<models.Document>> levelGrouped = {1: [], 2: [], 3: []};
    final Map<String, List<models.Document>> specialGrouped = {
      'officeAdmin': [],
      'eventAdmin': [],
      'hrAdmin': [],
      'securityAdmin': [],
    };

    for (final doc in _admins) {
      final role = doc.data['role'] as String? ?? 'admin';
      if (role == 'admin') {
        final lvl = (doc.data['level'] as int?) ?? 1;
        final clamped = (lvl >= 1 && lvl <= 3) ? lvl : 1;
        levelGrouped[clamped]!.add(doc);
      } else if (specialGrouped.containsKey(role)) {
        specialGrouped[role]!.add(doc);
      }
    }

    final specialCount =
        specialGrouped.values.fold(0, (sum, list) => sum + list.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        _buildSummaryStrip(levelGrouped, specialCount),
        const SizedBox(height: 20),

        for (final level in [1, 2, 3])
          if (levelGrouped[level]!.isNotEmpty) ...[
            _buildLevelHeader(level, levelGrouped[level]!.length),
            const SizedBox(height: 10),
            ...levelGrouped[level]!.map((doc) => _buildAdminCard(doc)),
            const SizedBox(height: 20),
          ],

        for (final role in ['officeAdmin', 'eventAdmin', 'hrAdmin', 'securityAdmin'])
          if (specialGrouped[role]!.isNotEmpty) ...[
            _buildSpecialRoleHeader(role, specialGrouped[role]!.length),
            const SizedBox(height: 10),
            ...specialGrouped[role]!.map((doc) => _buildAdminCard(doc)),
            const SizedBox(height: 20),
          ],
      ],
    );
  }

  // â"€â"€ Summary strip (three mini-stat tiles) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _buildSummaryStrip(
      Map<int, List<models.Document>> grouped, int specialCount) {
    return Row(
      children: [1, 2, 3].map((lvl) {
        final meta = _levelMeta[lvl]!;
        final count = grouped[lvl]?.length ?? 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: lvl < 3 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: meta.color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: meta.color.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: meta.color),
                ),
                Text(
                  meta.label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // â"€â"€ Section header for each level â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _buildLevelHeader(int level, int count) {
    final meta = _levelMeta[level]!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(meta.icon, color: meta.color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: meta.color),
            ),
            Text(
              meta.scope,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count ${count == 1 ? 'admin' : 'admins'}",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: meta.color),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRoleHeader(String role, int count) {
    final meta = _specialRoleMeta[role]!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(meta.icon, color: meta.color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: meta.color),
            ),
            Text(
              meta.scope,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count ${count == 1 ? 'admin' : 'admins'}",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: meta.color),
          ),
        ),
      ],
    );
  }

  // â"€â"€ Individual admin card â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _buildAdminCard(models.Document doc) {
    final data = doc.data;
    final isActive = data['status'] != 'disabled';
    final String? lastLoginStr = data['lastLogin'] as String?;
    final String role = data['role'] as String? ?? 'admin';
    final int level = (data['level'] as int?) ?? 1;

    final Color cardColor;
    final IconData cardIcon;
    final String badgeText;
    if (role == 'admin') {
      final m = _levelMeta[level] ?? _levelMeta[1]!;
      cardColor = m.color;
      cardIcon = m.icon;
      badgeText = '$level';
    } else {
      final m = _specialRoleMeta[role] ??
          (
            color: kDeanGold,
            icon: Icons.admin_panel_settings,
            label: 'Admin',
            badge: '?',
            scope: '',
          );
      cardColor = m.color;
      cardIcon = m.icon;
      badgeText = m.badge;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => _showAdminDetails(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar with level-coloured ring
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cardColor.withValues(alpha: 0.35), width: 2),
                      color: isActive
                          ? cardColor.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.07),
                    ),
                    child: Icon(
                      cardIcon,
                      color: isActive ? cardColor : Colors.red,
                      size: 22,
                    ),
                  ),
                  // Badge: level number for standard admins, role code for special roles
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] as String? ??
                                data['username'] as String? ??
                                '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("DISABLED",
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            data['department'] as String? ?? 'No Dept',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "â€¢ ${data['username']}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lastLoginStr != null
                          ? "Last login: ${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(lastLoginStr))}"
                          : "Never logged in",
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

