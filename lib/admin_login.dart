import 'dart:math'; // For Random Captcha
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'admin_home_page.dart';
import 'office_admin_home_page.dart';
import 'event_admin_home_page.dart';
import 'hr_admin_home_page.dart';
import 'security_admin_home_page.dart';
import 'department_admin_home_page.dart';
import 'dean_home_page.dart';
import 'admin_onboarding_page.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'services/admin_roles.dart';

/// The single login page for every admin type: Dean, L1/L2/L3, Event and
/// department admins (Office / HR / Security / Finance …). The dashboard is
/// chosen from the account's record; see [adminKindOf].
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  bool _isObscure = true;


  /// An admin needs first-login onboarding until it has completed it once.
  static bool _needsOnboarding(Map<String, dynamic> data) {
    final onboardedAt = data['presenceOnboardedAt'] as String?;
    return onboardedAt == null || onboardedAt.isEmpty;
  }

  /// Routes to the first-login onboarding page (photo + face + boundary pin)
  /// when [needsOnboarding], otherwise straight to [destination].
  void _navigateAfterLogin({
    required Widget destination,
    required String docId,
    required String username,
    required String name,
    required bool needsOnboarding,
    required Color accent,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => needsOnboarding
            ? AdminOnboardingPage(
                adminDocId: docId,
                username: username,
                adminName: name,
                destination: destination,
                accent: accent,
              )
            : destination,
      ),
    );
  }


  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Captcha State
  String _generatedCaptcha = "";

  @override
  void initState() {
    super.initState();
    _generateCaptcha(); // Generate code on startup

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    usernameController.dispose();
    passwordController.dispose();
    captchaController.dispose();
    super.dispose();
  }

  // GENERATE RANDOM CAPTCHA
  void _generateCaptcha() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars like I, 1, 0, O
    setState(() {
      _generatedCaptcha = List.generate(
        5,
        (index) => chars[Random().nextInt(chars.length)],
      ).join();
    });
  }

  // LOGIN LOGIC
  Future<void> _login() async {
    // 1. Check Captcha
    if (captchaController.text.toUpperCase().trim() != _generatedCaptcha) {
      _showError("Incorrect Captcha. Try again.");
      _generateCaptcha(); // Refresh on fail
      captchaController.clear();
      return;
    }

    final adminId = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (adminId.isEmpty || password.isEmpty) {
      _showError("Please enter Admin ID and Password.");
      return;
    }

    final statusText = ValueNotifier("Authenticating...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: statusText,
            builder: (context, value, child) {
              return Row(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6A8A73)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      // Query by username only — password verified client-side for dual-mode support
      final query = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', adminId)],
      );

      if (query.documents.isEmpty) {
        _dismissAndShowError("Invalid Admin ID or Password");
        _generateCaptcha();
        return;
      }

      final doc = query.documents.first;
      final data = doc.data;

      // Dual-mode password verification (supports plaintext legacy + hashed)
      final storedPassword = data['password'] as String? ?? '';
      if (!AppwriteService.verifyPassword(password, storedPassword)) {
        _dismissAndShowError("Invalid Admin ID or Password");
        _generateCaptcha();
        return;
      }

      // The account's record alone decides which dashboard it gets.
      final kind = adminKindOf(data);
      if (kind == AdminKind.notAdmin) {
        _dismissAndShowError("This account doesn't have admin access.");
        _generateCaptcha();
        return;
      }

      if (data['status'] == 'disabled') {
        _dismissAndShowError("Your account has been disabled. Please contact administration.");
        _generateCaptcha();
        return;
      }

      statusText.value = "Finalizing...";

      // lastLogin + plaintext→hash upgrade + legacy role migration, in one write.
      final migration = legacyMigrationPatch(data);
      final updateData = <String, dynamic>{
        'lastLogin': DateTime.now().toIso8601String(),
        ...?migration,
      };
      if (!AppwriteService.isHashed(storedPassword)) {
        updateData['password'] = AppwriteService.hashPassword(password);
      }
      try {
        await AppwriteService.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: 'users',
          documentId: doc.$id,
          data: updateData,
        );
      } catch (_) {
        // Non-critical for the Dean (as in the old Dean portal); fatal otherwise.
        if (kind != AdminKind.dean) rethrow;
      }

      // Trigger lazy background cleanup of old accounts (not on L1–L3 logins).
      if (kind != AdminKind.hierarchy) {
        AppwriteService.cleanupInactiveAccounts();
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      if (kind == AdminKind.dean) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeanHomePage()),
        );
        return;
      }

      final adminName = data['name'] as String? ?? adminId;
      final dept = functionalDeptOf(data) ?? data['department'] as String? ?? '';
      final Widget destination;
      switch (kind) {
        case AdminKind.hierarchy:
          destination = AdminHomePage(
            adminName: adminName,
            adminId: adminId,
            adminLevel: hierarchyLevelOf(data),
          );
          break;
        case AdminKind.office:
          destination = OfficeAdminHomePage(
            adminName: adminName,
            adminId: adminId,
            adminDepartment: dept,
          );
          break;
        case AdminKind.hr:
          destination = HrAdminHomePage(adminName: adminName, adminId: adminId, adminDepartment: dept);
          break;
        case AdminKind.security:
          destination = SecurityAdminHomePage(adminName: adminName, adminId: adminId);
          break;
        case AdminKind.event:
          destination = EventAdminHomePage(adminName: adminName, adminId: adminId);
          break;
        default:
          destination = DepartmentAdminHomePage(
            adminName: adminName,
            adminId: adminId,
            department: dept,
          );
      }
      _navigateAfterLogin(
        destination: destination,
        docId: doc.$id,
        username: adminId,
        name: adminName,
        needsOnboarding: _needsOnboarding(data),
        accent: adminColor({...data, ...?migration}),
      );
    } catch (e) {
      _dismissAndShowError("An unexpected error occurred: $e");
    }
  }

  void _dismissAndShowError(String message) {
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER & USER BUTTON (Updated to match main.dart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "upasthiti",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    tooltip: "Back to user login",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 2. TITLE SECTION (Polished Typography)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Admin Portal",
                    style: AppTheme.headingWhite,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in with your admin credentials.",
                    style: AppTheme.subheadingGrey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. WHITE SHEET (Form)
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    decoration: AppTheme.bottomSheet,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppTheme.sheetHandle,

                          // Inputs
                          TextFormField(
                            controller: usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration(
                              "Admin ID",
                              Icons.admin_panel_settings_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _isObscure,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration(
                              "Password",
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ðŸ›¡ï¸ CAPTCHA SECTION (Polished UI)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Security Check",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Captcha Display Code
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          image: const DecorationImage(
                                            image: NetworkImage(
                                              "https://www.transparenttextures.com/patterns/black-scales.png",
                                            ),
                                            opacity: 0.05,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _generatedCaptcha
                                                .split('')
                                                .join(' '), // Add spacing
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              letterSpacing: 6,
                                              color: Color(0xFF2D3142),
                                              fontFamily: 'Courier',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Refresh Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6A8A73,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: _generateCaptcha,
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          color: AppTheme.kGreen,
                                        ),
                                        tooltip: "Refresh Captcha",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: captchaController,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: AppTheme.inputDecoration(
                                    "Enter Captcha",
                                    Icons.security,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Secure Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // ---------------------------------------------------
                          // PROFESSIONAL LOGO FOOTER (Updated to withValues)
                          // ---------------------------------------------------
                          const SizedBox(height: 50),
                          Center(
                            child: Opacity(
                              opacity: 0.6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6A8A73,
                                          ).withValues(alpha: 0.15),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color(
                                          0xFF6A8A73,
                                        ).withValues(alpha: 0.1),
                                        BlendMode.srcATop,
                                      ),
                                      child: Image.asset(
                                        'assets/upasthiti.png',
                                        width: 90,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "POWERED BY upasthiti",
                                    style: TextStyle(
                                      color: const Color(
                                        0xFF6A8A73,
                                      ).withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40), // Clear bottom of screen
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
