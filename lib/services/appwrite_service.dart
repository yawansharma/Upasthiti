import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';

class AppwriteService {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '6ac4f7a50037e9fe4dfa';

  // ── Centralized IDs ───────────────────────────────────────────────────────
  static const String databaseId = '6ac510390009fba397c7';
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
  static final Account account = Account(client);

  static String getEmailFromUsername(String username) => "$username@upasthiti.local";

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

  // ── Authentication (Appwrite Account API) ─────────────────────────────────
  /// Logs a user in. If they only exist in the legacy DB, migrates them to Appwrite Auth.
  static Future<Map<String, dynamic>> loginWithMigration(String username, String password) async {
    final email = getEmailFromUsername(username);

    try {
      // 1. Try to create an Appwrite Auth session
      await account.createEmailPasswordSession(email: email, password: password);
      
      // If successful, fetch user data from the database for RBAC
      final query = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', username)],
      );

      if (query.documents.isEmpty) {
        throw Exception("User record not found in database.");
      }

      return {'docId': query.documents.first.$id, 'data': query.documents.first.data};
    } on AppwriteException catch (e) {
      // 2. Fallback to legacy database check and AUTO-MIGRATE
      // Usually a 401 means invalid credentials or user doesn't exist
      
      final query = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', username)],
      );

      if (query.documents.isEmpty) {
        throw Exception("Invalid credentials.");
      }

      final doc = query.documents.first;
      final storedPassword = doc.data['password'] as String? ?? '';

      if (!verifyPassword(password, storedPassword)) {
        throw Exception("Invalid credentials.");
      }

      // Password matches legacy DB! Auto-migrate to Appwrite Auth.
      try {
        await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: doc.data['name'] as String? ?? username,
        );
        // Create session now that account exists
        await account.createEmailPasswordSession(email: email, password: password);
      } catch (migrationError) {
        throw Exception("Account migration failed: $migrationError");
      }

      return {'docId': doc.$id, 'data': doc.data};
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// Logout the current user
  static Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (_) {
      // Ignore if no session exists
    }
  }

  // ── Database Maintenance ───────────────────────────────────────────────────
  /// Lazy-cleanup of inactive accounts. Deletes accounts where `lastLogin`
  /// is older than the specified days. Removes both DB record and profile picture.
  static Future<void> cleanupInactiveAccounts({int inactiveDays = 60}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: inactiveDays))
          .toIso8601String();

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
