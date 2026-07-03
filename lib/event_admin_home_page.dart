import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'main.dart';
import 'services/appwrite_service.dart';

const Color _kEAAccent = Color(0xFF3D6B8A);
const _kDb = '6a2c10dc000d5e50f314';

class EventAdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;

  const EventAdminHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
  });

  @override
  State<EventAdminHomePage> createState() => _EventAdminHomePageState();
}

class _EventAdminHomePageState extends State<EventAdminHomePage> {
  int _selectedTab = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _EventsTab(adminId: widget.adminId),
      _KioskTab(adminId: widget.adminId),
      _TrackingTab(adminId: widget.adminId),
    ];
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kEAAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Event Admin", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(widget.adminName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  child: IndexedStack(
                    index: _selectedTab,
                    children: _tabs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kEAAccent,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), activeIcon: Icon(Icons.event_note), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.app_registration), activeIcon: Icon(Icons.app_registration), label: "Kiosk"),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check), label: "Tracking"),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Events
// ─────────────────────────────────────────────────────────────────────────────
class _EventsTab extends StatefulWidget {
  final String adminId;
  const _EventsTab({required this.adminId});
  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  List<models.Document> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'events',
        queries: [Query.equal('createdBy', widget.adminId), Query.orderDesc('date'), Query.limit(100)],
      );
      if (mounted) setState(() { _events = res.documents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateEvent() {
    final titleCtrl = TextEditingController();
    DateTime date = DateTime.now();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("New Event", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(date)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setSheet(() => date = picked);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (titleCtrl.text.isEmpty) return;
                    setSheet(() => saving = true);
                    try {
                      await AppwriteService.databases.createDocument(
                        databaseId: _kDb,
                        collectionId: 'events',
                        documentId: ID.unique(),
                        data: {
                          'title': titleCtrl.text,
                          'date': date.toIso8601String(),
                          'createdBy': widget.adminId,
                        },
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchEvents();
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e")));
                      setSheet(() => saving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent, foregroundColor: Colors.white),
                  child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text("Create"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Events", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showCreateEvent,
                icon: const Icon(Icons.add),
                label: const Text("New"),
                style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator(color: _kEAAccent))
            : _events.isEmpty ? const Center(child: Text("No events found. Create one!"))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _events.length,
                itemBuilder: (ctx, i) {
                  final d = _events[i].data;
                  return Card(
                    child: ListTile(
                      title: Text(d['title'] as String? ?? 'Untitled'),
                      subtitle: Text(d['date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(d['date'])) : ''),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Kiosk Self-Service Registration
// ─────────────────────────────────────────────────────────────────────────────
class _KioskTab extends StatefulWidget {
  final String adminId;
  const _KioskTab({required this.adminId});
  @override
  State<_KioskTab> createState() => _KioskTabState();
}

class _KioskTabState extends State<_KioskTab> {
  List<models.Document> _events = [];
  models.Document? _selectedEvent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'events',
        queries: [Query.equal('createdBy', widget.adminId), Query.orderDesc('date'), Query.limit(100)],
      );
      if (mounted) setState(() { _events = res.documents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterKioskMode() {
    if (_selectedEvent == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _KioskRegistrationScreen(event: _selectedEvent!)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kEAAccent));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Self-Service Registration", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Select an event and enter Kiosk Mode to allow students to register themselves on this device.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          DropdownButtonFormField<models.Document>(
            value: _selectedEvent,
            decoration: const InputDecoration(labelText: "Select Event", border: OutlineInputBorder()),
            items: _events.map((e) => DropdownMenuItem(value: e, child: Text(e.data['title'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedEvent = v),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedEvent == null ? null : _enterKioskMode,
              icon: const Icon(Icons.fullscreen),
              label: const Padding(padding: EdgeInsets.all(16), child: Text("Enter Kiosk Mode", style: TextStyle(fontSize: 16))),
              style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

class _KioskRegistrationScreen extends StatefulWidget {
  final models.Document event;
  const _KioskRegistrationScreen({required this.event});
  @override
  State<_KioskRegistrationScreen> createState() => _KioskRegistrationScreenState();
}

class _KioskRegistrationScreenState extends State<_KioskRegistrationScreen> {
  final _idCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final userId = _idCtrl.text.trim();
    if (userId.isEmpty) return;

    setState(() => _loading = true);
    try {
      // Create registration
      await AppwriteService.databases.createDocument(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        documentId: ID.unique(),
        data: {
          'eventId': widget.event.$id,
          'userId': userId,
          'status': 'registered',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully registered!"), backgroundColor: Colors.green));
        _idCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.data['title'] ?? 'Event Registration'),
        backgroundColor: _kEAAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.app_registration, size: 100, color: _kEAAccent),
              const SizedBox(height: 24),
              Text("Self-Service Registration", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                  labelText: "Enter your Student ID",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(20)),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Register Now", style: TextStyle(fontSize: 20)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Tracking
// ─────────────────────────────────────────────────────────────────────────────
class _TrackingTab extends StatefulWidget {
  final String adminId;
  const _TrackingTab({required this.adminId});
  @override
  State<_TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<_TrackingTab> {
  List<models.Document> _events = [];
  models.Document? _selectedEvent;
  List<models.Document> _registrations = [];
  bool _loadingEvents = true;
  bool _loadingRegs = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'events',
        queries: [Query.equal('createdBy', widget.adminId), Query.orderDesc('date'), Query.limit(100)],
      );
      if (mounted) setState(() { _events = res.documents; _loadingEvents = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _fetchRegistrations() async {
    if (_selectedEvent == null) return;
    setState(() => _loadingRegs = true);
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        queries: [Query.equal('eventId', _selectedEvent!.$id), Query.limit(500)],
      );
      if (mounted) setState(() { _registrations = res.documents; _loadingRegs = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRegs = false);
    }
  }

  Future<void> _markAttended(models.Document reg) async {
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: _kDb,
        collectionId: 'event_registrations',
        documentId: reg.$id,
        data: {'status': 'attended'},
      );
      _fetchRegistrations();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEvents) return const Center(child: CircularProgressIndicator(color: _kEAAccent));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Participation Tracking", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<models.Document>(
                value: _selectedEvent,
                decoration: const InputDecoration(labelText: "Select Event", border: OutlineInputBorder()),
                items: _events.map((e) => DropdownMenuItem(value: e, child: Text(e.data['title'] ?? ''))).toList(),
                onChanged: (v) {
                  setState(() => _selectedEvent = v);
                  _fetchRegistrations();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedEvent == null
            ? const Center(child: Text("Select an event above"))
            : _loadingRegs
              ? const Center(child: CircularProgressIndicator(color: _kEAAccent))
              : _registrations.isEmpty
                ? const Center(child: Text("No registrations yet."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _registrations.length,
                    itemBuilder: (ctx, i) {
                      final reg = _registrations[i];
                      final isAttended = reg.data['status'] == 'attended';
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.person, color: isAttended ? Colors.green : Colors.grey),
                          title: Text("Student: ${reg.data['userId']}"),
                          subtitle: Text("Status: ${reg.data['status']}"),
                          trailing: isAttended 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => _markAttended(reg),
                                style: ElevatedButton.styleFrom(backgroundColor: _kEAAccent, foregroundColor: Colors.white),
                                child: const Text("Mark Attended"),
                              ),
                        ),
                      );
                    },
                  ),
        )
      ],
    );
  }
}
