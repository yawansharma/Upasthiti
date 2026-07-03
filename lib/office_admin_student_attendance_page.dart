import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';

const _kOAAccent = Color(0xFF8A6A6A);

class OfficeAdminStudentAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? profilePictureId;

  const OfficeAdminStudentAttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.profilePictureId,
  });

  @override
  State<OfficeAdminStudentAttendancePage> createState() =>
      _OfficeAdminStudentAttendancePageState();
}

class _OfficeAdminStudentAttendancePageState
    extends State<OfficeAdminStudentAttendancePage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String? _selectedClassId;
  List<Map<String, String>> _classes = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Computed stats ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredLogs {
    var logs = _logs;
    if (_selectedClassId != null) {
      logs = logs.where((l) => l['classId'] == _selectedClassId).toList();
    }
    if (_startDate != null) {
      logs = logs.where((l) {
        try {
          return !DateTime.parse(l['timestamp'] as String).isBefore(_startDate!);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    if (_endDate != null) {
      final end = _endDate!.add(const Duration(days: 1));
      logs = logs.where((l) {
        try {
          return DateTime.parse(l['timestamp'] as String).isBefore(end);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    return logs;
  }

  int get _presentCount => _filteredLogs
      .where((l) =>
          l['adminVerifiedStatus'] == 'Present' ||
          l['adminVerifiedStatus'] == 'Verified')
      .length;
  int get _absentCount =>
      _filteredLogs.where((l) => l['adminVerifiedStatus'] == 'Absent').length;
  int get _pendingCount =>
      _filteredLogs.where((l) => l['adminVerifiedStatus'] == 'Pending').length;

  Map<String, List<Map<String, dynamic>>> get _groupedLogs {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final log in _filteredLogs) {
      try {
        final ts = DateTime.parse(log['timestamp'] as String);
        final key = DateFormat('dd MMM yyyy').format(ts);
        map.putIfAbsent(key, () => []).add(log);
      } catch (_) {
        map.putIfAbsent('Unknown Date', () => []).add(log);
      }
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'attendance_logs',
        queries: [
          Query.equal('userId', widget.studentId),
          Query.orderDesc('timestamp'),
          Query.limit(2000),
        ],
      );

      final logs =
          result.documents.map((d) => Map<String, dynamic>.from(d.data)).toList();

      final classMap = <String, String>{};
      for (final log in logs) {
        final classId = log['classId'] as String? ?? '';
        final className = log['className'] as String? ?? classId;
        if (classId.isNotEmpty) classMap[classId] = className;
      }

      if (mounted) {
        setState(() {
          _logs = logs;
          _classes = classMap.entries
              .map((e) => {'id': e.key, 'name': e.value})
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
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
          colorScheme: const ColorScheme.light(primary: _kOAAccent),
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
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kOAAccent))
                    : _error != null
                        ? _buildError()
                        : Column(
                            children: [
                              _buildStatsBar(),
                              _buildFilters(),
                              Expanded(
                                child: _filteredLogs.isEmpty
                                    ? _buildEmpty()
                                    : _buildTimeline(),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          UserAvatar(
            profilePictureId: widget.profilePictureId,
            fallbackName: widget.studentName,
            radius: 22,
            backgroundColor: _kOAAccent.withValues(alpha: 0.25),
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "ID: ${widget.studentId}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kOAAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Attendance History",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final total = _filteredLogs.length;
    final pct = total > 0
        ? (_presentCount / total * 100).toStringAsFixed(1)
        : '0.0';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _kOAAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOAAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("$total", "Sessions"),
          _statItem("$pct%", "Present"),
          _statItem("$_absentCount", "Absent"),
          _statItem("$_pendingCount", "Pending"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 18, color: _kOAAccent),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedClassId = v),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _startDate != null
                    ? _kOAAccent.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _startDate != null
                      ? _kOAAccent.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16,
                      color: _startDate != null ? _kOAAccent : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _startDate != null
                        ? "${DateFormat('dd MMM').format(_startDate!)} – "
                            "${_endDate != null ? DateFormat('dd MMM').format(_endDate!) : '...'}"
                        : "Date Range",
                    style: TextStyle(
                      fontSize: 12,
                      color: _startDate != null ? _kOAAccent : Colors.grey,
                      fontWeight: _startDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (_startDate != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                      child: const Icon(Icons.close,
                          size: 14, color: _kOAAccent),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final grouped = _groupedLogs;
    final dates = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final date = dates[i];
        final logs = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                date,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black45),
              ),
            ),
            ...logs.map(_buildLogCard),
          ],
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final status = log['adminVerifiedStatus'] as String? ?? 'Pending';
    final entryStatus = log['entryStatus'] as String? ?? '';
    final inGeofence = log['isWithinGeofence'] as bool? ?? false;
    final className =
        log['className'] as String? ?? log['classId'] as String? ?? 'Unknown';

    String timeStr = '';
    try {
      final ts = DateTime.parse(log['timestamp'] as String);
      timeStr = DateFormat('HH:mm').format(ts);
    } catch (_) {}

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Present':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Absent':
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'Late':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.schedule_outlined;
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entryStatus.isNotEmpty)
                    Text(entryStatus,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      inGeofence
                          ? Icons.location_on_outlined
                          : Icons.location_off_outlined,
                      size: 12,
                      color: inGeofence
                          ? Colors.green.shade400
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(timeStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Failed to load attendance history",
                style: TextStyle(color: Colors.black54)),
          ],
        ),
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
            Icon(Icons.history_toggle_off_outlined,
                size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No attendance records found",
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text("Try adjusting the filters",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
