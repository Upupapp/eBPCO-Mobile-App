import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/notifications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../applications/application_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsService>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsService>();

    return SoftPageScaffold(
      title: 'Notifications',
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationsService>().refresh(),
        child: notifications.loading && notifications.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifications.items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    children: const [SoftEmptyCard("You're all caught up.")],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    itemCount: notifications.items.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationRow(entry: notifications.items[i]),
                    ),
                  ),
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
      onTap: () async {
        if (!entry.isRead) {
          await context.read<NotificationsService>().markRead(entry.id);
        }
        if (entry.applicationId != null && context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: entry.applicationId!)));
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
                Text(entry.createdAt.substring(0, 10), style: SoftType.cellLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
