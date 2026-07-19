import 'dart:io';

import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/admin_presence_service.dart';

/// Once-a-day presence widget shared by every admin home page (L1/L2/L3,
/// Office/Event/HR/Security). After 05:30 the admin may report presence once —
/// re-verifying face + geofence — then sign out. See [AdminPresenceService].
class AdminPresenceCard extends StatefulWidget {
  final String adminId;
  final String adminName;
  final String role; // 'admin' | 'officeAdmin' | 'eventAdmin' | ...
  final int level; // 0 for special roles, 1/2/3 for hierarchy admins
  final String department;
  final String? parentAdminId;
  final Color accent;

  /// Called after sign-out is recorded (e.g. to log the user out of the app).
  final VoidCallback? onSignedOut;

  const AdminPresenceCard({
    super.key,
    required this.adminId,
    required this.adminName,
    required this.role,
    required this.level,
    required this.department,
    this.parentAdminId,
    required this.accent,
    this.onSignedOut,
  });

  @override
  State<AdminPresenceCard> createState() => _AdminPresenceCardState();
}

class _AdminPresenceCardState extends State<AdminPresenceCard> {
  models.Document? _today;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Records the login for today (idempotent) then loads today's row.
    await AdminPresenceService.recordLogin(
      adminId: widget.adminId,
      adminName: widget.adminName,
      role: widget.role,
      level: widget.level,
      department: widget.department,
      parentAdminId: widget.parentAdminId,
    );
    await _refresh();
  }

  Future<void> _refresh() async {
    final doc = await AdminPresenceService.fetchTodayLog(widget.adminId);
    if (mounted) {
      setState(() {
        _today = doc;
        _loading = false;
      });
    }
  }

  bool get _reported =>
      _today != null &&
      (_today!.data['presenceTime'] as String?)?.isNotEmpty == true;

  bool get _signedOut =>
      _today != null &&
      (_today!.data['signOutTime'] as String?)?.isNotEmpty == true;

  String? _timeStr(String field) {
    final raw = _today?.data[field] as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _report() async {
    if (_busy) return;
    if (!AdminPresenceService.isPresenceWindowOpen()) {
      _snack('Presence can only be reported after 5:30 AM.');
      return;
    }
    setState(() => _busy = true);
    final progress = ValueNotifier<String>('Checking your location…');
    _showProgress(progress);

    try {
      // 1. Geofence — a location MUST be set before presence can be reported.
      final boundary = await AdminPresenceService.boundaryForAdmin(widget.adminId);
      if (boundary == null) {
        _closeProgress();
        _snack('Your presence location has not been set yet. Ask the office admin to set your location.');
        setState(() => _busy = false);
        return;
      }
      bool inside = false;
      try {
        inside = await AdminPresenceService.isInsideBoundary(boundary);
      } catch (_) {
        inside = false;
      }
      if (!inside) {
        _closeProgress();
        _snack('You are outside your assigned location. Move closer and try again.');
        setState(() => _busy = false);
        return;
      }

      // 2. Camera
      progress.value = 'Opening camera…';
      if (!mounted) return;
      final File? photo = await AdminPresenceService.capturePhoto(context);
      if (photo == null) {
        _closeProgress();
        _snack('A photo is required to report presence.');
        setState(() => _busy = false);
        return;
      }

      // 3. Face verification
      progress.value = 'Verifying your face…';
      final faceError = await AdminPresenceService.verifyFace(widget.adminId, photo);
      if (faceError != null) {
        _closeProgress();
        _snack('Face verification failed: $faceError');
        setState(() => _busy = false);
        return;
      }

      // 4. Save
      progress.value = 'Saving…';
      final status = await AdminPresenceService.savePresence(
        adminId: widget.adminId,
        adminName: widget.adminName,
        role: widget.role,
        level: widget.level,
        department: widget.department,
        parentAdminId: widget.parentAdminId,
        insideGeofence: inside,
        faceVerified: true,
      );

      _closeProgress();
      await _refresh();
      _snack(status == 'Late'
          ? 'Presence reported — marked Late.'
          : 'Presence reported. Have a great day!');
    } catch (e) {
      _closeProgress();
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AdminPresenceService.signOut(widget.adminId);
      await _refresh();
      widget.onSignedOut?.call();
    } catch (e) {
      _snack('Sign-out failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showProgress(ValueNotifier<String> notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ValueListenableBuilder<String>(
          valueListenable: notifier,
          builder: (_, value, __) => Row(
            children: [
              CircularProgressIndicator(color: widget.accent),
              const SizedBox(width: 20),
              Expanded(child: Text(value)),
            ],
          ),
        ),
      ),
    );
  }

  void _closeProgress() {
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final IconData icon;
    final String title;
    final String subtitle;
    final Color tone;

    if (_signedOut) {
      icon = Icons.logout_rounded;
      tone = Colors.grey.shade600;
      title = 'Signed out';
      subtitle = 'Presence ${_timeStr('presenceTime') ?? ''} · Out ${_timeStr('signOutTime') ?? ''}';
    } else if (_reported) {
      final status = (_today!.data['status'] as String?) ?? 'Present';
      final isLate = status == 'Late';
      icon = isLate ? Icons.schedule_rounded : Icons.check_circle_rounded;
      tone = isLate ? Colors.orange.shade700 : Colors.green.shade600;
      title = isLate ? 'Present (Late)' : 'Present';
      subtitle = 'Reported at ${_timeStr('presenceTime') ?? '--'}';
    } else {
      final open = AdminPresenceService.isPresenceWindowOpen();
      icon = Icons.how_to_reg_outlined;
      tone = accent;
      title = 'Report today\'s presence';
      subtitle = open ? 'Face + location will be verified.' : 'Opens at 5:30 AM.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: tone, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87)),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_signedOut) ...[
                  const SizedBox(height: 14),
                  if (!_reported)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_busy ||
                                !AdminPresenceService.isPresenceWindowOpen())
                            ? null
                            : _report,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.how_to_reg, size: 18),
                        label: Text('Report Presence',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _signOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text('Sign Out',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
