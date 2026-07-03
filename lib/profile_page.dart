import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

import 'components/user_avatar.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String name;
  final String? profilePictureId;
  const ProfilePage({super.key, required this.username, required this.name, this.profilePictureId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String? _selectedSecurityQuestion;
  final List<String> _securityQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "In what city were you born?",
    "What is your favorite book?",
    "What high school did you attend?"
  ];
  bool _isLoading = false;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', widget.username)],
      );
      if (result.documents.isNotEmpty) {
        final doc = result.documents.first;
        _docId = doc.$id;
        if (mounted) {
          setState(() {
            _selectedSecurityQuestion = doc.data['securityQuestion'] as String?;
          });
        }
      }
    } catch (_) {}
  }

  void _showSecurityQuestionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text("Select a Security Question", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _securityQuestions.length,
                  itemBuilder: (context, index) {
                    final question = _securityQuestions[index];
                    final isSelected = _selectedSecurityQuestion == question;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                      title: Text(question, style: TextStyle(
                        fontSize: 14, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.kGreen : Colors.black87
                      )),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.kGreen) : null,
                      onTap: () {
                        setState(() => _selectedSecurityQuestion = question);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (_docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User document not found. Try re-opening this page.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {};
      
      if (_newPasswordController.text.isNotEmpty) {
        updateData['password'] = AppwriteService.hashPassword(_newPasswordController.text.trim());
      }
      
      if (_selectedSecurityQuestion != null && _securityAnswerController.text.trim().isNotEmpty) {
        updateData['securityQuestion'] = _selectedSecurityQuestion;
        updateData['securityAnswer'] = _securityAnswerController.text.trim();
      }

      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No changes to save.")));
        setState(() => _isLoading = false);
        return;
      }

      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        documentId: _docId!,
        data: updateData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        title: const Text("Profile Settings"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: AppTheme.bottomSheet,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppTheme.sheetHandle,
                    UserAvatar(
                      profilePictureId: widget.profilePictureId,
                      fallbackName: widget.name,
                      radius: 50,
                      backgroundColor: AppTheme.kGreen.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.kGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: AppTheme.sectionTitle.copyWith(fontSize: 22),
                    ),
                    Text(
                      widget.username,
                      style: AppTheme.subheadingGrey.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Security Center",
                      textAlign: TextAlign.center,
                      style: AppTheme.subheadingGrey,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      readOnly: true,
                      decoration: AppTheme.inputDecoration("Username", Icons.person_outline).copyWith(
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: AppTheme.inputDecoration("New Password (Optional)", Icons.lock_outline),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Account Recovery",
                      textAlign: TextAlign.center,
                      style: AppTheme.subheadingGrey,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showSecurityQuestionPicker,
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: AppTheme.inputDecoration(
                            _selectedSecurityQuestion ?? "Select Security Question", 
                            Icons.help_outline,
                          ),
                          style: TextStyle(
                            color: _selectedSecurityQuestion == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _securityAnswerController,
                      decoration: AppTheme.inputDecoration("New Security Answer (Optional)", Icons.key_outlined),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes"),
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
}


