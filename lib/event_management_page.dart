import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'services/admin_presence_service.dart';

enum EventMode {
  /// Level 1 host: create/edit/delete, set location+geofence, assign L2/L3.
  host,

  /// Assigned Level 2/3: read-only view of events they're on, geofence-gated
  /// "Claim Presence".
  assigned,
}

/// Events management screen.
///
/// **Host mode** (Level 1 Institution Admin): create/edit/delete events, each
/// with a human-readable `location`, an optional geofence `boundary`, and an
/// assigned set of Level 2/3 admins.
///
/// **Assigned mode** (Level 2/3): read-only list of the events they've been
/// assigned to, with a "Claim Presence" action that only succeeds inside the
/// event's geofence. Backed by the `events` collection
/// (`title`, `date`, `location`, `boundary`, `createdBy`, `assignedAdminIds`,
/// `assignedAdminNames`) and `event_registrations`.
class EventManagementPage extends StatefulWidget {
  final String adminId;
  final String adminName;
  final Color accent;
  final EventMode mode;

  const EventManagementPage({
    super.key,
    required this.adminId,
    required this.adminName,
    this.accent = AppTheme.kGreen,
    this.mode = EventMode.host,
  });

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  static final String _kDb = AppwriteService.databaseId;
  List<models.Document> _events = [];
  bool _loading = true;

  bool get _isHost => widget.mode == EventMode.host;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Map<String, dynamic>? _parseBoundary(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map &&
            d['lat'] != null &&
            d['lng'] != null &&
            d['radiusMeters'] != null) {
          return {
            'lat': (d['lat'] as num).toDouble(),
            'lng': (d['lng'] as num).toDouble(),
            'radiusMeters': (d['radiusMeters'] as num).toDouble(),
          };
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      if (_isHost) {
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
      } else {
        // Assigned mode: fetch recent events and keep those this admin is on.
        final res = await AppwriteService.databases.listDocuments(
          databaseId: _kDb,
          collectionId: 'events',
          queries: [Query.orderDesc('date'), Query.limit(500)],
        );
        final mine = res.documents.where((d) {
          final ids = (d.data['assignedAdminIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [];
          return ids.contains(widget.adminId);
        }).toList();
        if (mounted) {
          setState(() {
            _events = mine;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _presentCount(String eventId) async {
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

  Future<models.Document?> _myClaim(String eventId) async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        queries: [
          Query.equal('eventId', eventId),
          Query.equal('userId', widget.adminId),
          Query.limit(1),
        ],
      );
      return res.documents.isEmpty ? null : res.documents.first;
    } catch (_) {
      return null;
    }
  }

  // ── Create / edit event (host) ─────────────────────────────────────────
  void _showEventSheet({models.Document? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.data['title'] as String? ?? '');
    final locationCtrl = TextEditingController(
        text: existing?.data['location'] as String? ?? '');
    DateTime date = existing?.data['date'] != null
        ? (DateTime.tryParse(existing!.data['date'] as String) ?? DateTime.now())
        : DateTime.now();
    Map<String, dynamic>? boundary = _parseBoundary(existing?.data['boundary']);
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
          child: SingleChildScrollView(
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
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                      labelText: "Location (e.g. Main Auditorium)",
                      prefixIcon: Icon(Icons.place_outlined, color: widget.accent),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: widget.accent),
                        const SizedBox(width: 12),
                        Text(
                            "Date: ${DateFormat('EEE, dd MMM yyyy').format(date)}",
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Geofence picker
                InkWell(
                  onTap: () async {
                    final picked = await _openBoundaryPicker(boundary);
                    if (picked != null) setSheet(() => boundary = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: boundary != null
                                ? widget.accent.withValues(alpha: 0.5)
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.my_location,
                            size: 18,
                            color: boundary != null
                                ? widget.accent
                                : Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            boundary != null
                                ? "Geofenced · ${(boundary!['radiusMeters'] as num).toStringAsFixed(0)} m radius"
                                : "Set event geofence (optional)",
                            style: TextStyle(
                                fontSize: 14,
                                color: boundary != null
                                    ? widget.accent
                                    : Colors.grey.shade600,
                                fontWeight: boundary != null
                                    ? FontWeight.w600
                                    : FontWeight.normal),
                          ),
                        ),
                        if (boundary != null)
                          GestureDetector(
                            onTap: () => setSheet(() => boundary = null),
                            child: Icon(Icons.close,
                                size: 16, color: widget.accent),
                          ),
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
                              final data = <String, dynamic>{
                                'title': titleCtrl.text.trim(),
                                'date': date.toIso8601String(),
                                'location': locationCtrl.text.trim(),
                                'boundary':
                                    boundary != null ? jsonEncode(boundary) : '',
                              };
                              if (isEdit) {
                                await AppwriteService.databases.updateDocument(
                                  databaseId: _kDb,
                                  collectionId: 'events',
                                  documentId: existing.$id,
                                  data: data,
                                );
                              } else {
                                data['createdBy'] = widget.adminId;
                                await AppwriteService.databases.createDocument(
                                  databaseId: _kDb,
                                  collectionId: 'events',
                                  documentId: ID.unique(),
                                  data: data,
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
      ),
    );
  }

  // ── Assign Level 2/3 admins to an event (host) ─────────────────────────
  Future<void> _showAssignSheet(models.Document event) async {
    List<models.Document> admins = [];
    bool loading = true;
    final selected = <String>{
      ...((event.data['assignedAdminIds'] as List?)
              ?.map((e) => e.toString()) ??
          const []),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (loading) {
            AppwriteService.databases.listDocuments(
              databaseId: _kDb,
              collectionId: 'users',
              queries: [
                Query.equal('role', 'admin'),
                Query.equal('level', [2, 3]),
                Query.limit(200),
              ],
            ).then((res) {
              if (!ctx.mounted) return;
              setSheet(() {
                admins = res.documents
                    .where((d) => d.data['status'] != 'disabled')
                    .toList();
                loading = false;
              });
            }).catchError((_) {
              if (ctx.mounted) setSheet(() => loading = false);
            });
          }
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text("Assign Admins",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Select Level 2/3 admins to run this event.",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: loading
                        ? Center(
                            child: CircularProgressIndicator(color: widget.accent))
                        : admins.isEmpty
                            ? Center(
                                child: Text("No Level 2/3 admins found.",
                                    style: TextStyle(
                                        color: Colors.grey.shade500)))
                            : ListView.builder(
                                itemCount: admins.length,
                                itemBuilder: (_, i) {
                                  final a = admins[i];
                                  final uname =
                                      a.data['username'] as String? ?? '';
                                  final lvl = a.data['level'];
                                  final checked = selected.contains(uname);
                                  return CheckboxListTile(
                                    value: checked,
                                    activeColor: widget.accent,
                                    title: Text(
                                        a.data['name'] as String? ?? uname),
                                    subtitle: Text(
                                        "${lvl == 2 ? 'Head of Dept' : 'Team Leader'} · ${a.data['department'] ?? ''}",
                                        style: const TextStyle(fontSize: 12)),
                                    onChanged: (v) => setSheet(() {
                                      if (v == true) {
                                        selected.add(uname);
                                      } else {
                                        selected.remove(uname);
                                      }
                                    }),
                                  );
                                },
                              ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ids = selected.toList();
                        final names = admins
                            .where((a) =>
                                selected.contains(a.data['username']))
                            .map((a) =>
                                a.data['name'] as String? ??
                                a.data['username'] as String? ??
                                '')
                            .toList();
                        try {
                          await AppwriteService.databases.updateDocument(
                            databaseId: _kDb,
                            collectionId: 'events',
                            documentId: event.$id,
                            data: {
                              'assignedAdminIds': ids,
                              'assignedAdminNames': names,
                            },
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetch();
                          _snack('Assigned ${ids.length} admin(s).');
                        } catch (e) {
                          _snack('Failed: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Save Assignment",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Claim presence at an event (assigned L2/L3), geofence-gated ─────────
  Future<void> _claim(models.Document event) async {
    final boundary = _parseBoundary(event.data['boundary']);
    final progress = ValueNotifier<String>('Checking your location…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ValueListenableBuilder<String>(
          valueListenable: progress,
          builder: (_, v, __) => Row(children: [
            CircularProgressIndicator(color: widget.accent),
            const SizedBox(width: 20),
            Expanded(child: Text(v)),
          ]),
        ),
      ),
    );
    try {
      // Guard against a double-claim.
      if (await _myClaim(event.$id) != null) {
        if (mounted) Navigator.of(context).pop();
        _snack('You have already claimed presence for this event.');
        return;
      }
      bool inside = true;
      try {
        inside = await AdminPresenceService.isInsideBoundary(boundary);
      } catch (_) {
        inside = false;
      }
      if (boundary != null && !inside) {
        if (mounted) Navigator.of(context).pop();
        _snack('You must be within the event location to claim presence.');
        return;
      }
      progress.value = 'Recording…';
      await AppwriteService.databases.createDocument(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        documentId: ID.unique(),
        data: {
          'eventId': event.$id,
          'userId': widget.adminId,
          'status': 'present',
          'timestamp': DateTime.now().toIso8601String(),
          'isWithinGeofence': inside,
        },
      );
      if (mounted) Navigator.of(context).pop();
      _snack('Presence claimed. See you there!');
      _fetch();
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      _snack('Failed to claim: $e');
    }
  }

  // ── Map geofence picker ────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _openBoundaryPicker(
      Map<String, dynamic>? existing) async {
    LatLng pos;
    if (existing != null) {
      pos = LatLng((existing['lat'] as num).toDouble(),
          (existing['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    double radius =
        existing != null ? (existing['radiusMeters'] as num).toDouble() : 100.0;
    LatLng current = pos;
    final mapController = MapController();
    if (!mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text("Set Event Geofence",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (_, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) => setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: widget.accent.withValues(alpha: 0.18),
                              borderColor: widget.accent,
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(Icons.radio_button_checked,
                                    size: 13, color: widget.accent),
                                const SizedBox(width: 6),
                                Text("Radius: ${radius.toStringAsFixed(0)} m",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor: widget.accent,
                                    onChanged: (v) => setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx, {
                                    'lat': current.latitude,
                                    'lng': current.longitude,
                                    'radiusMeters': radius,
                                  }),
                                  child: const Text("Confirm Geofence",
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
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
        title: Text(_isHost ? "Manage Events" : "My Assigned Events",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: _isHost
          ? FloatingActionButton.extended(
              backgroundColor: widget.accent,
              foregroundColor: Colors.white,
              onPressed: () => _showEventSheet(),
              icon: const Icon(Icons.add),
              label: const Text("New Event",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
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
                        Text(_isHost ? "No events yet" : "No events assigned to you",
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black45)),
                        if (_isHost) ...[
                          const SizedBox(height: 4),
                          Text("Tap “New Event” to create one.",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
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
    final location = data['location'] as String? ?? '';
    final hasGeofence = _parseBoundary(data['boundary']) != null;
    final assignedCount =
        (data['assignedAdminIds'] as List?)?.length ?? 0;
    DateTime? date;
    try {
      date = DateTime.parse(data['date'] as String);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(
                        date != null
                            ? DateFormat('EEE, dd MMM yyyy').format(date)
                            : 'No date',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_isHost) ...[
                  IconButton(
                    icon: Icon(Icons.group_add_outlined,
                        size: 20, color: widget.accent),
                    onPressed: () => _showAssignSheet(doc),
                    tooltip: 'Assign admins',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: widget.accent),
                    onPressed: () => _showEventSheet(existing: doc),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Colors.red.shade400),
                    onPressed: () => _deleteEvent(doc),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasGeofence)
                  _chip(Icons.my_location, 'Geofenced', widget.accent),
                if (_isHost) ...[
                  if (hasGeofence) const SizedBox(width: 6),
                  _chip(Icons.groups_outlined, '$assignedCount assigned',
                      Colors.blueGrey),
                  const SizedBox(width: 6),
                  FutureBuilder<int>(
                    future: _presentCount(doc.$id),
                    builder: (_, snap) => _chip(Icons.how_to_reg,
                        '${snap.data ?? 0} present', Colors.green.shade600),
                  ),
                ],
              ],
            ),
            // Assigned mode: geofence-gated claim.
            if (!_isHost)
              FutureBuilder<models.Document?>(
                future: _myClaim(doc.$id),
                builder: (_, snap) {
                  final claimed = snap.data != null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: claimed
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle,
                                  size: 18, color: Colors.green),
                              label: const Text('Presence claimed',
                                  style: TextStyle(color: Colors.green)),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _claim(doc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.how_to_reg, size: 18),
                              label: Text(hasGeofence
                                  ? 'Claim Presence (within geofence)'
                                  : 'Claim Presence'),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
