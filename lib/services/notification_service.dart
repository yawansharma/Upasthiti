import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'appwrite_service.dart';

/// Lightweight in-app notifications, backed by the `notifications` collection
/// (`recipientId`, `fromId`, `fromName`, `type`, `message`, `timestamp`,
/// `isRead`). Recipients are admin usernames, or the literal `dean` for the
/// Dean's inbox.
class NotificationService {
  static String get _db => AppwriteService.databaseId;
  static const String collection = 'notifications';

  /// Resolves who a presence-related notification about an admin should go to:
  /// an L2/L3 escalates to its explicit parent; everyone else escalates to the
  /// Dean.
  static String higherInchargeId({
    required String role,
    required int level,
    String? parentAdminId,
  }) {
    if (role == 'admin' &&
        (level == 2 || level == 3) &&
        parentAdminId != null &&
        parentAdminId.isNotEmpty) {
      return parentAdminId;
    }
    return 'dean';
  }

  static Future<void> create({
    required String recipientId,
    required String fromId,
    required String fromName,
    required String type,
    required String message,
  }) async {
    try {
      await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: collection,
        documentId: ID.unique(),
        data: {
          'recipientId': recipientId,
          'fromId': fromId,
          'fromName': fromName,
          'type': type,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'isRead': false,
        },
      );
    } catch (_) {
      // Advisory — never block the triggering action on a notify failure.
    }
  }

  static Future<int> unreadCount(String recipientId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: collection,
        queries: [
          Query.equal('recipientId', recipientId),
          Query.equal('isRead', false),
          Query.limit(100),
        ],
      );
      return res.total;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<models.Document>> list(String recipientId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: collection,
        queries: [
          Query.equal('recipientId', recipientId),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );
      return res.documents;
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAllRead(String recipientId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: collection,
        queries: [
          Query.equal('recipientId', recipientId),
          Query.equal('isRead', false),
          Query.limit(100),
        ],
      );
      for (final d in res.documents) {
        await AppwriteService.databases.updateDocument(
          databaseId: _db,
          collectionId: collection,
          documentId: d.$id,
          data: {'isRead': true},
        );
      }
    } catch (_) {}
  }
}
