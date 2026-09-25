import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<NotificationsService>().refresh(),
          child: notifications.loading && notifications.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notifications.items.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Text("You're all caught up.", style: AppTypography.body, textAlign: TextAlign.center),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24),
                      itemCount: notifications.items.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationRow(entry: notifications.items[i]),
                      ),
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
      color: entry.isRead ? AppColors.surface : AppColors.primary50,
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
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: entry.isRead ? Colors.transparent : AppColors.primary500, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(entry.body, style: AppTypography.body),
                const SizedBox(height: 6),
                Text(entry.createdAt.substring(0, 10), style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
