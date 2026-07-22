import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'appwrite_service.dart';
import 'admin_hierarchy_service.dart';

/// Outcome of a "Report presence" attempt.
class PresenceResult {
  final bool ok;
  final String message;
  final String? status; // 'Present' | 'Late' when ok
  const PresenceResult(this.ok, this.message, {this.status});
}

/// Shared logic for the admin presence system:
///  - each admin's own individual geofence, set by the Dean/Office Admin
///    (there is no shared/common boundary — see [boundaryForAdmin])
///  - first-login face registration (see AdminOnboardingPage)
///  - the once-a-day "Report presence" / sign-out flow (`admin_presence_logs`)
///
/// Reuses the same ML face backend and geofence approach as the student flow in
/// [class_detail_page.dart] / [register_page.dart].
class AdminPresenceService {
  static String get _db => AppwriteService.databaseId;

  static const String logsCollection = 'admin_presence_logs';

  /// Presence can only be reported after 05:30 local time.
  static const int presenceStartHour = 5;
  static const int presenceStartMinute = 30;

  static String get _registerFaceEndpoint =>
      '${AppwriteService.mlBackendBase}/register-face';
  static String get _verifyFaceEndpoint =>
      '${AppwriteService.mlBackendBase}/login-face';

  // ── Date helpers ────────────────────────────────────────────────────────
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// True once the local clock has passed today's 05:30 presence window open.
  static bool isPresenceWindowOpen([DateTime? now]) {
    final t = now ?? DateTime.now();
    final open = DateTime(t.year, t.month, t.day, presenceStartHour, presenceStartMinute);
    return !t.isBefore(open);
  }

  // ── Boundary config (set by the Office Admin) ───────────────────────────
  static Map<String, dynamic>? _parseBoundary(dynamic raw) {
    Map<String, dynamic>? map;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }
    if (map == null) return null;
    if (map['lat'] == null || map['lng'] == null || map['radiusMeters'] == null) {
      return null;
    }
    return {
      'lat': (map['lat'] as num).toDouble(),
      'lng': (map['lng'] as num).toDouble(),
      'radiusMeters': (map['radiusMeters'] as num).toDouble(),
    };
  }

  /// Boundary an admin is checked against — strictly per-admin, set
  /// individually by the Dean/Office Admin (usually at creation time). There
  /// is no shared/common fallback: an admin with no boundary set cannot
  /// report presence at all until one is assigned to them specifically.
  static Future<Map<String, dynamic>?> boundaryForAdmin(String adminId) async {
    try {
      final admin = await AdminHierarchyService.findUserByUsername(adminId);
      return _parseBoundary(admin?.data['presenceBoundary']);
    } catch (_) {
      return null;
    }
  }

  /// Sets a specific admin's own presence geofence, overriding the global
  /// config for that admin. Lets the Office Admin pin a location per admin
  /// right after creating their ID. Stored as `presenceBoundary` JSON.
  static Future<void> setAdminBoundary({
    required String adminDocId,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: 'users',
      documentId: adminDocId,
      data: {
        'presenceBoundary': jsonEncode(
            {'lat': lat, 'lng': lng, 'radiusMeters': radiusMeters}),
      },
    );
  }

  /// Marks first-login onboarding complete. Does NOT assign any boundary —
  /// there is no shared default to fall back to. The Dean/Office Admin must
  /// have already set this specific admin's location (normally done at
  /// creation time via [setAdminBoundary]); if they haven't, the admin stays
  /// unable to report presence until one is set for their account.
  static Future<Map<String, dynamic>?> pinBoundaryAndCompleteOnboarding(
    String adminDocId,
  ) async {
    Map<String, dynamic>? existing;
    try {
      final doc = await AppwriteService.databases.getDocument(
        databaseId: _db,
        collectionId: 'users',
        documentId: adminDocId,
      );
      existing = _parseBoundary(doc.data['presenceBoundary']);
    } catch (_) {}

    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: 'users',
      documentId: adminDocId,
      data: {'presenceOnboardedAt': DateTime.now().toIso8601String()},
    );
    return existing;
  }

  // ── Geofence check (mirrors class_detail_page._checkGeofence) ───────────
  /// True if within [boundary]. A null boundary is treated as "pass" so admins
  /// aren't blocked before the Office Admin has configured one.
  static Future<bool> isInsideBoundary(Map<String, dynamic>? boundary) async {
    if (boundary == null) return true;

    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      (boundary['lat'] as num).toDouble(),
      (boundary['lng'] as num).toDouble(),
    );
    return distance <= (boundary['radiusMeters'] as num).toDouble();
  }

  // ── Camera capture (front cam mobile / camera.html on Windows) ──────────
  static Future<File?> capturePhoto(BuildContext context) async {
    if (!Platform.isWindows) {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 90,
      );
      return picked != null ? File(picked.path) : null;
    }
    // Windows fallback: open the camera helper, then let the user pick the file.
    try {
      final htmlPath =
          '${Directory.current.path}\\windows\\runner\\resources\\camera.html';
      await launchUrl(Uri.file(htmlPath), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Camera helper opened. Capture, save the photo, then select it.'),
      ));
    }
    final XFile? picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  // ── Face backend (same 3-attempt cold-start retry as student flow) ──────
  /// Registers [username]'s face. Returns null on success, else an error string.
  static Future<String?> registerFace(String username, File photo) =>
      _faceRequest(_registerFaceEndpoint, username, photo, verify: false);

  /// Verifies [username]'s face. Returns null on success, else an error string.
  static Future<String?> verifyFace(String username, File photo) =>
      _faceRequest(_verifyFaceEndpoint, username, photo, verify: true);

  static Future<String?> _faceRequest(
    String endpoint,
    String username,
    File photo, {
    required bool verify,
  }) async {
    const maxAttempts = 3;
    const initialDelay = Duration(seconds: 3);
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(endpoint));
        request.fields['username'] = username;
        request.files
            .add(await http.MultipartFile.fromPath('image', photo.path));
        final streamed =
            await request.send().timeout(const Duration(seconds: 60));
        final body = await streamed.stream.bytesToString();

        if (streamed.statusCode >= 500 && attempt < maxAttempts) {
          await Future.delayed(initialDelay * attempt);
          continue;
        }
        if (!verify && streamed.statusCode == 200) return null;
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          if (verify) {
            if (decoded['verified'] == true) return null;
            return decoded['error'] as String? ?? 'Face not recognised.';
          }
          return decoded['error'] as String? ?? 'Face registration failed.';
        } catch (_) {
          return verify
              ? 'Face verification failed (status ${streamed.statusCode}).'
              : 'Face registration failed (status ${streamed.statusCode}).';
        }
      } catch (_) {
        if (attempt < maxAttempts) {
          await Future.delayed(initialDelay * attempt);
          continue;
        }
        return 'Could not reach the server. Please check your connection.';
      }
    }
    return verify
        ? 'Face verification failed after $maxAttempts attempts.'
        : 'Face registration failed after $maxAttempts attempts.';
  }

  /// Uploads [photo] to the profile bucket. Returns the file id, or null.
  static Future<String?> uploadProfilePhoto(String username, File photo) async {
    try {
      final bytes = await photo.readAsBytes();
      final ext = photo.path.split('.').last.toLowerCase();
      final uploaded = await AppwriteService.storage.createFile(
        bucketId: AppwriteService.profileBucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename:
              'admin_${username}_${DateTime.now().millisecondsSinceEpoch}.$ext',
        ),
      );
      return uploaded.$id;
    } catch (_) {
      return null;
    }
  }

  // ── Daily presence log ──────────────────────────────────────────────────
  static Future<models.Document?> fetchTodayLog(String adminId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: logsCollection,
        queries: [
          Query.equal('adminId', adminId),
          Query.equal('date', dateKey(DateTime.now())),
          Query.limit(1),
        ],
      );
      return res.documents.isEmpty ? null : res.documents.first;
    } catch (_) {
      return null;
    }
  }

  /// Records the login for today (creates the daily row with `loginTime` if it
  /// doesn't exist yet). Safe to call on every home-page load.
  static Future<void> recordLogin({
    required String adminId,
    required String adminName,
    required String role,
    required int level,
    required String department,
    String? parentAdminId,
  }) async {
    try {
      if (await fetchTodayLog(adminId) != null) return;
      await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: logsCollection,
        documentId: ID.unique(),
        data: {
          'adminId': adminId,
          'adminName': adminName,
          'role': role,
          'level': level,
          'department': department,
          'parentAdminId': parentAdminId ?? '',
          'date': dateKey(DateTime.now()),
          'loginTime': DateTime.now().toIso8601String(),
          'isWithinGeofence': false,
          'faceVerified': false,
          'status': '',
          'deadline': '',
        },
      );
    } catch (_) {
      // Advisory logging — never block the login flow.
    }
  }

  static bool _isAfterDeadline(DateTime now, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return now.isAfter(DateTime(now.year, now.month, now.day, h, m));
  }

  /// Writes today's presence (creating or updating the daily row) after the
  /// caller has confirmed geofence + face. Returns the computed status.
  /// For an L3 with a `presenceDeadline`, a late report is flagged `Late`.
  static Future<String> savePresence({
    required String adminId,
    required String adminName,
    required String role,
    required int level,
    required String department,
    String? parentAdminId,
    required bool insideGeofence,
    required bool faceVerified,
  }) async {
    final now = DateTime.now();
    String status = 'Present';
    String deadline = '';
    if (level == 3) {
      final admin = await AdminHierarchyService.findUserByUsername(adminId);
      deadline = (admin?.data['presenceDeadline'] as String?) ?? '';
      if (deadline.isNotEmpty && _isAfterDeadline(now, deadline)) {
        status = 'Late';
      }
    }

    final existing = await fetchTodayLog(adminId);
    final data = <String, dynamic>{
      'adminId': adminId,
      'adminName': adminName,
      'role': role,
      'level': level,
      'department': department,
      'parentAdminId': parentAdminId ?? '',
      'date': dateKey(now),
      'presenceTime': now.toIso8601String(),
      'isWithinGeofence': insideGeofence,
      'faceVerified': faceVerified,
      'status': status,
      'deadline': deadline,
    };
    if (existing != null) {
      await AppwriteService.databases.updateDocument(
        databaseId: _db,
        collectionId: logsCollection,
        documentId: existing.$id,
        data: data,
      );
    } else {
      data['loginTime'] = now.toIso8601String();
      await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: logsCollection,
        documentId: ID.unique(),
        data: data,
      );
    }
    return status;
  }

  /// Records the sign-out time on today's row.
  static Future<void> signOut(String adminId) async {
    final existing = await fetchTodayLog(adminId);
    if (existing == null) return;
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: logsCollection,
      documentId: existing.$id,
      data: {'signOutTime': DateTime.now().toIso8601String()},
    );
  }
}
