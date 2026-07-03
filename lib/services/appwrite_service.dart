import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';

class AppwriteService {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6a2c0bd800121a164e77';

  // ── Centralized IDs ───────────────────────────────────────────────────────
  static const String databaseId = '6a2c10dc000d5e50f314';
  static const String profileBucketId = '6a2c12a500260c940843';
  static const String attendancePhotosBucket = 'attendance_photos';
  static const String communityFilesBucket = 'community_files';

  // ── ML Backend ────────────────────────────────────────────────────────────
  static const String mlBackendBase =
      'https://pasteshub404-navikarana-backend.hf.space';

  static final Client client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId);

  static final Databases databases = Databases(client);
  static final Storage storage = Storage(client);
  static final Realtime realtime = Realtime(client);

  // ── Password Hashing ──────────────────────────────────────────────────────
  /// Hash a plaintext password using SHA-256.
  /// Returns a hex-encoded hash string.
  static String hashPassword(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a string looks like it's already a SHA-256 hash
  /// (64 hex characters). Used for dual-mode migration.
  static bool isHashed(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }

  /// Verify a password against a stored value.
  /// Supports dual-mode: works with both plaintext (legacy) and hashed passwords.
  /// Returns true if the password matches.
  static bool verifyPassword(String inputPlaintext, String storedValue) {
    if (isHashed(storedValue)) {
      // Stored value is already hashed — compare hashes
      return hashPassword(inputPlaintext) == storedValue;
    } else {
      // Stored value is plaintext (legacy) — direct comparison
      return inputPlaintext == storedValue;
    }
  }

  // ── Database Maintenance ───────────────────────────────────────────────────
  /// Lazy-cleanup of inactive accounts. Deletes accounts where `lastLogin`
  /// is older than the specified days. Removes both DB record and profile picture.
  static Future<void> cleanupInactiveAccounts({int inactiveDays = 60}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: inactiveDays)).toIso8601String();
      
      // Query users where lastLogin is less than cutoffDate
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: 'users',
        queries: [
          Query.lessThan('lastLogin', cutoffDate),
          Query.limit(50), // Batch size to prevent timeouts
        ],
      );

      for (var doc in response.documents) {
        final data = doc.data;
        
        // 1. Delete profile picture if it exists
        final profilePictureId = data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          try {
            await storage.deleteFile(
              bucketId: profileBucketId,
              fileId: profilePictureId,
            );
          } catch (e) {
            // Ignore storage errors (file might already be deleted)
          }
        }

        // 2. Delete database record
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: 'users',
          documentId: doc.$id,
        );
      }
    } catch (e) {
      // Fail silently in background to not disrupt admin login flow
    }
  }
}
