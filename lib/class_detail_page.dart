import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// Appwrite imports
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'community_page.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;
  final Map<String, dynamic>? boundary;
  final String username;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
    this.boundary,
    required this.username,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  bool _isReporting = false;
  String? _lastUploadError;

  bool get _hasBoundary =>
      widget.boundary != null &&
      widget.boundary!['lat'] != null &&
      widget.boundary!['lng'] != null &&
      widget.boundary!['radiusMeters'] != null;

  Future<bool> _checkGeofence() async {
    if (!_hasBoundary) return true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double boundaryLat = (widget.boundary!['lat'] as num).toDouble();
    final double boundaryLng = (widget.boundary!['lng'] as num).toDouble();
    final double radiusMeters = (widget.boundary!['radiusMeters'] as num)
        .toDouble();

    final double distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      boundaryLat,
      boundaryLng,
    );

    return distance <= radiusMeters;
  }

  static String get _verifyFaceEndpoint => '${AppwriteService.mlBackendBase}/login-face';

  Future<String?> _verifyFace(File photo) async {
    const maxAttempts = 3;
    const initialDelay = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(_verifyFaceEndpoint),
        );
        request.fields['username'] = widget.username;
        request.files.add(await http.MultipartFile.fromPath('image', photo.path));
        
        if (mounted && attempt > 1) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI model warming up… Retry $attempt/$maxAttempts'),
            duration: const Duration(seconds: 2),
          ));
        }

        final streamed = await request.send().timeout(const Duration(seconds: 60));
        final body = await streamed.stream.bytesToString();
        
        // If it's a 5xx (server cold start), retry
        if (streamed.statusCode >= 500 && attempt < maxAttempts) {
          await Future.delayed(initialDelay * attempt);
          continue;
        }

        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          if (decoded['verified'] == true) return null;
          return decoded['error'] as String? ?? 'Face not recognised.';
        } catch (_) {
          return 'Face verification failed (status ${streamed.statusCode}).';
        }
      } catch (e) {
        if (attempt < maxAttempts) {
          await Future.delayed(initialDelay * attempt);
          continue;
        }
        return 'Could not reach the server. Please check your connection.';
      }
    }
    return "Face verification failed after $maxAttempts attempts.";
  }

  Future<String?> _uploadPhoto(File photo) async {
    try {
      final fileId = ID.unique();
      final file = await AppwriteService.storage.createFile(
        bucketId: AppwriteService.attendancePhotosBucket,
        fileId: fileId,
        file: InputFile.fromPath(
          path: photo.path,
          filename:
              '${widget.username}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      _lastUploadError = null;
      return "${AppwriteService.endpoint}/storage/buckets/${AppwriteService.attendancePhotosBucket}/files/${file.$id}/view?project=${AppwriteService.projectId}";
    } catch (e) {
      _lastUploadError = e.toString();
      return null;
    }
  }

  Map<String, dynamic>? _getActivePeriod(List<models.Document> periodDocs) {
    final now = DateTime.now();
    for (var doc in periodDocs) {
      final data = doc.data;
      if (data['startTime'] == null || data['endTime'] == null) continue;

      final realStart = DateTime.parse(data['startTime']);
      final realEnd = DateTime.parse(data['endTime']);

      final start = realStart.subtract(const Duration(minutes: 10));
      final end = realEnd.add(const Duration(minutes: 10));

      if (now.isAfter(start) && now.isBefore(end)) {
        return {'id': doc.$id, ...data};
      }
    }
    return null;
  }

  Future<void> _reportAttendance(Map<String, dynamic> activePeriod) async {
    if (_isReporting) return;

    if (_hasBoundary) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_off_outlined, color: Colors.red),
                SizedBox(width: 10),
                Text("Location Required"),
              ],
            ),
            content: const Text(
              "This class requires you to be within the boundary to report attendance. Please enable location services and try again.",
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }
    }

    setState(() => _isReporting = true);
    final statusNotifier = ValueNotifier("Checking your location...");

    try {
      _showProgressDialog(statusNotifier);

      bool isWithinGeofence = false;
      bool geofenceCheckErrored = false;
      try {
        isWithinGeofence = await _checkGeofence();
      } catch (_) {
        isWithinGeofence = false;
        geofenceCheckErrored = true;
      }

      if (_hasBoundary && !isWithinGeofence) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar(
          geofenceCheckErrored
              ? "Couldn't verify your location. Check GPS/location permissions and try again."
              : "You are outside the class boundary. Move closer and try again.",
        );
        setState(() => _isReporting = false);
        return;
      }

      statusNotifier.value = "Opening camera...";
      File? photo;
      if (!Platform.isWindows) {
        final XFile? picked = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 85,
        );
        if (picked != null) photo = File(picked.path);
      } else {
        final XFile? picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) photo = File(picked.path);
      }

      if (photo == null) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar("Photo is required to report attendance.");
        setState(() => _isReporting = false);
        return;
      }

      statusNotifier.value = "Verifying your face...";
      final faceError = await _verifyFace(photo);
      if (faceError != null) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar("Face verification failed: $faceError");
        setState(() => _isReporting = false);
        return;
      }

      statusNotifier.value = "Uploading photo...";
      final photoUrl = await _uploadPhoto(photo);

      statusNotifier.value = "Saving record...";
      final now = DateTime.now();
      final realStart = DateTime.parse(activePeriod['startTime']);
      final realEnd = DateTime.parse(activePeriod['endTime']);

      String entryStatus = "Within Window";
      if (now.isBefore(realStart)) {
        entryStatus = "Early Window";
      } else if (now.isAfter(realEnd)) {
        entryStatus = "Late Window";
      }

      final classDoc = await AppwriteService.databases.getDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'classes',
        documentId: widget.classId,
      );
      final adminId =
          classDoc.data['createdBy'] ?? classDoc.data['adminId'] ?? '';

      await AppwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'attendance_logs',
        documentId: ID.unique(),
        data: {
          'userId': widget.username,
          'classId': widget.classId,
          'adminId': adminId,
          'periodId': activePeriod['id'],
          'className': widget.className,
          'timestamp': DateTime.now().toIso8601String(),
          'photoUrl': photoUrl ?? '',
          'isWithinGeofence': isWithinGeofence,
          'isVerified': false,
          'adminVerifiedStatus': isWithinGeofence ? 'Present' : 'Pending',
          'entryStatus': entryStatus,
          'verifiedBy': '',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {}); // Refresh the FutureBuilders
        if (photoUrl == null) {
          _showSnackBar(
              "Attendance saved, but photo upload failed: ${_lastUploadError ?? 'unknown error'}");
        }
        _showSuccessTicket(isWithinGeofence, entryStatus, activePeriod);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      _showSnackBar("Something went wrong: $e");
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  void _showSuccessTicket(
    bool inZone,
    String entryStatus,
    Map<String, dynamic> period,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.kGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Session ID: ${period['id'].toString().toUpperCase()}",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Attendance Logged", style: AppTheme.sectionTitle),
                    const SizedBox(height: 24),
                    _ticketRow("Class", widget.className),
                    _ticketRow(
                      "Date",
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                    ),
                    _ticketRow("Window", entryStatus),
                    _ticketRow("Geofence", inZone ? "VERIFIED" : "OUTSIDE"),
                    const SizedBox(height: 24),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F4F2),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      inZone
                          ? "Your attendance has been sent for admin verification."
                          : "Reported outside boundary. Admin will manually review your status.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Done"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog(ValueNotifier<String> statusNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: statusNotifier,
            builder: (_, value, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.kGreen),
                const SizedBox(height: 24),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please keep the app open during this process.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person, color: Colors.grey),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Hero(
          tag: 'class_header_${widget.classId}',
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.classId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: "Community",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityPage(
                  classId: widget.classId,
                  className: widget.className,
                  username: widget.username,
                  isAdmin: false,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<models.DocumentList>(
            future: AppwriteService.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: 'attendance_logs',
              queries: [
                Query.equal('userId', widget.username),
                Query.equal('classId', widget.classId),
              ],
            ),
            builder: (context, snapshot) {
              String statusLabel = "Not Reported Today";
              Color statusColor = Colors.grey.shade500;
              IconData statusIcon = Icons.radio_button_unchecked;

              if (snapshot.hasData && snapshot.data!.documents.isNotEmpty) {
                final todayDocs = snapshot.data!.documents.where((doc) {
                  final ts = doc.data['timestamp'] as String?;
                  if (ts == null) return false;
                  final d = DateTime.parse(ts);
                  return d.isAfter(startOfDay) && d.isBefore(endOfDay);
                }).toList();

                if (todayDocs.isNotEmpty) {
                  todayDocs.sort((a, b) {
                    final tsA = DateTime.parse(a.data['timestamp']);
                    final tsB = DateTime.parse(b.data['timestamp']);
                    return tsB.compareTo(tsA);
                  });
                  final log = todayDocs.first.data;
                  final adminStatus =
                      log['adminVerifiedStatus'] as String? ?? 'Pending';

                  if (adminStatus == 'Present') {
                    statusLabel = "Verified Present";
                    statusColor = const Color(0xFF6A8A73);
                    statusIcon = Icons.check_circle;
                  } else if (adminStatus == 'Late') {
                    statusLabel = "Verified Late";
                    statusColor = Colors.orange;
                    statusIcon = Icons.access_time_filled;
                  } else if (adminStatus == 'Absent') {
                    statusLabel = "Marked Absent";
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                  } else {
                    statusLabel = "Pending Verification";
                    statusColor = Colors.orange;
                    statusIcon = Icons.hourglass_top_rounded;
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Last Period Status",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Text(
                        "Attendance History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<models.DocumentList>(
                        future: AppwriteService.databases.listDocuments(
                          databaseId: AppwriteService.databaseId,
                          collectionId: 'periods',
                          queries: [
                            Query.equal('classId', widget.classId),
                            Query.orderDesc('startTime'),
                          ],
                        ),
                        builder: (context, periodSnap) {
                          if (!periodSnap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6A8A73),
                              ),
                            );
                          final periods = periodSnap.data!.documents;

                          if (periods.isEmpty)
                            return const Center(
                              child: Text(
                                "No periods scheduled yet.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );

                          return FutureBuilder<models.DocumentList>(
                            future: AppwriteService.databases.listDocuments(
                              databaseId: AppwriteService.databaseId,
                              collectionId: 'attendance_logs',
                              queries: [
                                Query.equal('userId', widget.username),
                                Query.equal('classId', widget.classId),
                              ],
                            ),
                            builder: (context, logSnap) {
                              if (!logSnap.hasData)
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6A8A73),
                                  ),
                                );

                              // Map logs by periodId Ã¢â‚¬â€ keep most recent if duplicates exist
                              Map<String, Map<String, dynamic>> logMap = {};
                              for (var log in logSnap.data!.documents) {
                                final data = log.data;
                                final pId = data['periodId'] as String?;
                                if (pId == null) continue;
                                final existing = logMap[pId];
                                if (existing == null) {
                                  logMap[pId] = data;
                                } else {
                                  final existingTsStr =
                                      existing['timestamp'] as String?;
                                  final newTsStr = data['timestamp'] as String?;
                                  if (newTsStr != null) {
                                    if (existingTsStr == null ||
                                        DateTime.parse(newTsStr).compareTo(
                                              DateTime.parse(existingTsStr),
                                            ) >
                                            0) {
                                      logMap[pId] = data;
                                    }
                                  }
                                }
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 0,
                                  right: 16,
                                  bottom: 100,
                                ),
                                itemCount: periods.length,
                                itemBuilder: (context, index) {
                                  final period = periods[index];
                                  final pData = period.data;
                                  final logData = logMap[period.$id];

                                  final startTs = pData['startTime'] != null
                                      ? DateTime.parse(pData['startTime'])
                                      : null;
                                  final endTs = pData['endTime'] != null
                                      ? DateTime.parse(pData['endTime'])
                                      : null;
                                  final String timeStr =
                                      (startTs != null && endTs != null)
                                      ? "${DateFormat('hh:mm a').format(startTs)} - ${DateFormat('hh:mm a').format(endTs)}"
                                      : "Unknown Time";
                                  final String dateStr = pData['date'] ?? "";

                                  String adminStatus = "Not Reported";
                                  String entryStatus = "";
                                  bool isWithinGeofence = false;
                                  String photoUrl = "";

                                  if (logData != null) {
                                    adminStatus =
                                        logData['adminVerifiedStatus']
                                            as String? ??
                                        'Pending';
                                    entryStatus =
                                        logData['entryStatus'] as String? ?? '';
                                    isWithinGeofence =
                                        logData['isWithinGeofence'] == true;
                                    photoUrl =
                                        logData['photoUrl'] as String? ?? '';
                                  } else {
                                    final realStart = startTs;
                                    if (realStart != null &&
                                        DateTime.now().isBefore(
                                          realStart.subtract(
                                            const Duration(minutes: 10),
                                          ),
                                        )) {
                                      adminStatus = "Upcoming";
                                    } else if (endTs != null &&
                                        DateTime.now().isAfter(
                                          endTs.add(
                                            const Duration(minutes: 10),
                                          ),
                                        )) {
                                      adminStatus = "Missing";
                                    } else {
                                      adminStatus = "Pending Action";
                                    }
                                  }

                                  Color adminColor = Colors.grey;
                                  IconData adminIcon = Icons.help_outline;
                                  if (adminStatus == 'Present') {
                                    adminColor = const Color(0xFF6A8A73);
                                    adminIcon = Icons.verified;
                                  } else if (adminStatus == 'Late') {
                                    adminColor = Colors.orange;
                                    adminIcon = Icons.access_time_filled;
                                  } else if (adminStatus == 'Absent') {
                                    adminColor = Colors.red;
                                    adminIcon = Icons.cancel;
                                  } else if (adminStatus == 'Upcoming') {
                                    adminColor = Colors.blue;
                                    adminIcon = Icons.calendar_today;
                                  } else if (adminStatus == 'Missing') {
                                    adminColor = Colors.orange;
                                    adminIcon = Icons.warning_amber_rounded;
                                  } else if (adminStatus == 'Pending' ||
                                      adminStatus == 'Pending Action') {
                                    adminColor = Colors.orangeAccent;
                                    adminIcon = Icons.hourglass_top_rounded;
                                  }

                                  Widget photoWidget = photoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            photoUrl,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, e, s) =>
                                                _photoPlaceholder(),
                                          ),
                                        )
                                      : _photoPlaceholder();

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                    color: Colors.grey.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          photoWidget,
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "$dateStr | $timeStr",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (entryStatus.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    entryStatus,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    if (logData != null) ...[
                                                      _StatusBadge(
                                                        label: isWithinGeofence
                                                            ? "In Zone"
                                                            : "Out of Zone",
                                                        color: isWithinGeofence
                                                            ? Colors.green
                                                            : Colors.red,
                                                        icon: isWithinGeofence
                                                            ? Icons.location_on
                                                            : Icons
                                                                  .location_off,
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    _StatusBadge(
                                                      label: adminStatus,
                                                      color: adminColor,
                                                      icon: adminIcon,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<models.DocumentList>(
        future: AppwriteService.databases.listDocuments(
          databaseId: AppwriteService.databaseId,
          collectionId: 'periods',
          queries: [Query.equal('classId', widget.classId)],
        ),
        builder: (context, periodSnap) {
          if (!periodSnap.hasData) return const SizedBox.shrink();
          final activePeriod = _getActivePeriod(periodSnap.data!.documents);

          if (activePeriod == null)
            return SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.block),
                label: const Text(
                  "No Active Session",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            );

          return FutureBuilder<models.DocumentList>(
            future: AppwriteService.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: 'attendance_logs',
              queries: [
                Query.equal('userId', widget.username),
                Query.equal('periodId', activePeriod['id']),
              ],
            ),
            builder: (context, logSnap) {
              final bool alreadyReported =
                  logSnap.hasData && logSnap.data!.documents.isNotEmpty;
              return SizedBox(
                width: MediaQuery.of(context).size.width - 40,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: alreadyReported || _isReporting
                      ? null
                      : () => _reportAttendance(activePeriod),
                  icon: Icon(
                    alreadyReported ? Icons.check_circle : Icons.camera_alt,
                  ),
                  label: Text(
                    alreadyReported
                        ? "Reported for this Period"
                        : "Report Attendance",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A8A73),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


