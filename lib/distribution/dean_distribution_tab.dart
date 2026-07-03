import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, Center;
import '../services/distribution_service.dart';
import '../services/appwrite_service.dart';

const Color _kDark = Color(0xFF10121C);
const Color _kGold = Color(0xFFD4AF37);
const Color _kBg = Color(0xFFF8F9FB);

class DeanDistributionTab extends StatefulWidget {
  const DeanDistributionTab({super.key});

  @override
  State<DeanDistributionTab> createState() => _DeanDistributionTabState();
}

class _DeanDistributionTabState extends State<DeanDistributionTab> {
  List<models.Document> _events = [];
  bool _loading = true;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _sub = AppwriteService.realtime.subscribe(
        ['databases.${AppwriteService.databaseId}.collections.distribution_events.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchEvents();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    try {
      final result = await DistributionService.getEvents();
      if (mounted) {
        setState(() {
          _events = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Create event bottom sheet
  // ---------------------------------------------------------------------------

  void _showCreateEventSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("New Distribution Event",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _field(titleCtrl, "Event Title", Icons.title),
              const SizedBox(height: 12),
              _field(descCtrl, "Description", Icons.description_outlined,
                  maxLines: 3),
              const SizedBox(height: 12),
              _field(locationCtrl, "Location", Icons.location_on_outlined),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheet(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF6A8A73)),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setSheet(() => saving = true);
                          try {
                            await DistributionService.createEvent(
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              scheduledDate: selectedDate.toIso8601String(),
                              location: locationCtrl.text.trim(),
                              createdBy: 'dean',
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchEvents();
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text("Error: $e")));
                            }
                          } finally {
                            setSheet(() => saving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(color: _kGold)
                      : Text("Create Event",
                          style: GoogleFonts.poppins(
                              color: _kGold, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Event detail bottom sheet
  // ---------------------------------------------------------------------------

  void _showEventDetail(models.Document eventDoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _EventDetailSheet(
        eventDoc: eventDoc,
        onChanged: _fetchEvents,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: _kGold))
            : _events.isEmpty
                ? _buildEmptyState()
                : _buildEventList(),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: _kDark,
            foregroundColor: _kGold,
            icon: const Icon(Icons.add),
            label: Text("New Event",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            onPressed: _showCreateEventSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No distribution events yet",
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 15)),
          const SizedBox(height: 6),
          Text("Tap + New Event to get started",
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _events.length,
      itemBuilder: (ctx, i) {
        final doc = _events[i];
        final d = doc.data;
        final status = d['status'] as String? ?? 'draft';
        final issued = d['issuedCount'] as int? ?? 0;
        final total = d['totalRecipients'] as int? ?? 0;
        final date = d['scheduledDate'] != null
            ? DateFormat('MMM dd, yyyy')
                .format(DateTime.parse(d['scheduledDate'] as String))
            : 'â€”';

        return GestureDetector(
          onTap: () => _showEventDetail(doc),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d['title'] as String? ?? 'Untitled',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                    if ((d['location'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d['location'] as String? ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (status != 'draft') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? issued / total : 0,
                            backgroundColor: Colors.grey.shade200,
                            color: status == 'closed'
                                ? Colors.grey
                                : const Color(0xFF6A8A73),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("$issued / $total",
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'draft': [Colors.orange.shade100, Colors.orange.shade700],
      'active': [const Color(0xFFE8F5E9), const Color(0xFF388E3C)],
      'closed': [Colors.grey.shade100, Colors.grey.shade600],
    };
    final c = colors[status] ?? colors['draft']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.bold, color: c[1]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kGold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }
}

// =============================================================================
// Event Detail Sheet â€” stateful sub-widget
// =============================================================================

class _EventDetailSheet extends StatefulWidget {
  final models.Document eventDoc;
  final VoidCallback onChanged;

  const _EventDetailSheet(
      {required this.eventDoc, required this.onChanged});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  late models.Document _event;
  List<models.Document> _recipients = [];
  List<models.Document> _assignments = [];
  bool _loadingRecipients = true;
  bool _loadingAssignments = true;
  bool _actioning = false;

  @override
  void initState() {
    super.initState();
    _event = widget.eventDoc;
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    _fetchRecipients();
    _fetchAssignments();
    try {
      final fresh =
          await DistributionService.getEventById(_event.$id);
      if (mounted) setState(() => _event = fresh);
    } catch (_) {}
  }

  Future<void> _fetchRecipients() async {
    try {
      final r = await DistributionService.getRecipients(_event.$id);
      if (mounted) {
        setState(() {
          _recipients = r.documents;
          _loadingRecipients = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRecipients = false);
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      final r = await DistributionService.getAssignments(_event.$id);
      if (mounted) {
        setState(() {
          _assignments = r.documents;
          _loadingAssignments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignments = false);
    }
  }

  // --- Excel bulk upload ---
  Future<void> _uploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    // Decode bytes
    final fileBytes = result.files.first.bytes ??
        (result.files.first.path != null
            ? File(result.files.first.path!).readAsBytesSync()
            : null);
    if (fileBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not read file.")));
      }
      return;
    }

    final excel = Excel.decodeBytes(fileBytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.maxRows == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Empty spreadsheet.")));
      }
      return;
    }

    // Collect usernames from column A (skip header row if it looks like a label)
    final usernames = <String>[];
    for (int r = 0; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      if (row.isEmpty) continue;
      final cell = row[0];
      if (cell == null || cell.value == null) continue;
      final val = cell.value.toString().trim();
      if (val.isEmpty) continue;
      // Skip header row
      if (r == 0 && (val.toLowerCase() == 'username' || val.toLowerCase() == 'id')) continue;
      usernames.add(val);
    }

    if (usernames.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No usernames found in column A.")));
      }
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Bulk Add Recipients",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            "Found ${usernames.length} username(s) in the file.\nAdd them all to this event?",
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kDark, foregroundColor: _kGold),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Add All"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Progress dialog
    final progressNotifier = ValueNotifier("Adding recipients (0 / ${usernames.length})...");
    int added = 0, failed = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ValueListenableBuilder<String>(
            valueListenable: progressNotifier,
            builder: (_, msg, __) => Row(
              children: [
                const CircularProgressIndicator(color: Color(0xFF6A8A73)),
                const SizedBox(width: 16),
                Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < usernames.length; i++) {
      final uid = usernames[i];
      progressNotifier.value = "Adding recipients (${i + 1} / ${usernames.length})...";
      try {
        // Look up the user's display name
        final userQuery = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteService.databaseId,
          collectionId: 'users',
          queries: [Query.equal('username', uid), Query.limit(1)],
        );
        final displayName = userQuery.documents.isNotEmpty
            ? (userQuery.documents.first.data['name'] as String? ?? uid)
            : uid;
        await DistributionService.addRecipient(
          eventId: _event.$id,
          userId: uid,
          userName: displayName,
          callerId: 'dean',
          isDean: true,
        );
        added++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) Navigator.of(context).pop(); // close progress dialog
    _refreshAll();
    widget.onChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Done: $added added, ${usernames.length - added - failed} already existed, $failed failed"),
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // --- Add Recipient ---
  void _showAddRecipientDialog() {
    final searchCtrl = TextEditingController();
    List<models.Document> searchResults = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text("Add Recipient",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search by name or ID...",
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6A8A73)),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (q) async {
                    if (q.trim().length < 2) {
                      setDlg(() => searchResults = []);
                      return;
                    }
                    setDlg(() => searching = true);
                    try {
                      // Two queries: name prefix match + username prefix match
                      // Merged and deduplicated client-side (no FTS index needed)
                      final byName = await AppwriteService.databases
                          .listDocuments(
                        databaseId: AppwriteService.databaseId,
                        collectionId: 'users',
                        queries: [
                          Query.startsWith('name', q.trim()),
                          Query.limit(8),
                        ],
                      );
                      final byId = await AppwriteService.databases
                          .listDocuments(
                        databaseId: AppwriteService.databaseId,
                        collectionId: 'users',
                        queries: [
                          Query.startsWith('username', q.trim()),
                          Query.limit(5),
                        ],
                      );
                      final seen = <String>{};
                      final merged = [
                        ...byName.documents,
                        ...byId.documents,
                      ].where((d) => seen.add(d.$id)).toList();
                      setDlg(() {
                        searchResults = merged;
                        searching = false;
                      });
                    } catch (_) {
                      setDlg(() => searching = false);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (_, i) {
                        final u = searchResults[i].data;
                        final alreadyAdded = _recipients.any((r) =>
                            r.data['userId'] == u['username']);
                        return ListTile(
                          dense: true,
                          title: Text(u['name'] as String? ?? 'â€”',
                              style: GoogleFonts.poppins(fontSize: 13)),
                          subtitle: Text(
                              u['username'] as String? ?? 'â€”',
                              style: GoogleFonts.poppins(fontSize: 11)),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF6A8A73), size: 18)
                              : const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF6A8A73), size: 18),
                          onTap: alreadyAdded
                              ? null
                              : () async {
                                  try {
                                    await DistributionService.addRecipient(
                                      eventId: _event.$id,
                                      userId: u['username'] as String,
                                      userName: u['name'] as String? ??
                                          u['username'] as String,
                                      callerId: 'dean',
                                      isDean: true,
                                    );
                                    _refreshAll();
                                    widget.onChanged();
                                    setDlg(() {
                                      searchResults = searchResults
                                          .toList();
                                    });
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx)
                                          .showSnackBar(SnackBar(
                                              content: Text("Error: $e")));
                                    }
                                  }
                                },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Done",
                  style: TextStyle(color: Color(0xFF6A8A73))),
            ),
          ],
        ),
      ),
    );
  }

  // --- Assign Admin ---
  void _showAssignAdminDialog() {
    List<models.Document> adminList = [];
    bool loading = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          if (loading) {
            Future(() async {
              try {
                final r = await AppwriteService.databases.listDocuments(
                  databaseId: AppwriteService.databaseId,
                  collectionId: 'users',
                  queries: [Query.equal('role', 'admin'), Query.limit(50)],
                );
                setDlg(() {
                  adminList = r.documents;
                  loading = false;
                });
              } catch (_) {
                setDlg(() => loading = false);
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text("Assign Admin",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: loading
                ? const SizedBox(
                    height: 60,
                    child: Center(
                        child:
                            CircularProgressIndicator(
                                color: Color(0xFF6A8A73))))
                : adminList.isEmpty
                    ? Text("No admins found.",
                        style: GoogleFonts.poppins(color: Colors.grey))
                    : SizedBox(
                        width: double.maxFinite,
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxHeight: 260),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: adminList.length,
                            itemBuilder: (_, i) {
                              final u = adminList[i].data;
                              final adminId =
                                  u['username'] as String? ?? '';
                              final alreadyAssigned = _assignments.any(
                                  (a) => a.data['adminId'] == adminId);
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF6A8A73)
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    (u['name'] as String? ?? 'A')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Color(0xFF6A8A73),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                                title: Text(u['name'] as String? ?? 'â€”',
                                    style:
                                        GoogleFonts.poppins(fontSize: 13)),
                                subtitle: Text(
                                    "Level ${u['level'] ?? 'â€”'}",
                                    style:
                                        GoogleFonts.poppins(fontSize: 11)),
                                trailing: alreadyAssigned
                                    ? const Icon(Icons.check_circle,
                                        color: Color(0xFF6A8A73),
                                        size: 18)
                                    : const Icon(
                                        Icons.person_add_outlined,
                                        color: Color(0xFF6A8A73),
                                        size: 18),
                                onTap: alreadyAssigned
                                    ? null
                                    : () async {
                                        try {
                                          await DistributionService
                                              .assignAdmin(
                                            eventId: _event.$id,
                                            adminId: adminId,
                                            adminName: u['name']
                                                    as String? ??
                                                adminId,
                                            assignedBy: 'dean',
                                            isDean: true,
                                          );
                                          _fetchAssignments();
                                          setDlg(() {});
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(SnackBar(
                                                    content:
                                                        Text("Error: $e")));
                                          }
                                        }
                                      },
                              );
                            },
                          ),
                        ),
                      ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done",
                    style: TextStyle(color: Color(0xFF6A8A73))),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- View Scan Logs ---
  void _showScanLogs() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Scan Audit Log",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: FutureBuilder<models.DocumentList>(
          future: DistributionService.getScanLogs(_event.$id),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                  height: 60,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6A8A73))));
            }
            final logs = snap.data!.documents;
            if (logs.isEmpty) {
              return Text("No scans yet.",
                  style: GoogleFonts.poppins(color: Colors.grey));
            }
            return SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (_, i) {
                    final l = logs[i].data;
                    final action = l['action'] as String? ?? '';
                    final ts = l['timestamp'] as String?;
                    final timeStr = ts != null
                        ? DateFormat('MMM dd, HH:mm')
                            .format(DateTime.parse(ts).toLocal())
                        : 'â€”';
                    final actionColor = {
                      'issued': Colors.green,
                      'duplicate_attempt': Colors.orange,
                      'ineligible': Colors.red,
                      'revoked': Colors.red.shade300,
                    }[action] ?? Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: actionColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['scannedUserId'] as String? ?? 'â€”',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "$action â€¢ $timeStr",
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close",
                style: TextStyle(color: Color(0xFF6A8A73))),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final d = _event.data;
    final status = d['status'] as String? ?? 'draft';
    final issued = d['issuedCount'] as int? ?? 0;
    final total = d['totalRecipients'] as int? ?? 0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['title'] as String? ?? 'Untitled',
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if ((d['location'] as String? ?? '').isNotEmpty)
                        Text(
                          d['location'] as String? ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            if (status != 'draft') ...[
              const SizedBox(height: 16),
              _statCard(issued, total),
            ],

            const SizedBox(height: 24),

            // Assigned Admins
            _sectionHeader("Assigned Admins", Icons.admin_panel_settings_outlined,
                onAdd: status == 'closed' ? null : _showAssignAdminDialog),
            const SizedBox(height: 8),
            _loadingAssignments
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF6A8A73)))
                : _assignments.isEmpty
                    ? _emptyRow("No admins assigned yet")
                    : Column(
                        children: _assignments.map((a) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF6A8A73)
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  (a.data['adminName'] as String? ?? 'A')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF6A8A73),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              title: Text(
                                  a.data['adminName'] as String? ?? 'â€”',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              subtitle: Text(
                                  a.data['adminId'] as String? ?? 'â€”',
                                  style: GoogleFonts.poppins(fontSize: 11)),
                              trailing: status != 'closed'
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle_outline,
                                          color: Colors.redAccent, size: 18),
                                      onPressed: () async {
                                        await DistributionService.revokeAdmin(
                                            a.$id,
                                            callerId: 'dean',
                                            isDean: true);
                                        _fetchAssignments();
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

            const SizedBox(height: 20),

            // Recipients
            _recipientsHeader(status),
            const SizedBox(height: 8),
            _loadingRecipients
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF6A8A73)))
                : _recipients.isEmpty
                    ? _emptyRow("No recipients added yet")
                    : Column(
                        children: _recipients.map((r) {
                          final rStatus =
                              r.data['status'] as String? ?? 'pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: _recipientStatusIcon(rStatus),
                              title: Text(
                                  r.data['userName'] as String? ?? 'â€”',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              subtitle: Text(
                                  r.data['userId'] as String? ?? 'â€”',
                                  style: GoogleFonts.poppins(fontSize: 11)),
                              trailing: rStatus == 'pending' &&
                                      status != 'closed'
                                  ? IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 18),
                                      onPressed: () async {
                                        await DistributionService
                                            .removeRecipient(
                                                r.$id, _event.$id,
                                                callerId: 'dean',
                                                isDean: true);
                                        _refreshAll();
                                        widget.onChanged();
                                      },
                                    )
                                  : _recipientStatusLabel(rStatus),
                            ),
                          );
                        }).toList(),
                      ),

            const SizedBox(height: 28),

            // Scan logs button
            if (status != 'draft')
              OutlinedButton.icon(
                onPressed: _showScanLogs,
                icon: const Icon(Icons.history, size: 16),
                label: const Text("View Scan Audit Log"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kDark,
                  side: const BorderSide(color: _kDark),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 12),

            // Action button
            if (status == 'draft')
              ElevatedButton.icon(
                onPressed: _actioning
                    ? null
                    : () => _doAction(() async {
                          await DistributionService.activateEvent(
                              _event.$id,
                              callerId: 'dean',
                              isDean: true);
                          widget.onChanged();
                          _refreshAll();
                        }),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text("Activate Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              )
            else if (status == 'active')
              ElevatedButton.icon(
                onPressed: _actioning
                    ? null
                    : () => _confirmClose(),
                icon: const Icon(Icons.lock_outlined),
                label: const Text("Close Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Close Event?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "No more packages can be issued once the event is closed."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _doAction(() async {
                await DistributionService.closeEvent(_event.$id,
                    callerId: 'dean', isDean: true);
                widget.onChanged();
                _refreshAll();
              });
            },
            child: const Text("Close Event"),
          ),
        ],
      ),
    );
  }

  Future<void> _doAction(Future<void> Function() fn) async {
    setState(() => _actioning = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  // --- Helpers ---

  Widget _statCard(int issued, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Packages Issued",
                  style:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
              Text("$issued / $total",
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF388E3C))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? issued / total : 0,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF6A8A73),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientsHeader(String status) {
    final isClosed = status == 'closed';
    return Row(
      children: [
        const Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          "Recipients (${_recipients.length})",
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700),
        ),
        const Spacer(),
        if (!isClosed) ...[
          GestureDetector(
            onTap: _uploadExcel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_chart_outlined,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text("Excel",
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showAddRecipientDialog,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _kDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("+ Add",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _kGold,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, IconData icon, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700),
        ),
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _kDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("+ Add",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _kGold,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _emptyRow(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(msg,
            style:
                GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13)),
      ),
    );
  }

  Widget _recipientStatusIcon(String status) {
    final map = {
      'pending': [Icons.pending_outlined, Colors.orange],
      'issued': [Icons.inventory_2_outlined, Colors.blue],
      'acknowledged': [Icons.check_circle_outline, Colors.green],
      'revoked': [Icons.block, Colors.red],
    };
    final v = map[status] ?? map['pending']!;
    return Icon(v[0] as IconData, color: v[1] as Color, size: 20);
  }

  Widget _recipientStatusLabel(String status) {
    final colors = {
      'issued': Colors.blue,
      'acknowledged': Colors.green,
      'revoked': Colors.red,
    };
    return Text(
      status.toUpperCase(),
      style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colors[status] ?? Colors.grey),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'draft': [Colors.orange.shade100, Colors.orange.shade700],
      'active': [const Color(0xFFE8F5E9), const Color(0xFF388E3C)],
      'closed': [Colors.grey.shade100, Colors.grey.shade600],
    };
    final c = colors[status] ?? colors['draft']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.bold, color: c[1]),
      ),
    );
  }
}


