import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/earlier_records_service.dart';
import '../../services/notifications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../applications/application_detail_screen.dart';
import '../applications/my_applications_screen.dart';
import '../home/root_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsService>().refresh());
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    await context.read<NotificationsService>().markAllRead();
    if (mounted) setState(() => _markingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsService>();
    final shown = _unreadOnly ? notifications.items.where((n) => !n.isRead).toList() : notifications.items;

    return SoftPageScaffold(
      title: 'Notifications',
      underNav: true,
      actions: [
        if (notifications.unreadCount > 0)
          _markingAll
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(onPressed: _markAllRead, child: const Text('Mark all as read')),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('${notifications.unreadCount} unread', style: SoftType.body),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SoftFilterChip(label: 'All', selected: !_unreadOnly, onTap: () => setState(() => _unreadOnly = false)),
                const SizedBox(width: 8),
                SoftFilterChip(label: 'Unread', selected: _unreadOnly, onTap: () => setState(() => _unreadOnly = true)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<NotificationsService>().refresh(),
              child: notifications.loading && notifications.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : shown.isEmpty
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, SoftPageScaffold.navClearance(context)),
                          children: [SoftEmptyCard(notifications.error ?? "You're all caught up.")],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, SoftPageScaffold.navClearance(context)),
                          itemCount: shown.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationRow(entry: shown[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationEntry entry;
  const _NotificationRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: entry.isRead ? null : SoftColors.primaryWash,
      padding: const EdgeInsets.all(16),
      onTap: () {
        if (!entry.isRead) {
          context.read<NotificationsService>().markRead(entry.id).catchError((_) {});
        }
        if (entry.applicationId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: entry.applicationId!)));
        } else if (entry.deepLink == '/applications') {
          // "Your earlier records are on your account" / "About your earlier
          // permit" (ebpco-api 069): the permits issued before eBPCO, and the
          // answers to "Find my earlier permits", are under My Applications.
          context.read<EarlierRecordsService>().refresh();
          MyApplicationsScreen.showFilter('All');
          RootShell.jumpTo(context, 1);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconTile(
            icon: entry.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_outlined,
            background: entry.isRead ? SoftColors.chipWash : SoftColors.white,
            foreground: entry.isRead ? SoftColors.muted : SoftColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: SoftType.tileTitle.copyWith(fontSize: 16, fontWeight: entry.isRead ? FontWeight.w500 : FontWeight.w600),
                      ),
                    ),
                    if (!entry.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, left: 8),
                        decoration: const BoxDecoration(color: SoftColors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.body, style: SoftType.body.copyWith(color: SoftColors.ink)),
                const SizedBox(height: 8),
                Text(notificationWhen(entry.createdAt), style: SoftType.cellLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// When a notification came, as the rest of the app writes a moment (an
/// application's history): "Nov 4, 2026 · 3:05 PM", in local time. It showed
/// the raw YYYY-MM-DD.
String notificationWhen(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : DateFormat('MMM d, yyyy · h:mm a').format(when);
}
