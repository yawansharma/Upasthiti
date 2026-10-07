import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';

/// Bell icon with an unread badge. Tapping it opens the notifications inbox
/// (and marks everything read). Drop into an admin dashboard's app-bar actions.
class NotificationBell extends StatefulWidget {
  final String recipientId;
  final Color iconColor;

  const NotificationBell({
    super.key,
    required this.recipientId,
    this.iconColor = Colors.white,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final n = await NotificationService.unreadCount(widget.recipientId);
    if (mounted) setState(() => _unread = n);
  }

  Future<void> _openInbox() async {
    final items = await NotificationService.list(widget.recipientId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _InboxSheet(items: items),
    );
    // Mark all read once viewed, then refresh the badge.
    await NotificationService.markAllRead(widget.recipientId);
    _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: widget.iconColor),
          tooltip: 'Notifications',
          onPressed: _openInbox,
        ),
        if (_unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _InboxSheet extends StatelessWidget {
  final List<models.Document> items;
  const _InboxSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          Text("Notifications",
              style:
                  GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text("No notifications.",
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = items[i].data;
                  final unread = d['isRead'] == false;
                  String time = '';
                  try {
                    time = DateFormat('dd MMM, hh:mm a')
                        .format(DateTime.parse(d['timestamp'] as String));
                  } catch (_) {}
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      unread
                          ? Icons.circle_notifications
                          : Icons.notifications_none,
                      color: unread ? Colors.red : Colors.grey,
                    ),
                    title: Text(d['message'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.normal)),
                    subtitle: Text(time,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
