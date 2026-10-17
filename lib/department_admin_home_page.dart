import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'main.dart';
import 'services/admin_roles.dart';
import 'components/admin_presence_card.dart';

/// Placeholder dashboard for department admins whose department has no
/// dedicated dashboard yet (e.g. Finance). Office / HR / Security admins have
/// their own pages; see [adminKindOf].
class DepartmentAdminHomePage extends StatelessWidget {
  final String adminName;
  final String adminId;
  final String department;

  const DepartmentAdminHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
    required this.department,
  });

  Color get _accent =>
      adminColor({'role': 'admin', 'department': department});

  void _logout(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () => _logout(context),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            _buildHeader(context),
            AdminPresenceCard(
              adminId: adminId,
              adminName: adminName,
              role: 'admin',
              level: 0,
              department: department,
              accent: _accent,
              requiresLogoutVerification: true,
              onSignedOut: () => _logout(context),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.construction_outlined, size: 56, color: _accent),
                    const SizedBox(height: 16),
                    Text(
                      "$department dashboard coming soon",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your account is set up as a $department admin. "
                      "Features for this department will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$department Admin",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  adminName,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
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
}
