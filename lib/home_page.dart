import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'class_detail_page.dart';
import 'main.dart';
import 'app_theme.dart';
import 'profile_page.dart';
import 'services/appwrite_service.dart';
import 'distribution/user_qr_page.dart';
import 'services/admin_hierarchy_service.dart';
import 'components/user_avatar.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String username;

  const HomePage({super.key, required this.name, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<models.Document> _classes = [];
  List<models.Document> _departmentClasses = [];
  List<models.Document> _pendingClasses = [];
  List<models.Document> _rejectedClasses = [];
  List<models.Document> _invitedClasses = [];
  String? _studentDepartment;
  String? _profilePictureId;
  bool _loading = true;
  bool _initialized = false;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _sub = AppwriteService.realtime
        .subscribe(['databases.${AppwriteService.databaseId}.collections.classes.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchClasses();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        queries: [Query.contains('studentIds', widget.username)],
      );

      final userResult = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'users',
        queries: [Query.equal('username', widget.username)],
      );

      String? dept;
      List<models.Document> deptClasses = [];
      List<models.Document> pendingClasses = [];
      List<models.Document> rejectedClasses = [];
      List<models.Document> invitedClasses = [];

      if (userResult.documents.isNotEmpty) {
        final data = userResult.documents.first.data;
        dept = data['department'] as String?;
        if (mounted) {
          setState(() {
            _profilePictureId = data['profilePictureId'] as String?;
          });
        }
      }

      // Fetch all classes to find pending/rejected requests and dept explore list
      try {
        Set<String> adminUsernames = {};
        if (dept != null && dept.isNotEmpty) {
          final adminResult = await AppwriteService.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: 'users',
            queries: [
              Query.equal('role', 'admin'),
              Query.equal('department', dept),
            ],
          );
          adminUsernames = adminResult.documents
              .map((d) => d.data['username'] as String?)
              .where((u) => u != null && u.isNotEmpty)
              .cast<String>()
              .toSet();
        }

        final allClassesResult = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteService.databaseId,
          collectionId: 'classes',
          queries: [Query.limit(500)],
        );

        final enrolledIds = result.documents.map((d) => d.$id).toSet();

        for (final doc in allClassesResult.documents) {
          if (enrolledIds.contains(doc.$id)) continue;

          final boundary = AdminHierarchyService.parseBoundaryRaw(doc.data['boundary']);
          final List<dynamic> pending = List.from(boundary['pendingStudents'] ?? []);
          final List<dynamic> rejected = List.from(boundary['rejectedStudents'] ?? []);
          final List<dynamic> invited = List.from(boundary['invitedStudents'] ?? []);

          final isPending = pending.any((s) => s['username'] == widget.username);
          final isRejected = rejected.any((s) => s['username'] == widget.username);
          final isInvited = invited.contains(widget.username);

          if (isInvited) {
            invitedClasses.add(doc);
          } else if (isPending) {
            pendingClasses.add(doc);
          } else if (isRejected) {
            rejectedClasses.add(doc);
          } else if (adminUsernames.contains(doc.data['createdBy'])) {
            deptClasses.add(doc);
          }
        }
      } catch (e) {
        debugPrint('Error fetching all classes: $e');
      }

      // Detect newly accepted classes for notification (skip on first load)
      if (_initialized && mounted) {
        final prevIds = _classes.map((d) => d.$id).toSet();
        for (final doc in result.documents) {
          if (!prevIds.contains(doc.$id)) {
            _showAcceptedNotification(doc.data['className'] ?? 'a class');
          }
        }
      }

      if (mounted) {
        setState(() {
          _classes = result.documents;
          _studentDepartment = dept;
          _departmentClasses = deptClasses;
          _pendingClasses = pendingClasses;
          _rejectedClasses = rejectedClasses;
          _invitedClasses = invitedClasses;
          _loading = false;
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching classes main: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAcceptedNotification(String className) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 4), () {
          if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.kGreen, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Request Accepted!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "You've been added to $className",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Great!"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Join a Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: "Class Code",
            hintText: "Enter the code provided by admin",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A8A73),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;

              // Capture messenger before any await to avoid async-gap lint
              final messenger = ScaffoldMessenger.of(context);

              try {
                final classQuery = await AppwriteService.databases.listDocuments(
                  databaseId: AppwriteService.databaseId,
                  collectionId: 'classes',
                  queries: [Query.equal('classCode', code)],
                );

                if (classQuery.documents.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Invalid class code.")),
                  );
                  return;
                }

                final classDoc = classQuery.documents.first;

                // Already enrolled
                final List<String> enrolled =
                    List<String>.from(classDoc.data['studentIds'] ?? []);
                if (enrolled.contains(widget.username)) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("You are already enrolled in this class.")),
                  );
                  return;
                }

                final boundary = AdminHierarchyService.parseBoundaryRaw(classDoc.data['boundary']);

                // Already pending
                final List<dynamic> pendingStudents =
                    List.from(boundary['pendingStudents'] ?? []);
                if (pendingStudents.any((s) => s['username'] == widget.username)) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Your request is already pending for this class.")),
                  );
                  return;
                }

                if (ctx.mounted) Navigator.pop(ctx);
                await _applyForClass(classDoc.$id, boundary);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Send Request"),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForClass(String classId, Map<String, dynamic> boundary) async {
    try {
      // Add to pending
      final List<dynamic> pending = List.from(boundary['pendingStudents'] ?? []);
      if (!pending.any((s) => s['username'] == widget.username)) {
        pending.add({
          'username': widget.username,
          'name': widget.name,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      boundary['pendingStudents'] = pending;

      // Remove from rejected if re-applying
      final List<dynamic> rejected = List.from(boundary['rejectedStudents'] ?? []);
      rejected.removeWhere((s) => s['username'] == widget.username);
      boundary['rejectedStudents'] = rejected;

      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        documentId: classId,
        data: {'boundary': jsonEncode(boundary)},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent! Waiting for admin approval.')),
        );
        _fetchClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelClassRequest(String classId, Map<String, dynamic> boundary) async {
    try {
      final List<dynamic> pending = List.from(boundary['pendingStudents'] ?? []);
      pending.removeWhere((s) => s['username'] == widget.username);
      boundary['pendingStudents'] = pending;

      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        documentId: classId,
        data: {'boundary': jsonEncode(boundary)},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled.')),
        );
        _fetchClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _acceptInvite(String classId, Map<String, dynamic> boundary, List<dynamic> currentStudentIds) async {
    try {
      final List<dynamic> invited = List.from(boundary['invitedStudents'] ?? []);
      invited.removeWhere((s) => s == widget.username);
      boundary['invitedStudents'] = invited;
      
      final List<dynamic> newStudents = List.from(currentStudentIds);
      if (!newStudents.contains(widget.username)) {
        newStudents.add(widget.username);
      }

      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        documentId: classId,
        data: {
            'boundary': jsonEncode(boundary),
            'studentIds': newStudents,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted!')),
        );
        _fetchClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _declineInvite(String classId, Map<String, dynamic> boundary) async {
    try {
      final List<dynamic> invited = List.from(boundary['invitedStudents'] ?? []);
      invited.removeWhere((s) => s == widget.username);
      boundary['invitedStudents'] = invited;

      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        documentId: classId,
        data: {'boundary': jsonEncode(boundary)},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
        _fetchClasses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Logout",
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: "My QR Code",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserQrPage(
                  username: widget.username,
                  name: widget.name,
                ),
              ),
            ),
          ),
          IconButton(
            icon: _profilePictureId != null
                ? UserAvatar(profilePictureId: _profilePictureId, fallbackName: widget.name, radius: 14)
                : const Icon(Icons.account_circle_outlined),
            tooltip: "Profile",
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfilePage(
                          username: widget.username,
                          name: widget.name,
                          profilePictureId: _profilePictureId,
                        ))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome back,", style: AppTheme.subheadingGrey),
                      const SizedBox(height: 4),
                      Text(widget.name, style: AppTheme.headingWhite),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.kGreen))
                    : _buildContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final bool hasAnything = _classes.isNotEmpty ||
        _pendingClasses.isNotEmpty ||
        _rejectedClasses.isNotEmpty ||
        _invitedClasses.isNotEmpty ||
        _departmentClasses.isNotEmpty;

    if (!hasAnything) {
      return _buildEmptyState(context);
    }
    return _buildScrollContent(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AppTheme.sheetHandle,
          const Spacer(),
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text("No Classes Joined", style: AppTheme.sectionTitle),
          const SizedBox(height: 8),
          Text(
            "You haven't joined any classes yet.\nJoin one to start tracking attendance.",
            textAlign: TextAlign.center,
            style: AppTheme.subheadingGrey,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: ElevatedButton.icon(
              onPressed: () => _showJoinClassDialog(context),
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text("Enter Class Code"),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildScrollContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: AppTheme.sheetHandle,
          ),
        ),

        // â”€â”€ Enrolled classes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_classes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ActivePeriodsBanner(
                classDocs: _classes,
                username: widget.username,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Classes", style: AppTheme.sectionTitle),
                  ElevatedButton.icon(
                    onPressed: () => _showJoinClassDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Join"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildEnrolledClassTile(context, _classes[index]),
                childCount: _classes.length,
              ),
            ),
          ),
        ] else ...[
          // No enrolled classes yet â€” show compact prompt
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: _buildNoClassesBanner(context),
            ),
          ),
        ],

        // â”€â”€ Invitations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_invitedClasses.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  Text("Invitations", style: AppTheme.sectionTitle),
                  const SizedBox(width: 8),
                  _requestCountChip(
                      "${_invitedClasses.length} new", Colors.purple),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildInviteTile(context, _invitedClasses[index]),
                childCount: _invitedClasses.length,
              ),
            ),
          ),
        ],

        // â”€â”€ My Requests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_pendingClasses.isNotEmpty || _rejectedClasses.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  Text("My Requests", style: AppTheme.sectionTitle),
                  const SizedBox(width: 8),
                  if (_pendingClasses.isNotEmpty)
                    _requestCountChip(
                        "${_pendingClasses.length} pending", Colors.amber.shade700),
                  if (_pendingClasses.isNotEmpty && _rejectedClasses.isNotEmpty)
                    const SizedBox(width: 6),
                  if (_rejectedClasses.isNotEmpty)
                    _requestCountChip(
                        "${_rejectedClasses.length} declined", Colors.red),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _pendingClasses.length) {
                    return _buildRequestTile(context, _pendingClasses[index], isPending: true);
                  }
                  return _buildRequestTile(
                      context, _rejectedClasses[index - _pendingClasses.length],
                      isPending: false);
                },
                childCount: _pendingClasses.length + _rejectedClasses.length,
              ),
            ),
          ),
        ],

        // â”€â”€ Explore Classes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_departmentClasses.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Explore Classes", style: AppTheme.sectionTitle),
                  Flexible(
                    child: Text(
                      _studentDepartment ?? '',
                      style: AppTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildExploreClassTile(context, _departmentClasses[index]),
                childCount: _departmentClasses.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoClassesBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("No Classes Joined", style: AppTheme.sectionTitle),
          const SizedBox(height: 6),
          Text(
            "Use a class code or browse available classes below.",
            textAlign: TextAlign.center,
            style: AppTheme.subheadingGrey,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showJoinClassDialog(context),
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text("Enter Class Code"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledClassTile(BuildContext context, models.Document doc) {
    final data = doc.data;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: AppTheme.kGreen),
              Expanded(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Hero(
                    tag: 'class_header_${doc.$id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data['className'] ?? "Unknown Class",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Code: ${data['classCode'] ?? 'Unknown'}",
                            style: AppTheme.labelSmall.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    final boundary =
                        AdminHierarchyService.parseBoundaryRaw(data['boundary']);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, anim, sa) => ClassDetailPage(
                          classId: doc.$id,
                          className: data['className'] ?? 'Class',
                          boundary: boundary,
                          username: widget.username,
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 0.2);
                          const end = Offset.zero;
                          const curve = Curves.fastOutSlowIn;
                          final slideTween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          final fadeTween =
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .chain(CurveTween(curve: Curves.easeIn));
                          final scaleTween =
                              Tween<double>(begin: 0.98, end: 1.0)
                                  .chain(CurveTween(curve: curve));
                          return FadeTransition(
                            opacity: animation.drive(fadeTween),
                            child: ScaleTransition(
                              scale: animation.drive(scaleTween),
                              child: SlideTransition(
                                position: animation.drive(slideTween),
                                child: child,
                              ),
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, models.Document doc,
      {required bool isPending}) {
    final data = doc.data;
    final boundary = AdminHierarchyService.parseBoundaryRaw(data['boundary']);
    final accentColor = isPending ? Colors.amber.shade700 : Colors.red;
    final statusLabel = isPending ? "Pending" : "Declined";
    final statusIcon = isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['className'] ?? "Unknown Class",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Code: ${data['classCode'] ?? 'Unknown'}",
                              style: AppTheme.labelSmall.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPending)
                        TextButton(
                          onPressed: () => _cancelClassRequest(doc.$id, boundary),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _applyForClass(doc.$id, boundary),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child:
                              const Text("Re-apply", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteTile(BuildContext context, models.Document doc) {
    final data = doc.data;
    final boundary = AdminHierarchyService.parseBoundaryRaw(data['boundary']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: Colors.purple),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['className'] ?? "Unknown Class",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Admin Invite",
                              style: AppTheme.labelSmall.copyWith(fontSize: 11, color: Colors.purple),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _declineInvite(doc.$id, boundary),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        child: const Text("Decline", style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _acceptInvite(doc.$id, boundary, data['studentIds'] ?? []),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Accept", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreClassTile(BuildContext context, models.Document doc) {
    final data = doc.data;
    final boundary = AdminHierarchyService.parseBoundaryRaw(data['boundary']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: Colors.blue),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['className'] ?? "Unknown Class",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Code: ${data['classCode'] ?? 'Unknown'}",
                              style: AppTheme.labelSmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _applyForClass(doc.$id, boundary),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Apply", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCountChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// =============================================================================
// _ActivePeriodsBanner â€“ shows active/upcoming sessions for all joined classes
// =============================================================================
class _ActivePeriodsBanner extends StatefulWidget {
  final List<models.Document> classDocs;
  final String username;

  const _ActivePeriodsBanner(
      {required this.classDocs, required this.username});

  @override
  State<_ActivePeriodsBanner> createState() => _ActivePeriodsBannerState();
}

class _ActivePeriodsBannerState extends State<_ActivePeriodsBanner> {
  final Map<String, List<Map<String, dynamic>>> _periodsMap = {};
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchAllPeriods();
    _sub = AppwriteService.realtime
        .subscribe(['databases.${AppwriteService.databaseId}.collections.periods.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchAllPeriods();
    });
  }

  @override
  void didUpdateWidget(covariant _ActivePeriodsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classDocs.length != widget.classDocs.length) {
      _fetchAllPeriods();
    }
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchAllPeriods() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, List<Map<String, dynamic>>> newMap = {};

    for (final classDoc in widget.classDocs) {
      final classId = classDoc.$id;
      final className = classDoc.data['className'] ?? 'Unknown Class';
      final boundary = classDoc.data['boundary'];

      try {
        final result = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteService.databaseId,
          collectionId: 'periods',
          queries: [
            Query.equal('classId', classId),
            Query.equal('date', todayStr),
          ],
        );

        final periods = result.documents.map((doc) {
          return <String, dynamic>{
            'id': doc.$id,
            'classId': classId,
            'className': className,
            'boundary': boundary,
            ...doc.data,
          };
        }).toList();

        newMap[classId] = periods;
      } catch (_) {
        newMap[classId] = [];
      }
    }

    if (mounted) setState(() => _periodsMap..clear()..addAll(newMap));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allPeriods = [];
    for (final list in _periodsMap.values) {
      allPeriods.addAll(list);
    }

    if (allPeriods.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();

    allPeriods.sort((a, b) {
      final aTs = a['startTime'] as String?;
      final bTs = b['startTime'] as String?;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return aTs.compareTo(bTs);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Classes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${allPeriods.length} Sessions",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPeriods.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final period = allPeriods[index];
              final startStr = period['startTime'] as String?;
              final endStr = period['endTime'] as String?;
              if (startStr == null || endStr == null) {
                return const SizedBox.shrink();
              }

              final realStart = DateTime.parse(startStr);
              final realEnd = DateTime.parse(endStr);
              final reportStart =
                  realStart.subtract(const Duration(minutes: 10));
              final reportEnd = realEnd.add(const Duration(minutes: 10));

              final isUpcoming = now.isBefore(reportStart);
              final isPast = now.isAfter(reportEnd);
              final isActive = !isUpcoming && !isPast;

              final accentColor = isActive
                  ? Colors.green
                  : (isUpcoming ? Colors.orange : Colors.grey);
              final statusText = isActive
                  ? "Active Now"
                  : (isUpcoming ? "Upcoming" : "Ended");

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.sensors : Icons.access_time_filled,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period['className'] ?? "Unknown Class",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${DateFormat('hh:mm a').format(realStart)} - ${DateFormat('hh:mm a').format(realEnd)}",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Spacer(),
                    if (isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () {
                            final rawBoundary = period['boundary'];
                            final boundary = rawBoundary is String &&
                                    rawBoundary.isNotEmpty
                                ? (jsonDecode(rawBoundary)
                                    as Map<String, dynamic>)
                                : (rawBoundary is Map<String, dynamic>
                                    ? rawBoundary
                                    : null);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDetailPage(
                                  classId: period['classId'],
                                  className: period['className'],
                                  boundary: boundary,
                                  username: widget.username,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Open to Report",
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


