import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';

class UserAvatar extends StatefulWidget {
  final String? profilePictureId;
  final String fallbackName;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  const UserAvatar({
    super.key,
    this.profilePictureId,
    this.fallbackName = '?',
    this.radius = 20,
    this.backgroundColor = const Color(0xFFE8F5E9),
    this.foregroundColor = const Color(0xFF6A8A73),
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profilePictureId != widget.profilePictureId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.profilePictureId == null || widget.profilePictureId!.isEmpty) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _hasError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final bytes = await AppwriteService.storage.getFileView(
        bucketId: AppwriteService.profileBucketId,
        fileId: widget.profilePictureId!,
      );
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("UserAvatar error loading profile picture '${widget.profilePictureId}': $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes != null && !_hasError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(_imageBytes!),
        backgroundColor: widget.backgroundColor,
      );
    }

    final initial = widget.fallbackName.isNotEmpty ? widget.fallbackName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      child: _isLoading
          ? SizedBox(
              width: widget.radius,
              height: widget.radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.foregroundColor,
              ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: widget.foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * 0.9,
              ),
            ),
    );
  }
}


