import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/appwrite_service.dart';
import 'services/admin_presence_service.dart';

/// First-login setup shown to every non-Dean admin exactly once. Captures a
/// photo, registers the face with the ML backend, stores the profile picture,
/// and pins the admin to the Office Admin's presence boundary. On completion it
/// replaces itself with the admin's normal [destination] home page.
class AdminOnboardingPage extends StatefulWidget {
  final String adminDocId; // users collection $id
  final String username; // adminId / login username
  final String adminName;
  final Widget destination;
  final Color accent;

  const AdminOnboardingPage({
    super.key,
    required this.adminDocId,
    required this.username,
    required this.adminName,
    required this.destination,
    this.accent = const Color(0xFF6A8A73),
  });

  @override
  State<AdminOnboardingPage> createState() => _AdminOnboardingPageState();
}

class _AdminOnboardingPageState extends State<AdminOnboardingPage> {
  File? _photo;
  bool _busy = false;
  String? _boundaryNote;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _capture() async {
    final photo = await AdminPresenceService.capturePhoto(context);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _complete() async {
    if (_photo == null) {
      _snack('Please take your photo first.');
      return;
    }
    setState(() => _busy = true);
    final progress = ValueNotifier<String>('Registering your face…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ValueListenableBuilder<String>(
          valueListenable: progress,
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

    try {
      // 1. Register face on the ML backend.
      final faceError =
          await AdminPresenceService.registerFace(widget.username, _photo!);
      if (faceError != null) {
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        _snack('Face registration failed: $faceError');
        setState(() => _busy = false);
        return;
      }

      // 2. Upload the profile picture and store its id on the account.
      progress.value = 'Saving your profile…';
      final picId =
          await AdminPresenceService.uploadProfilePhoto(widget.username, _photo!);
      final updateData = <String, dynamic>{};
      if (picId != null) updateData['profilePictureId'] = picId;
      if (updateData.isNotEmpty) {
        await AppwriteService.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: 'users',
          documentId: widget.adminDocId,
          data: updateData,
        );
      }

      // 3. Pin the Office Admin's boundary + mark onboarding complete.
      progress.value = 'Setting up your work location…';
      final boundary = await AdminPresenceService
          .pinBoundaryAndCompleteOnboarding(widget.adminDocId);
      if (boundary == null) {
        _boundaryNote =
            'No campus boundary is set yet — your presence location will apply once the Office Admin configures it.';
      }

      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop(); // progress
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.destination),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      _snack('Setup failed: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Scaffold(
      backgroundColor: const Color(0xFF10121C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Welcome, ${widget.adminName.split(' ').first}',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'First-time setup — this happens only once. We\'ll register your '
                'face for daily verification and pin you to your work location.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: _busy ? null : _capture,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.6), width: 2),
                      image: _photo != null
                          ? DecorationImage(
                              image: FileImage(_photo!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: accent, size: 44),
                              const SizedBox(height: 10),
                              const Text('Tap to take photo',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _capture,
                    icon: Icon(Icons.refresh, color: accent, size: 18),
                    label: Text('Retake',
                        style: TextStyle(color: accent, fontSize: 13)),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_busy || _photo == null) ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Complete Setup',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (_boundaryNote != null) ...[
                const SizedBox(height: 16),
                Text(_boundaryNote!,
                    style: TextStyle(
                        color: Colors.orange.shade200, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
