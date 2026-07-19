import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'services/appwrite_service.dart';

/// Reusable events management screen. Lets an admin (used by Level 1
/// Institution Admins, and reusable elsewhere) create, edit and delete their
/// own events. Backed by the existing `events` collection
/// (`title`, `date`, `createdBy`).
class EventManagementPage extends StatefulWidget {
  final String adminId;
  final String adminName;
  final Color accent;

  const EventManagementPage({
    super.key,
    required this.adminId,
    required this.adminName,
    this.accent = AppTheme.kGreen,
  });

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  static final String _kDb = AppwriteService.databaseId;
  List<models.Document> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'events',
        queries: [
          Query.equal('createdBy', widget.adminId),
          Query.orderDesc('date'),
          Query.limit(200),
        ],
      );
      if (mounted) {
        setState(() {
          _events = res.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _registrationCount(String eventId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        queries: [Query.equal('eventId', eventId), Query.limit(1)],
      );
      return res.total;
    } catch (_) {
      return 0;
    }
  }

  void _showEventSheet({models.Document? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.data['title'] as String? ?? '');
    DateTime date = existing?.data['date'] != null
        ? (DateTime.tryParse(existing!.data['date'] as String) ?? DateTime.now())
        : DateTime.now();
    bool saving = false;
    final isEdit = existing != null;

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
              left: 24,
              right: 24,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(isEdit ? "Edit Event" : "New Event",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                    labelText: "Event Title",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                          colorScheme:
                              ColorScheme.light(primary: widget.accent)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setSheet(() => date = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: widget.accent),
                      const SizedBox(width: 12),
                      Text("Date: ${DateFormat('EEE, dd MMM yyyy').format(date)}",
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            _snack('Please enter an event title.');
                            return;
                          }
                          setSheet(() => saving = true);
                          try {
                            if (isEdit) {
                              await AppwriteService.databases.updateDocument(
                                databaseId: _kDb,
                                collectionId: 'events',
                                documentId: existing.$id,
                                data: {
                                  'title': titleCtrl.text.trim(),
                                  'date': date.toIso8601String(),
                                },
                              );
                            } else {
                              await AppwriteService.databases.createDocument(
                                databaseId: _kDb,
                                collectionId: 'events',
                                documentId: ID.unique(),
                                data: {
                                  'title': titleCtrl.text.trim(),
                                  'date': date.toIso8601String(),
                                  'createdBy': widget.adminId,
                                },
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetch();
                          } catch (e) {
                            setSheet(() => saving = false);
                            _snack('Error: $e');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? "Save Changes" : "Create Event",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent(models.Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Event"),
        content: Text(
            "Delete \"${doc.data['title'] ?? 'this event'}\"? This can't be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppwriteService.databases.deleteDocument(
        databaseId: _kDb,
        collectionId: 'events',
        documentId: doc.$id,
      );
      _fetch();
      _snack('Event deleted.');
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text("Manage Events",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.accent,
        foregroundColor: Colors.white,
        onPressed: () => _showEventSheet(),
        icon: const Icon(Icons.add),
        label: const Text("New Event",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No events yet",
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black45)),
                        const SizedBox(height: 4),
                        Text("Tap “New Event” to create one.",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: widget.accent,
                    onRefresh: _fetch,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                      itemCount: _events.length,
                      itemBuilder: (ctx, i) => _eventCard(_events[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _eventCard(models.Document doc) {
    final data = doc.data;
    final title = data['title'] as String? ?? 'Untitled';
    DateTime? date;
    try {
      date = DateTime.parse(data['date'] as String);
    } catch (_) {}
    final isPast = date != null && date.isBefore(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event, color: widget.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        date != null
                            ? DateFormat('EEE, dd MMM yyyy').format(date)
                            : 'No date',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Past',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade700)),
                        ),
                      ],
                    ],
                  ),
                  FutureBuilder<int>(
                    future: _registrationCount(doc.$id),
                    builder: (_, snap) => Text(
                      '${snap.data ?? 0} registration(s)',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: widget.accent),
              onPressed: () => _showEventSheet(existing: doc),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: Colors.red.shade400),
              onPressed: () => _deleteEvent(doc),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
