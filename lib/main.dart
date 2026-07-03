import 'dart:async'; // Required for Splash Screen Timer
import 'package:flutter/services.dart';
import 'forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'admin_level_select_page.dart';
import 'dean_login.dart';
import 'app_theme.dart';
import 'package:appwrite/appwrite.dart';
import 'services/appwrite_service.dart'; // or correct path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW: Animated Splash Screen with PNG Effect & Slow Disappear
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // Phase 1: Logo Appears
    _controller.forward();

    // Phase 2: Logic to disappear slowly and then navigate
    Timer(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      // Change duration to make the disappear phase slower (1 second)
      _controller.duration = const Duration(milliseconds: 1000);

      // Reverse the animation (logo shrinks and fades out)
      _controller.reverse();

      // Wait for the slow fade to finish
      await Future.delayed(const Duration(milliseconds: 1100));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kGreen.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/upasthiti.png',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOGIN PAGE - ALL FUNCTIONS PRESERVED
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final uniqueCodeController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isObscure = true;

  int _secretTapCount = 0;
  Timer? _secretTimer;

  void _handleSecretTap() {
    _secretTapCount++;
    if (_secretTapCount == 5) {
      // Haptic feedback could be added here if vibrator is available
      setState(() {});
    }
    _secretTimer?.cancel();
    _secretTimer = Timer(const Duration(seconds: 2), () {
      _secretTapCount = 0;
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    uniqueCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (uniqueCodeController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar("Please enter your unique code and password.");
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
      final uniqueCode = uniqueCodeController.text.trim();
      final password = passwordController.text.trim();

      // Query by username only — password verified client-side for dual-mode support
      final response = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [
          Query.equal('username', uniqueCode),
        ],
      );

      if (response.documents.isEmpty) {
        _dismissDialogAndShow(statusText, "Invalid credentials.");
        return;
      }

      // Dual-mode password verification (supports plaintext legacy + hashed)
      final storedPassword = response.documents.first.data['password'] as String? ?? '';
      if (!AppwriteService.verifyPassword(password, storedPassword)) {
        _dismissDialogAndShow(statusText, "Invalid credentials.");
        return;
      }

      final data = response.documents.first.data;

      // RBAC Security Check
      final role = data['role'] as String?;
      if (role == 'admin' || role == 'dean') {
        _dismissDialogAndShow(
          statusText,
          "Unauthorized access. Use the correct portal.",
        );
        return;
      }

      // Admin Validation Check
      final status = data['status'] as String?;
      if (status == 'pending') {
        _dismissDialogAndShow(
          statusText,
          "Your account validation is pending from the admin. Please try again later.",
        );
        return;
      }

      statusText.value = "Finalizing...";

      // Auto-upgrade plaintext password to hashed on successful login
      final updateData = <String, dynamic>{
        'lastLogin': DateTime.now().toIso8601String(),
      };
      if (!AppwriteService.isHashed(storedPassword)) {
        updateData['password'] = AppwriteService.hashPassword(password);
      }
      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        documentId: response.documents.first.$id,
        data: updateData,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            name: data['name'] ?? "User",
            username: data['username'] ?? "Unknown",
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      if (mounted) _showSnackBar("An unexpected error occurred: $e");
    }
  }

  void _dismissDialogAndShow(ValueNotifier<String> statusText, String message) {
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _handleSecretTap,
                              child: const Text(
                                "upasthiti",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminLevelSelectPage()),
                              ),
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              label: const Text(
                                "ADMIN",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome Back", style: AppTheme.headingWhite),
                            const SizedBox(height: 8),
                            Text(
                              "Verify your unique code and identity.",
                              style: AppTheme.subheadingGrey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: RisingSheet(
                          child: Container(
                            width: double.infinity,
                            decoration: AppTheme.bottomSheet,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                AppTheme.sheetHandle,
                                TextFormField(
                                  controller: uniqueCodeController,
                                  textInputAction: TextInputAction.next,
                                  decoration: AppTheme.inputDecoration(
                                    "Unique Code",
                                    Icons.badge_outlined,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _isObscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
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
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: AppTheme.kGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "First day at work? ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      ),
                                      child: const Text(
                                        "Register here",
                                        style: TextStyle(
                                          color: AppTheme.kGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 50),
                                Center(
                                  child: RepaintBoundary(
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
                                ),
                                const SizedBox(height: 40),
                                if (_secretTapCount >= 5)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const DeanLoginPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1A1C29),
                                        foregroundColor: const Color(
                                          0xFFD4AF37,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(Icons.shield, size: 16),
                                      label: const Text(
                                        "Super Admin Portal",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

