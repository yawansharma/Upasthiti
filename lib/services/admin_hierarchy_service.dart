import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

/// Assignment metadata is stored in the class [boundary] JSON (always writable)
/// and mirrored on user docs when those attributes exist in Appwrite.
class ClassAssignments {
  final String? headAdminId;
  final String? headAdminName;
  final String? supervisorId;
  final String? supervisorName;

  const ClassAssignments({
    this.headAdminId,
    this.headAdminName,
    this.supervisorId,
    this.supervisorName,
  });

  bool get hasSupervisor => supervisorId != null && supervisorId!.isNotEmpty;
  bool get hasHead => headAdminId != null && headAdminId!.isNotEmpty;
}

class AdminHierarchyService {
  static const String databaseId = '6a2c10dc000d5e50f314';
  static const String usersCollection = 'users';
  static const String classesCollection = 'classes';

  static const _assignmentKeys = [
    'headAdminId',
    'headAdminName',
    'supervisorId',
    'supervisorName',
  ];

  static Map<String, dynamic> parseBoundaryRaw(dynamic boundary) {
    if (boundary == null) return {};
    if (boundary is String && boundary.isNotEmpty) {
      try {
        final decoded = jsonDecode(boundary);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      return {};
    }
    if (boundary is Map) return Map<String, dynamic>.from(boundary);
    return {};
  }

  static ClassAssignments readAssignments(Map<String, dynamic> classData) {
    String? headId = classData['headAdminId'] as String?;
    String? headName = classData['headAdminName'] as String?;
    String? supId = classData['supervisorId'] as String?;
    String? supName = classData['supervisorName'] as String?;

    final boundary = parseBoundaryRaw(classData['boundary']);
    headId ??= boundary['headAdminId'] as String?;
    headName ??= boundary['headAdminName'] as String?;
    supId ??= boundary['supervisorId'] as String?;
    supName ??= boundary['supervisorName'] as String?;

    return ClassAssignments(
      headAdminId: headId?.isNotEmpty == true ? headId : null,
      headAdminName: headName?.isNotEmpty == true ? headName : null,
      supervisorId: supId?.isNotEmpty == true ? supId : null,
      supervisorName: supName?.isNotEmpty == true ? supName : null,
    );
  }

  static Map<String, dynamic> geoFromBoundary(dynamic boundary) {
    final raw = parseBoundaryRaw(boundary);
    final geo = Map<String, dynamic>.from(raw);
    for (final key in _assignmentKeys) {
      geo.remove(key);
    }
    return geo;
  }

  static String encodeBoundaryWithAssignments(
    Map<String, dynamic> geo,
    ClassAssignments assignments,
  ) {
    final map = Map<String, dynamic>.from(geo);
    for (final key in _assignmentKeys) {
      map.remove(key);
    }
    if (assignments.headAdminId != null) {
      map['headAdminId'] = assignments.headAdminId;
    }
    if (assignments.headAdminName != null) {
      map['headAdminName'] = assignments.headAdminName;
    }
    if (assignments.supervisorId != null) {
      map['supervisorId'] = assignments.supervisorId;
    }
    if (assignments.supervisorName != null) {
      map['supervisorName'] = assignments.supervisorName;
    }
    return jsonEncode(map);
  }

  static Future<List<models.Document>> listAdminsByLevel(
    int level, {
    String? department,
  }) async {
    final queries = <String>[
      Query.equal('role', 'admin'),
      Query.equal('level', level),
      if (department != null && department.isNotEmpty)
        Query.equal('department', department),
      Query.limit(100),
    ];
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: queries,
    );
    return result.documents
        .where((d) => d.data['status'] != 'disabled')
        .toList();
  }

  static Future<models.Document?> findUserByUsername(String username) async {
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: [Query.equal('username', username), Query.limit(1)],
    );
    if (result.documents.isEmpty) return null;
    return result.documents.first;
  }

  static Future<List<models.Document>> _listAllClasses({
    int limit = 200,
  }) async {
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: classesCollection,
      queries: [Query.limit(limit)],
    );
    return result.documents;
  }

  static Future<List<models.Document>> listL3UnderSupervisor(
    String supervisorId,
  ) async {
    final found = <String, models.Document>{};

    final l3Admins = await listAdminsByLevel(3);
    for (final l3 in l3Admins) {
      final username = l3.data['username'] as String? ?? '';
      if (username.isEmpty || found.containsKey(username)) continue;

      final managed = l3.data['managedClasses'] as List<dynamic>? ?? [];
      for (final classId in managed) {
        try {
          final classDoc = await AppwriteService.databases.getDocument(
            databaseId: databaseId,
            collectionId: classesCollection,
            documentId: classId.toString(),
          );
          if (readAssignments(classDoc.data).supervisorId == supervisorId) {
            found[username] = l3;
            break;
          }
        } catch (_) {}
      }
    }

    for (final classDoc in await _listAllClasses()) {
      final a = readAssignments(classDoc.data);
      if (a.supervisorId == supervisorId && a.headAdminId != null) {
        final l3 = await findUserByUsername(a.headAdminId!);
        if (l3 != null) {
          final u = l3.data['username'] as String? ?? '';
          if (u.isNotEmpty) found[u] = l3;
        }
      }
    }

    return found.values.toList();
  }

  static Future<({String? id, String? name})> resolveReportingL1(
    String l2AdminId,
  ) async {
    for (final classDoc in await _listAllClasses()) {
      final a = readAssignments(classDoc.data);
      if (a.supervisorId == l2AdminId) {
        final l1Id = classDoc.data['createdBy'] as String?;
        if (l1Id != null && l1Id.isNotEmpty) {
          final l1 = await findUserByUsername(l1Id);
          return (id: l1Id, name: l1 != null ? displayName(l1) : l1Id);
        }
      }
    }

    return (id: null, name: null);
  }

  static Future<List<models.Document>> fetchClassesForAdmin({
    required String adminId,
    required int adminLevel,
  }) async {
    if (adminLevel == 1) {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: databaseId,
        collectionId: classesCollection,
        queries: [Query.equal('createdBy', adminId), Query.limit(100)],
      );
      return result.documents;
    }

    if (adminLevel == 3) {
      final seen = <String>{};
      final docs = <models.Document>[];

      try {
        final byHead = await AppwriteService.databases.listDocuments(
          databaseId: databaseId,
          collectionId: classesCollection,
          queries: [Query.equal('headAdminId', adminId), Query.limit(100)],
        );
        for (final d in byHead.documents) {
          if (seen.add(d.$id)) docs.add(d);
        }
      } catch (_) {}

      final user = await findUserByUsername(adminId);
      final managed = user?.data['managedClasses'] as List<dynamic>? ?? [];
      for (final classId in managed) {
        if (classId.toString().isEmpty || !seen.add(classId.toString())) {
          continue;
        }
        try {
          docs.add(
            await AppwriteService.databases.getDocument(
              databaseId: databaseId,
              collectionId: classesCollection,
              documentId: classId.toString(),
            ),
          );
        } catch (_) {}
      }

      for (final classDoc in await _listAllClasses()) {
        if (!seen.add(classDoc.$id)) continue;
        if (readAssignments(classDoc.data).headAdminId == adminId) {
          docs.add(classDoc);
        }
      }
      return docs;
    }

    if (adminLevel == 2) {
      final seen = <String>{};
      final docs = <models.Document>[];

      try {
        final bySupervisor = await AppwriteService.databases.listDocuments(
          databaseId: databaseId,
          collectionId: classesCollection,
          queries: [Query.equal('supervisorId', adminId), Query.limit(100)],
        );
        for (final d in bySupervisor.documents) {
          if (seen.add(d.$id)) docs.add(d);
        }
      } catch (_) {}

      for (final classDoc in await _listAllClasses()) {
        if (!seen.add(classDoc.$id)) continue;
        if (readAssignments(classDoc.data).supervisorId == adminId) {
          docs.add(classDoc);
        }
      }

      final l3s = await listL3UnderSupervisor(adminId);
      for (final l3 in l3s) {
        final headId = l3.data['username'] as String? ?? '';
        if (headId.isEmpty) continue;
        try {
          final byHead = await AppwriteService.databases.listDocuments(
            databaseId: databaseId,
            collectionId: classesCollection,
            queries: [Query.equal('headAdminId', headId), Query.limit(100)],
          );
          for (final d in byHead.documents) {
            if (seen.add(d.$id)) docs.add(d);
          }
        } catch (_) {}
      }
      return docs;
    }

    return [];
  }

  /// Classes where [username] is currently the head admin (L3) or
  /// supervisor (L2). Used to block suspending/deleting an admin who still
  /// owns classes, so they don't silently orphan.
  static Future<List<models.Document>> findOwnedClasses(
    String username,
  ) async {
    final found = <String, models.Document>{};

    final byHead = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: classesCollection,
      queries: [Query.equal('headAdminId', username), Query.limit(200)],
    );
    for (final d in byHead.documents) {
      found[d.$id] = d;
    }

    final bySupervisor = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: classesCollection,
      queries: [Query.equal('supervisorId', username), Query.limit(200)],
    );
    for (final d in bySupervisor.documents) {
      found[d.$id] = d;
    }

    return found.values.toList();
  }

  static Future<void> _removeManagedClass(
    String l3Username,
    String classDocId,
  ) async {
    final l3 = await findUserByUsername(l3Username);
    if (l3 == null) return;
    final managed = List<String>.from(
      (l3.data['managedClasses'] as List<dynamic>? ?? []).map(
        (e) => e.toString(),
      ),
    );
    if (!managed.contains(classDocId)) return;
    managed.remove(classDocId);
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollection,
        documentId: l3.$id,
        data: {'managedClasses': managed},
      );
    } catch (_) {}
  }

  static Future<bool> patchClassAssignments({
    required String classDocId,
    required ClassAssignments assignments,
    bool isDean = false,
  }) async {
    if (!assignments.hasHead && !assignments.hasSupervisor) return true;
    try {
      final docData = <String, dynamic>{
        if (assignments.headAdminId != null)
          'headAdminId': assignments.headAdminId,
        if (assignments.headAdminName != null)
          'headAdminName': assignments.headAdminName,
        if (assignments.supervisorId != null)
          'supervisorId': assignments.supervisorId,
        if (assignments.supervisorName != null)
          'supervisorName': assignments.supervisorName,
      };
      if (isDean) {
        docData['actingAs'] = 'dean';
      }
      await AppwriteService.databases.updateDocument(
        databaseId: databaseId,
        collectionId: classesCollection,
        documentId: classDocId,
        data: docData,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> linkClassStaff({
    required String classDocId,
    required String l1AdminId,
    required ClassAssignments assignments,
  }) async {
    final headAdminId = assignments.headAdminId;

    if (headAdminId != null && headAdminId.isNotEmpty) {
      final l3 = await findUserByUsername(headAdminId);
      if (l3 != null) {
        final managed = List<String>.from(
          (l3.data['managedClasses'] as List<dynamic>? ?? []).map(
            (e) => e.toString(),
          ),
        );
        if (!managed.contains(classDocId)) managed.add(classDocId);

        try {
          await AppwriteService.databases.updateDocument(
            databaseId: databaseId,
            collectionId: usersCollection,
            documentId: l3.$id,
            data: {'managedClasses': managed},
          );
        } catch (_) {}
      }
    }
  }

  /// Persists L2/L3 assignments on boundary JSON + user links.
  static Future<void> persistClassAssignments({
    required String classDocId,
    required Map<String, dynamic> classData,
    required String l1AdminId,
    String? headAdminId,
    String? headAdminName,
    String? supervisorId,
    String? supervisorName,
    ClassAssignments? previous,
    bool isDean = false,
  }) async {
    final prev = previous ?? readAssignments(classData);
    final next = ClassAssignments(
      headAdminId: headAdminId?.isNotEmpty == true ? headAdminId : null,
      headAdminName: headAdminName?.isNotEmpty == true ? headAdminName : null,
      supervisorId: supervisorId?.isNotEmpty == true ? supervisorId : null,
      supervisorName: supervisorName?.isNotEmpty == true
          ? supervisorName
          : null,
    );

    final geo = geoFromBoundary(classData['boundary']);
    final boundaryJson = encodeBoundaryWithAssignments(geo, next);

    final docData = <String, dynamic>{'boundary': boundaryJson};
    if (isDean) {
      docData['actingAs'] = 'dean';
    }

    await AppwriteService.databases.updateDocument(
      databaseId: databaseId,
      collectionId: classesCollection,
      documentId: classDocId,
      data: docData,
    );

    await patchClassAssignments(classDocId: classDocId, assignments: next, isDean: isDean);

    if (prev.headAdminId != null && prev.headAdminId != next.headAdminId) {
      await _removeManagedClass(prev.headAdminId!, classDocId);
    }

    await linkClassStaff(
      classDocId: classDocId,
      l1AdminId: l1AdminId,
      assignments: next,
    );
  }

  /// Usernames of the admin(s) allowed to approve a leave request from
  /// [requesterId] at [requesterLevel]. Level 3 approvers are the
  /// supervisor(s) of the requester's own classes; Level 2's approver is
  /// whichever L1 they report to; Level 1 routes to the Dean.
  static Future<List<String>> resolveApprovers({
    required String requesterId,
    required int requesterLevel,
  }) async {
    if (requesterLevel == 1) return const ['dean'];

    if (requesterLevel == 2) {
      final l1 = await resolveReportingL1(requesterId);
      return l1.id != null && l1.id!.isNotEmpty ? [l1.id!] : const [];
    }

    if (requesterLevel == 3) {
      final classes = await fetchClassesForAdmin(
        adminId: requesterId,
        adminLevel: 3,
      );
      final supervisors = <String>{};
      for (final classDoc in classes) {
        final supervisorId = readAssignments(classDoc.data).supervisorId;
        if (supervisorId != null && supervisorId.isNotEmpty) {
          supervisors.add(supervisorId);
        }
      }
      return supervisors.toList();
    }

    return const [];
  }

  static String displayName(models.Document doc) {
    final data = doc.data;
    return data['name'] as String? ?? data['username'] as String? ?? 'Admin';
  }

  static String? username(models.Document? doc) =>
      doc?.data['username'] as String?;
}


