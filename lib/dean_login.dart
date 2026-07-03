import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'main.dart'; // Import main to navigate back
import 'dean_home_page.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

class DeanLoginPage extends StatefulWidget {
  const DeanLoginPage({super.key});

  @override
  State<DeanLoginPage> createState() => _DeanLoginPageState();
}

class _DeanLoginPageState extends State<DeanLoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🔐 DEAN LOGIN LOGIC — Now backed by Appwrite database
  Future<void> _login() async {
    final deanId = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (deanId.isEmpty || password.isEmpty) {
      _showError("Please enter Dean ID and Password.");
      return;
    }

    final statusText = ValueNotifier("Verifying Master Credentials...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1C29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: statusText,
            builder: (context, value, child) {
              return Row(
                children: [
                  const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
      // Query Appwrite for dean-role users
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [
          Query.equal('username', deanId),
          Query.equal('role', 'dean'),
        ],
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result.documents.isEmpty) {
        _showError("Invalid Executive Credentials.");
        return;
      }

      final doc = result.documents.first;
      final storedPassword = doc.data['password'] as String? ?? '';

      // Dual-mode password verification
      if (!AppwriteService.verifyPassword(password, storedPassword)) {
        _showError("Invalid Executive Credentials.");
        return;
      }

      // Auto-upgrade plaintext password to hashed
      final updateData = <String, dynamic>{
        'lastLogin': DateTime.now().toIso8601String(),
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
        // Non-critical — login still succeeds even if update fails
      }
      // Trigger lazy background cleanup of old accounts
      AppwriteService.cleanupInactiveAccounts();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeanHomePage()),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError("Login failed: ${e.toString()}");
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Midnight Indigo Theme Colors
    const Color midnightIndigo = Color(0xFF10121C);
    const Color panelColor = Color(0xFF1A1C29);
    const Color goldAccent = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: midnightIndigo,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "upasthiti Executive",
                    style: TextStyle(
                      color: goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 2. TITLE SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Super Admin Portal",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Restricted System Access.",
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. WHITE SHEET (Form)
            Expanded(
              child: RisingSheet(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(35),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Inputs
                        TextFormField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Executive ID",
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.shield,
                              color: goldAccent,
                            ),
                            filled: true,
                            fillColor: midnightIndigo,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: goldAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: _isObscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Master Password",
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: goldAccent,
                            ),
                            filled: true,
                            fillColor: midnightIndigo,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: goldAccent,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _isObscure = !_isObscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Authorize",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: midnightIndigo,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
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


