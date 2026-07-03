import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

class LeaveService {
  static const String databaseId = '6a2c10dc000d5e50f314';
  static const String collectionId = 'leave_requests';

  static Future<models.Document> submitRequest({
    required String userId,
    required String userName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required int approverLevel,
    String? approverId,
  }) async {
    return await AppwriteService.databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'userName': userName,
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
        'status': 'pending',
        'approverLevel': approverLevel,
        if (approverId != null) 'approverId': approverId,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Pending requests at [level]. When [approverId] is given, results are
  /// narrowed to requests routed to that specific admin — requests submitted
  /// before approver-scoping shipped (no `approverId` stored) still show to
  /// anyone at the right level, so older pending requests aren't orphaned.
  static Future<List<models.Document>> getPendingRequests(
    int level, {
    String? approverId,
  }) async {
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.equal('approverLevel', level),
        Query.equal('status', 'pending'),
        Query.orderDesc('createdAt'),
      ],
    );
    if (approverId == null) return result.documents;
    return result.documents.where((doc) {
      final docApproverId = doc.data['approverId'] as String?;
      return docApproverId == null ||
          docApproverId.isEmpty ||
          docApproverId == approverId;
    }).toList();
  }

  static Future<models.DocumentList> getMyRequests(String userId) async {
    return await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('createdAt'),
      ],
    );
  }

  /// [actionById] is the acting admin's own username, checked against the
  /// request's resolved `approverId` (if any). [actionBy] is kept separate
  /// as the human-readable name recorded on the request.
  static Future<void> updateStatus(
    String documentId,
    String status,
    String actionBy, {
    required String actionById,
    String? comment,
  }) async {
    final doc = await AppwriteService.databases.getDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
    final approverId = doc.data['approverId'] as String?;
    if (approverId != null && approverId.isNotEmpty && approverId != actionById) {
      throw Exception('You are not the approver for this request.');
    }

    await AppwriteService.databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: {
        'status': status,
        'actionBy': actionBy,
        'actionTime': DateTime.now().toIso8601String(),
        if (comment != null) 'actionComment': comment,
      },
    );
  }
}


