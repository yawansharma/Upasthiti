import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appwrite/models.dart' as models;
import '../app_theme.dart';
import '../services/distribution_service.dart';

class UserQrPage extends StatefulWidget {
  final String username;
  final String name;

  const UserQrPage({super.key, required this.username, required this.name});

  @override
  State<UserQrPage> createState() => _UserQrPageState();
}

class _UserQrPageState extends State<UserQrPage> {
  List<Map<String, dynamic>> _activeEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyEvents();
  }

  Future<void> _loadMyEvents() async {
    try {
      final entries =
          await DistributionService.getMyRecipientEntries(widget.username);
      final activeList = <Map<String, dynamic>>[];

      for (final entry in entries.documents) {
        final status = entry.data['status'] as String? ?? '';
        if (status == 'pending' || status == 'issued') {
          final eventId = entry.data['eventId'] as String;
          try {
            final event = await DistributionService.getEventById(eventId);
            if (event.data['status'] == 'active') {
              activeList.add({'entry': entry, 'event': event});
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _activeEvents = activeList;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acknowledge(String recipientDocId) async {
    try {
      await DistributionService.acknowledgeReceipt(recipientDocId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt acknowledged. Thank you!")),
      );
      _loadMyEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = DistributionService.encodeQr(widget.username);

    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text("My QR Code",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.kGreen))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            AppTheme.sheetHandle,
                            const SizedBox(height: 16),
                            Text(
                              "Show this to the admin to receive your package",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 220,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF6A8A73),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    widget.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    widget.username,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (_activeEvents.isNotEmpty) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "ACTIVE PACKAGES",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._activeEvents.map((item) {
                                final entry =
                                    item['entry'] as models.Document;
                                final event =
                                    item['event'] as models.Document;
                                final status =
                                    entry.data['status'] as String? ??
                                        'pending';
                                final isIssued = status == 'issued';

                                return Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isIssued
                                        ? AppTheme.kGreen
                                            .withValues(alpha: 0.07)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isIssued
                                          ? AppTheme.kGreen
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isIssued
                                            ? Icons.inventory_2_outlined
                                            : Icons.pending_outlined,
                                        color: isIssued
                                            ? AppTheme.kGreen
                                            : Colors.orange,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.data['title']
                                                      as String? ??
                                                  'Event',
                                              style: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              isIssued
                                                  ? "Tap 'Got it' after collecting"
                                                  : "Awaiting distribution",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors
                                                      .grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isIssued)
                                        TextButton(
                                          onPressed: () =>
                                              _acknowledge(entry.$id),
                                          child: const Text(
                                            "Got it",
                                            style: TextStyle(
                                              color: AppTheme.kGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ] else ...[
                              Icon(Icons.qr_code_2,
                                  size: 48,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(
                                "No active distribution events",
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


