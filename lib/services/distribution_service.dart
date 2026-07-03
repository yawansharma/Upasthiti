// SETUP: Create these collections in Appwrite Console (database 6a2c10dc000d5e50f314)
//
// distribution_events:
//   title(String), description(String), scheduledDate(String), location(String),
//   status(String: draft|active|closed), createdBy(String),
//   issuedCount(Integer), totalRecipients(Integer), createdAt(String)
//
// event_recipients:
//   eventId(String), userId(String), userName(String),
//   status(String: pending|issued|acknowledged|revoked),
//   issuedAt(String?), issuedBy(String?), acknowledgedAt(String?), packageNote(String?)
//
// event_admin_assignments:
//   eventId(String), adminId(String), adminName(String),
//   assignedBy(String), assignedAt(String), isActive(Boolean)
//
// distribution_scan_logs:
//   eventId(String), scannedUserId(String), scannedBy(String),
//   action(String: issued|duplicate_attempt|ineligible|revoked|manual_override),
//   timestamp(String)

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

enum ScanStatus {
  success,
  alreadyIssued,
  notInList,
  eventNotActive,
  notAuthorized,
  revoked,
}

class ScanResult {
  final ScanStatus status;
  final String? userName;
  final String? issuedAt;
  final String? issuedBy;
  const ScanResult({
    required this.status,
    required this.userName,
    this.issuedAt,
    this.issuedBy,
  });
}

class DistributionService {
  static const String _db = '6a2c10dc000d5e50f314';
  static const String _events = 'distribution_events';
  static const String _recipients = 'event_recipients';
  static const String _assignments = 'event_admin_assignments';
  static const String _scanLogs = 'distribution_scan_logs';

  // ---------------------------------------------------------------------------
  // Dean: Event CRUD
  // ---------------------------------------------------------------------------

  static Future<models.Document> createEvent({
    required String title,
    required String description,
    required String scheduledDate,
    required String location,
    required String createdBy,
  }) {
    return AppwriteService.databases.createDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: ID.unique(),
      data: {
        'title': title,
        'description': description,
        'scheduledDate': scheduledDate,
        'location': location,
        'status': 'draft',
        'createdBy': createdBy,
        'issuedCount': 0,
        'totalRecipients': 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<models.DocumentList> getEvents() {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _events,
      queries: [Query.orderDesc('createdAt'), Query.limit(100)],
    );
  }

  static Future<models.DocumentList> getEventsByCreator(String createdBy) {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _events,
      queries: [
        Query.equal('createdBy', createdBy),
        Query.orderDesc('createdAt'),
        Query.limit(100),
      ],
    );
  }

  static Future<models.Document> getEventById(String eventId) {
    return AppwriteService.databases.getDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
    );
  }

  /// Thrown when a caller who is neither the event's creator nor the Dean
  /// tries to manage it.
  static Future<void> _requireOwner({
    required String eventId,
    required String callerId,
    required bool isDean,
  }) async {
    if (isDean) return;
    final event = await getEventById(eventId);
    if (event.data['createdBy'] != callerId) {
      throw Exception('Only the event creator or the Dean can do this.');
    }
  }

  static Future<void> activateEvent(
    String eventId, {
    required String callerId,
    bool isDean = false,
  }) async {
    await _requireOwner(eventId: eventId, callerId: callerId, isDean: isDean);
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
      data: {'status': 'active'},
    );
  }

  static Future<void> closeEvent(
    String eventId, {
    required String callerId,
    bool isDean = false,
  }) async {
    await _requireOwner(eventId: eventId, callerId: callerId, isDean: isDean);
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
      data: {'status': 'closed'},
    );
  }

  // ---------------------------------------------------------------------------
  // Dean: Recipients
  // ---------------------------------------------------------------------------

  static Future<void> addRecipient({
    required String eventId,
    required String userId,
    required String userName,
    required String callerId,
    bool isDean = false,
    String? packageNote,
  }) async {
    await _requireOwner(eventId: eventId, callerId: callerId, isDean: isDean);
    final existing = await AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _recipients,
      queries: [Query.equal('eventId', eventId), Query.equal('userId', userId)],
    );
    if (existing.documents.isNotEmpty) return;

    await AppwriteService.databases.createDocument(
      databaseId: _db,
      collectionId: _recipients,
      documentId: ID.unique(),
      data: {
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'status': 'pending',
        if (packageNote != null) 'packageNote': packageNote,
      },
    );

    final event = await getEventById(eventId);
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
      data: {
        'totalRecipients': (event.data['totalRecipients'] as int? ?? 0) + 1,
      },
    );
  }

  static Future<models.DocumentList> getRecipients(String eventId) {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _recipients,
      queries: [Query.equal('eventId', eventId), Query.limit(500)],
    );
  }

  static Future<void> removeRecipient(
    String recipientDocId,
    String eventId, {
    required String callerId,
    bool isDean = false,
  }) async {
    await _requireOwner(eventId: eventId, callerId: callerId, isDean: isDean);
    await AppwriteService.databases.deleteDocument(
      databaseId: _db,
      collectionId: _recipients,
      documentId: recipientDocId,
    );
    final event = await getEventById(eventId);
    final current = (event.data['totalRecipients'] as int? ?? 1);
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
      data: {'totalRecipients': current > 0 ? current - 1 : 0},
    );
  }

  // ---------------------------------------------------------------------------
  // Dean: Admin Assignments
  // ---------------------------------------------------------------------------

  static Future<void> assignAdmin({
    required String eventId,
    required String adminId,
    required String adminName,
    required String assignedBy,
    bool isDean = false,
  }) async {
    await _requireOwner(
      eventId: eventId,
      callerId: assignedBy,
      isDean: isDean,
    );
    final existing = await AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _assignments,
      queries: [
        Query.equal('eventId', eventId),
        Query.equal('adminId', adminId),
      ],
    );
    if (existing.documents.isNotEmpty) {
      await AppwriteService.databases.updateDocument(
        databaseId: _db,
        collectionId: _assignments,
        documentId: existing.documents.first.$id,
        data: {'isActive': true},
      );
      return;
    }
    await AppwriteService.databases.createDocument(
      databaseId: _db,
      collectionId: _assignments,
      documentId: ID.unique(),
      data: {
        'eventId': eventId,
        'adminId': adminId,
        'adminName': adminName,
        'assignedBy': assignedBy,
        'assignedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      },
    );
  }

  static Future<void> revokeAdmin(
    String assignmentDocId, {
    required String callerId,
    bool isDean = false,
  }) async {
    final assignment = await AppwriteService.databases.getDocument(
      databaseId: _db,
      collectionId: _assignments,
      documentId: assignmentDocId,
    );
    await _requireOwner(
      eventId: assignment.data['eventId'] as String,
      callerId: callerId,
      isDean: isDean,
    );
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _assignments,
      documentId: assignmentDocId,
      data: {'isActive': false},
    );
  }

  static Future<models.DocumentList> getAssignments(String eventId) {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _assignments,
      queries: [Query.equal('eventId', eventId), Query.equal('isActive', true)],
    );
  }

  // ---------------------------------------------------------------------------
  // Admin: Get assigned active events
  // ---------------------------------------------------------------------------

  static Future<List<models.Document>> getAdminActiveEvents(
    String adminId,
  ) async {
    final assignments = await AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _assignments,
      queries: [Query.equal('adminId', adminId), Query.equal('isActive', true)],
    );
    if (assignments.documents.isEmpty) return [];

    final result = <models.Document>[];
    for (final a in assignments.documents) {
      try {
        final event = await getEventById(a.data['eventId'] as String);
        if (event.data['status'] == 'active') result.add(event);
      } catch (_) {}
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Admin: Process QR scan
  // ---------------------------------------------------------------------------

  static Future<ScanResult> processQrScan({
    required String eventId,
    required String scannedUserId,
    required String adminId,
  }) async {
    final event = await getEventById(eventId);
    if (event.data['status'] != 'active') {
      return const ScanResult(
        status: ScanStatus.eventNotActive,
        userName: null,
      );
    }

    final adminCheck = await AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _assignments,
      queries: [
        Query.equal('eventId', eventId),
        Query.equal('adminId', adminId),
        Query.equal('isActive', true),
      ],
    );
    if (adminCheck.documents.isEmpty) {
      return const ScanResult(status: ScanStatus.notAuthorized, userName: null);
    }

    final recipientQuery = await AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _recipients,
      queries: [
        Query.equal('eventId', eventId),
        Query.equal('userId', scannedUserId),
      ],
    );

    if (recipientQuery.documents.isEmpty) {
      await _writeScanLog(eventId, scannedUserId, adminId, 'ineligible');
      return const ScanResult(status: ScanStatus.notInList, userName: null);
    }

    final recipientDoc = recipientQuery.documents.first;
    final status = recipientDoc.data['status'] as String;
    final userName = recipientDoc.data['userName'] as String? ?? scannedUserId;

    if (status == 'revoked') {
      await _writeScanLog(eventId, scannedUserId, adminId, 'revoked');
      return ScanResult(status: ScanStatus.revoked, userName: userName);
    }

    if (status == 'issued' || status == 'acknowledged') {
      await _writeScanLog(eventId, scannedUserId, adminId, 'duplicate_attempt');
      return ScanResult(
        status: ScanStatus.alreadyIssued,
        userName: userName,
        issuedAt: recipientDoc.data['issuedAt'] as String?,
        issuedBy: recipientDoc.data['issuedBy'] as String?,
      );
    }

    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _recipients,
      documentId: recipientDoc.$id,
      data: {
        'status': 'issued',
        'issuedAt': DateTime.now().toIso8601String(),
        'issuedBy': adminId,
      },
    );
    await AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _events,
      documentId: eventId,
      data: {'issuedCount': (event.data['issuedCount'] as int? ?? 0) + 1},
    );
    await _writeScanLog(eventId, scannedUserId, adminId, 'issued');
    return ScanResult(status: ScanStatus.success, userName: userName);
  }

  static Future<void> _writeScanLog(
    String eventId,
    String userId,
    String adminId,
    String action,
  ) {
    return AppwriteService.databases.createDocument(
      databaseId: _db,
      collectionId: _scanLogs,
      documentId: ID.unique(),
      data: {
        'eventId': eventId,
        'scannedUserId': userId,
        'scannedBy': adminId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // User: My events + acknowledgement
  // ---------------------------------------------------------------------------

  static Future<models.DocumentList> getMyRecipientEntries(String userId) {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _recipients,
      queries: [Query.equal('userId', userId), Query.orderDesc('\$createdAt')],
    );
  }

  static Future<void> acknowledgeReceipt(String recipientDocId) {
    return AppwriteService.databases.updateDocument(
      databaseId: _db,
      collectionId: _recipients,
      documentId: recipientDocId,
      data: {
        'status': 'acknowledged',
        'acknowledgedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Audit logs (Dean view)
  // ---------------------------------------------------------------------------

  static Future<models.DocumentList> getScanLogs(String eventId) {
    return AppwriteService.databases.listDocuments(
      databaseId: _db,
      collectionId: _scanLogs,
      queries: [
        Query.equal('eventId', eventId),
        Query.orderDesc('timestamp'),
        Query.limit(200),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QR encode/decode
  // ---------------------------------------------------------------------------

  static String encodeQr(String username) =>
      jsonEncode({'u': username, 'v': 1});

  static String? decodeQr(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['u'] as String?;
    } catch (_) {
      return null;
    }
  }
}


