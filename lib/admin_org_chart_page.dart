import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';
import 'services/admin_hierarchy_service.dart';

const _kSpecialRoles = ['officeAdmin', 'eventAdmin', 'hrAdmin', 'securityAdmin'];

const _kSpecialRoleLabels = {
  'officeAdmin': 'Office Admin',
  'eventAdmin': 'Event Admin',
  'hrAdmin': 'HR Admin',
  'securityAdmin': 'Security Admin',
};

class _SpecialRoleAdmin {
  final String id;
  final String name;
  final String role;
  final String? profilePictureId;

  _SpecialRoleAdmin({
    required this.id,
    required this.name,
    required this.role,
    this.profilePictureId,
  });
}

class OrgNode {
  final String id;
  final String name;
  final int level;
  final String department;
  final String? profilePictureId;
  final List<OrgNode> children;

  OrgNode({
    required this.id,
    required this.name,
    required this.level,
    required this.department,
    this.profilePictureId,
    required this.children,
  });
}

class AdminOrgChartPage extends StatefulWidget {
  final String currentAdminId;

  const AdminOrgChartPage({super.key, required this.currentAdminId});

  @override
  State<AdminOrgChartPage> createState() => _AdminOrgChartPageState();
}

class _AdminOrgChartPageState extends State<AdminOrgChartPage> {
  bool _isLoading = true;
  List<OrgNode> _roots = [];
  List<_SpecialRoleAdmin> _specialRoleAdmins = [];

  @override
  void initState() {
    super.initState();
    _fetchAndBuildTree();
  }

  Future<void> _fetchAndBuildTree() async {
    try {
      // 1. Fetch all admins
      final result = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'users',
        queries: [
          Query.equal('role', 'admin'),
          Query.limit(500),
        ],
      );
      final admins = result.documents;

      // 1b. Fetch cross-cutting roles separately — they have no
      // head/supervisor relationship to nest in the tree above.
      final specialResult = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'users',
        queries: [
          Query.equal('role', _kSpecialRoles),
          Query.limit(200),
        ],
      );
      final specialRoleAdmins = specialResult.documents
          .map((doc) => _SpecialRoleAdmin(
                id: doc.data['username'] as String? ?? '',
                name: doc.data['name'] as String? ??
                    doc.data['username'] as String? ??
                    'Admin',
                role: doc.data['role'] as String? ?? '',
                profilePictureId: doc.data['profilePictureId'] as String?,
              ))
          .where((a) => a.id.isNotEmpty)
          .toList();

      // 2. Fetch all classes to determine relationships
      final classesResult = await AppwriteService.databases.listDocuments(
        databaseId: '6a2c10dc000d5e50f314',
        collectionId: 'classes',
        queries: [
          Query.limit(500),
        ],
      );
      final classes = classesResult.documents;

      // 3. Map parent-child relationships based on classes
      final Map<String, String> parentOf = {};
      for (final classDoc in classes) {
        final data = classDoc.data;
        final createdBy = data['createdBy'] as String? ?? '';
        
        final assignments = AdminHierarchyService.readAssignments(data);
        final headAdminId = assignments.headAdminId ?? ''; // L3
        final supervisorId = assignments.supervisorId ?? ''; // L2

        if (createdBy.isNotEmpty) {
          if (supervisorId.isNotEmpty) {
            parentOf[supervisorId] = createdBy;
          }
          if (headAdminId.isNotEmpty) {
            parentOf[headAdminId] = createdBy;
          }
        }
      }

      // 4. Initialize OrgNode objects for all admins
      final Map<String, OrgNode> allNodes = {};
      for (final doc in admins) {
        final id = doc.data['username'] as String? ?? '';
        if (id.isEmpty) continue;
        final level = doc.data['level'] as int? ?? 1;
        allNodes[id] = OrgNode(
          id: id,
          name: doc.data['name'] ?? id,
          level: level,
          department: doc.data['department'] ?? 'N/A',
          profilePictureId: doc.data['profilePictureId'],
          children: [],
        );
      }

      // 5. Connect child nodes to their parent nodes
      final List<OrgNode> roots = [];
      for (final doc in admins) {
        final id = doc.data['username'] as String? ?? '';
        if (id.isEmpty) continue;
        final node = allNodes[id]!;
        
        final parentId = parentOf[id];
        if (parentId != null && parentId.isNotEmpty && allNodes.containsKey(parentId)) {
          // Avoid duplicate children
          if (!allNodes[parentId]!.children.any((c) => c.id == node.id)) {
            allNodes[parentId]!.children.add(node);
          }
        } else {
          roots.add(node);
        }
      }

      // 6. Sort children by level
      for (final node in allNodes.values) {
        node.children.sort((a, b) => a.level.compareTo(b.level));
      }

      // 7. Sort the roots list by admin level so that L1s are shown first
      roots.sort((a, b) => a.level.compareTo(b.level));

      if (mounted) {
        setState(() {
          _roots = roots;
          _specialRoleAdmins = specialRoleAdmins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Organizational Chart",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.kGreen))
                    : (_roots.isEmpty && _specialRoleAdmins.isEmpty)
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              if (_specialRoleAdmins.isNotEmpty) ...[
                                _buildSpecialRolesSection(),
                                const SizedBox(height: 28),
                                if (_roots.isNotEmpty)
                                  Text(
                                    "Institution Hierarchy",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                if (_roots.isNotEmpty)
                                  const SizedBox(height: 16),
                              ],
                              for (int i = 0; i < _roots.length; i++)
                                _buildNode(
                                  _roots[i],
                                  0,
                                  i == _roots.length - 1,
                                  [],
                                ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cross-Cutting Roles",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Operate institution-wide, outside the L1/L2/L3 chain",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _specialRoleAdmins.map((a) {
            final isMe = a.id == widget.currentAdminId;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe ? AppTheme.kGreen : Colors.grey.shade200,
                  width: isMe ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    profilePictureId: a.profilePictureId,
                    fallbackName: a.name,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        _kSpecialRoleLabels[a.role] ?? a.role,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text("No Administrators Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPrefixText(int depth, bool isLast, List<bool> isLastList) {
    if (depth == 0) return const SizedBox.shrink();
    String prefix = "";
    for (int i = 0; i < depth - 1; i++) {
      prefix += isLastList[i] ? "        " : "   â”‚    ";
    }
    prefix += isLast ? "   â””â”€â”€ " : "   â”œâ”€â”€ ";
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        prefix,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Colors.grey,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNode(OrgNode node, int depth, bool isLast, List<bool> isLastList) {
    final isMe = node.id == widget.currentAdminId;
    
    String roleLabel = "Admin";
    Color roleColor = Colors.purple;
    if (node.level == 2) {
      roleLabel = "Head of Department";
      roleColor = const Color(0xFF4E7A8A);
    } else if (node.level == 3) {
      roleLabel = "Team Leader";
      roleColor = const Color(0xFF7A6A8A);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrefixText(depth, isLast, isLastList),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isMe ? roleColor.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMe ? roleColor : Colors.transparent,
                      width: isMe ? 2 : 0,
                    ),
                    boxShadow: [
                      if (!isMe)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        UserAvatar(
                          profilePictureId: node.profilePictureId,
                          fallbackName: node.name,
                          radius: 20,
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          foregroundColor: roleColor,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                node.department,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (node.children.isNotEmpty)
          Column(
            children: List.generate(node.children.length, (index) {
              final child = node.children[index];
              final childIsLast = index == node.children.length - 1;
              final childIsLastList = List<bool>.from(isLastList)..add(isLast);
              return _buildNode(child, depth + 1, childIsLast, childIsLastList);
            }),
          ),
      ],
    );
  }
}


