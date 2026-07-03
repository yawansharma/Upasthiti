import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _usernameController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Username, 2: Answer Question, 3: Reset Password
  bool _isLoading = false;
  String? _userId;
  String? _securityQuestion;
  String? _expectedAnswer;
  bool _isObscure = true;
  bool _isConfirmObscure = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar("Please enter your username/Unique ID.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', username)],
      );

      if (response.documents.isEmpty) {
        _showSnackBar("User not found.");
        return;
      }

      final doc = response.documents.first;
      final sq = doc.data['securityQuestion'] as String?;
      final sa = doc.data['securityAnswer'] as String?;

      if (sq == null || sa == null || sq.isEmpty || sa.isEmpty) {
        _showSnackBar("No security question is set for this account. Please contact your admin to reset your password.");
        return;
      }

      setState(() {
        _userId = doc.$id;
        _securityQuestion = sq;
        _expectedAnswer = sa;
        _currentStep = 2;
      });
    } catch (e) {
      _showSnackBar("Error checking user: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyAnswer() {
    final answer = _securityAnswerController.text.trim().toLowerCase();
    if (answer.isEmpty) {
      _showSnackBar("Please provide an answer.");
      return;
    }

    if (answer == _expectedAnswer?.toLowerCase()) {
      setState(() {
        _currentStep = 3;
      });
    } else {
      _showSnackBar("Incorrect answer.");
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters.");
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final hashedPassword = AppwriteService.hashPassword(newPassword);
      
      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        documentId: _userId!,
        data: {'password': hashedPassword},
      );

      _showSnackBar("Password reset successfully! You can now log in.");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Failed to reset password: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Account Recovery", style: AppTheme.headingWhite),
        const SizedBox(height: 10),
        Text("Enter your Unique ID to start.", style: AppTheme.subheadingGrey),
        const SizedBox(height: 40),
        TextFormField(
          controller: _usernameController,
          decoration: AppTheme.inputDecoration("Unique ID (Username)", Icons.person_outline),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkUsername,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Security Verification", style: AppTheme.headingWhite),
        const SizedBox(height: 10),
        Text("Answer the security question you set during registration.", style: AppTheme.subheadingGrey),
        const SizedBox(height: 40),
        Text(
          "Q: $_securityQuestion",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _securityAnswerController,
          decoration: AppTheme.inputDecoration("Your Answer", Icons.key_outlined),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _verifyAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Verify Answer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Reset Password", style: AppTheme.headingWhite),
        const SizedBox(height: 10),
        Text("Set a new password for your account.", style: AppTheme.subheadingGrey),
        const SizedBox(height: 40),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _isObscure,
          decoration: AppTheme.inputDecoration(
            "New Password", 
            Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmObscure,
          decoration: AppTheme.inputDecoration(
            "Confirm New Password", 
            Icons.lock_reset,
            suffix: IconButton(
              icon: Icon(_isConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Reset Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_currentStep == 1) _buildStep1(),
                if (_currentStep == 2) _buildStep2(),
                if (_currentStep == 3) _buildStep3(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
