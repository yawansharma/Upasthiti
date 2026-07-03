import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/appwrite_service.dart';
import 'components/user_avatar.dart';

// =============================================================================
// CommunityPage Ã¢â‚¬â€ two tabs: Channel + Direct Messages
//
// Appwrite collection: community_messages
//   Fields: classId (string), channel (string), senderId (string),
//           text (string), fileUrl (string), fileType (string),
//           fileName (string), timestamp (string ISO-8601), isAdmin (bool)
//
// Storage bucket: community_files
// =============================================================================
class CommunityPage extends StatelessWidget {
  final String classId;
  final String className;
  final String username;
  final bool isAdmin;
  final List<String> studentIds;

  const CommunityPage({
    super.key,
    required this.classId,
    required this.className,
    required this.username,
    required this.isAdmin,
    this.studentIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF101010),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Community",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white)),
              Text(className,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white60)),
            ],
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.kGreen,
            indicatorWeight: 3,
            labelColor: AppTheme.kGreen,
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: "CHANNEL"),
              Tab(text: "DIRECT MESSAGES"),
            ],
          ),
        ),
        body: RisingSheet(
          child: TabBarView(
            children: [
              // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 0: Public class channel Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
              _ChatView(
                classId: classId,
                channel: 'channel',
                username: username,
                isAdmin: isAdmin,
                showSenderName: true,
              ),
              // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 1: Direct Messages Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
              isAdmin
                  ? _AdminDmListTab(
                      classId: classId,
                      adminName: username,
                      studentIds: studentIds,
                    )
                  : _ChatView(
                      classId: classId,
                      channel: 'dm_$username',
                      username: username,
                      isAdmin: false,
                      showSenderName: false,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Generic chat view Ã¢â‚¬â€ reused for channel and student DM
// =============================================================================
class _ChatView extends StatefulWidget {
  final String classId;
  final String channel;
  final String username;
  final bool isAdmin;
  final bool showSenderName;

  const _ChatView({
    required this.classId,
    required this.channel,
    required this.username,
    required this.isAdmin,
    required this.showSenderName,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  bool _loading = true;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _sub = AppwriteService.realtime.subscribe(
        ['databases.main_db.collections.community_messages.documents']);
    _sub!.stream.listen((event) {
      final payload = event.payload;
      if (payload['classId'] == widget.classId &&
          payload['channel'] == widget.channel) {
        if (mounted) _fetchMessages();
      }
    });
  }

  @override
  void dispose() {
    _sub?.close();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: 'community_messages',
        queries: [
          Query.equal('classId', widget.classId),
          Query.equal('channel', widget.channel),
          Query.orderAsc('timestamp'),
          Query.limit(200),
        ],
      );
      if (mounted) {
        setState(() {
          _messages = result.documents
              .map((d) => {'_id': d.$id, ...d.data})
              .toList();
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await AppwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'community_messages',
        documentId: ID.unique(),
        data: {
          'classId': widget.classId,
          'channel': widget.channel,
          'senderId': widget.username,
          'text': text,
          'fileUrl': '',
          'fileType': '',
          'fileName': '',
          'timestamp': DateTime.now().toIso8601String(),
          'isAdmin': widget.isAdmin,
        },
      );
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Send failed: $e")));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _attach() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'csv', 'doc', 'docx', 'xls', 'xlsx',
        'png', 'jpg', 'jpeg', 'gif', 'txt',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    setState(() => _sending = true);
    try {
      final fileId = ID.unique();
      final uploaded = await AppwriteService.storage.createFile(
        bucketId: 'community_files',
        fileId: fileId,
        file: InputFile.fromPath(
          path: file.path!,
          filename: file.name,
        ),
      );
      final url =
          '${AppwriteService.endpoint}/storage/buckets/community_files'
          '/files/${uploaded.$id}/view?project=${AppwriteService.projectId}';

      await AppwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: 'community_messages',
        documentId: ID.unique(),
        data: {
          'classId': widget.classId,
          'channel': widget.channel,
          'senderId': widget.username,
          'text': '',
          'fileUrl': url,
          'fileType': file.extension?.toLowerCase() ?? '',
          'fileName': file.name,
          'timestamp': DateTime.now().toIso8601String(),
          'isAdmin': widget.isAdmin,
        },
      );
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.kGreen))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet.\nStart the conversation!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final data = _messages[i];
                          final isMine =
                              data['senderId'] == widget.username;
                          return _MessageBubble(
                            data: data,
                            isMine: isMine,
                            showSenderName: widget.showSenderName,
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          _InputBar(
            ctrl: _ctrl,
            onSend: _send,
            onAttach: _attach,
            sending: _sending,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Admin DM list Ã¢â‚¬â€ lists enrolled students, tap to open thread
// =============================================================================
class _AdminDmListTab extends StatelessWidget {
  final String classId;
  final String adminName;
  final List<String> studentIds;

  const _AdminDmListTab({
    required this.classId,
    required this.adminName,
    required this.studentIds,
  });

  @override
  Widget build(BuildContext context) {
    if (studentIds.isEmpty) {
      return Container(
        color: Colors.white,
        child: const Center(
            child: Text("No students enrolled.",
                style: TextStyle(color: Colors.grey))),
      );
    }
    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: studentIds.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, i) {
          final studentId = studentIds[i];
          return FutureBuilder<models.Document>(
            future: AppwriteService.databases.getDocument(
              databaseId: AppwriteService.databaseId,
              collectionId: 'users',
              documentId: studentId,
            ),
            builder: (context, snap) {
              String name = studentId;
              String? profilePic;
              if (snap.hasData) {
                name = snap.data!.data['name'] as String? ?? studentId;
                profilePic = snap.data!.data['profilePictureId'] as String?;
              }
              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: UserAvatar(
                    profilePictureId: profilePic,
                    fallbackName: name,
                    radius: 22,
                    backgroundColor: AppTheme.kGreen.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.kGreen,
                  ),
                  title: Text(name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("@$studentId",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade300, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _DmThreadPage(
                        classId: classId,
                        studentId: studentId,
                        studentName: name,
                        adminName: adminName,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// Full-screen DM thread page Ã¢â‚¬â€ admin navigates here
// =============================================================================
class _DmThreadPage extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String adminName;

  const _DmThreadPage({
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(studentId,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
      body: _ChatView(
        classId: classId,
        channel: 'dm_$studentId',
        username: adminName,
        isAdmin: true,
        showSenderName: false,
      ),
    );
  }
}

// =============================================================================
// Message bubble
// =============================================================================
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMine;
  final bool showSenderName;

  const _MessageBubble(
      {required this.data,
      required this.isMine,
      required this.showSenderName});

  @override
  Widget build(BuildContext context) {
    final text = data['text'] as String? ?? '';
    final fileUrl = data['fileUrl'] as String? ?? '';
    final fileType = data['fileType'] as String? ?? '';
    final fileName = data['fileName'] as String? ?? '';
    final senderId = data['senderId'] as String? ?? '';
    final isAdmin = data['isAdmin'] == true;
    final tsStr = data['timestamp'] as String?;
    final timeStr = tsStr != null
        ? DateFormat('hh:mm a').format(DateTime.parse(tsStr))
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMine)
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(senderId,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kGreen)),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: AppTheme.kGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text("Admin",
                          style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.kGreen,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isAdmin
                      ? AppTheme.kGreen.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
                  child: Text(
                    senderId.isNotEmpty ? senderId[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 11,
                        color: isAdmin
                            ? AppTheme.kGreen
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMine
                        ? const LinearGradient(
                            colors: [
                              AppTheme.kGreen,
                              Color(0xFF5A7A63)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMine ? null : const Color(0xFFF1F4F2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMine ? 20 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 20),
                    ),
                    boxShadow: [
                      if (isMine)
                        BoxShadow(
                          color: AppTheme.kGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (text.isNotEmpty)
                        Text(text,
                            style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14)),
                      if (fileUrl.isNotEmpty)
                        _FileAttachment(
                          fileUrl: fileUrl,
                          fileType: fileType,
                          fileName: fileName,
                          isMine: isMine,
                        ),
                      const SizedBox(height: 4),
                      Text(timeStr,
                          style: TextStyle(
                              fontSize: 10,
                              color: isMine
                                  ? Colors.white70
                                  : Colors.grey)),
                    ],
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// File attachment widget
// =============================================================================
class _FileAttachment extends StatelessWidget {
  final String fileUrl;
  final String fileType;
  final String fileName;
  final bool isMine;

  const _FileAttachment({
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    required this.isMine,
  });

  bool get _isImage =>
      ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(fileType);

  IconData get _fileIcon {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'csv':
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get _fileColor {
    switch (fileType) {
      case 'pdf':
        return Colors.red;
      case 'csv':
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'doc':
      case 'docx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return GestureDetector(
        onTap: _openUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fileUrl,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_fileIcon,
                color: isMine ? Colors.white : _fileColor, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMine ? Colors.white : Colors.black87),
                  ),
                  Text("Tap to open",
                      style: TextStyle(
                          fontSize: 10,
                          color: isMine ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Input bar
// =============================================================================
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool sending;

  const _InputBar({
    required this.ctrl,
    required this.onSend,
    required this.onAttach,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppTheme.kGreen),
            onPressed: sending ? null : onAttach,
            tooltip: "Attach file",
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              maxLength: 1000,
              buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.kGreen),
                  ))
              : GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppTheme.kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send,
                        color: Colors.white, size: 18),
                  ),
                ),
        ],
      ),
    );
  }
}


