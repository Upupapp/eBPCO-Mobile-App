import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The visual-hierarchy tier for a notification — every kind pairs a
/// color with its own icon/label (never color alone), per the
/// notifications spec's "do not rely solely on color" requirement.
enum NotificationKind { info, actionRequired, success, warning, urgent }

extension NotificationKindX on NotificationKind {
  String get badgeLabel => switch (this) {
        NotificationKind.info => 'Info',
        NotificationKind.actionRequired => 'Action Required',
        NotificationKind.success => 'Approved',
        NotificationKind.warning => 'Warning',
        NotificationKind.urgent => 'Urgent',
      };

  IconData get badgeIcon => switch (this) {
        NotificationKind.info => Icons.info_outline_rounded,
        NotificationKind.actionRequired => Icons.arrow_forward_rounded,
        NotificationKind.success => Icons.check_circle_outline_rounded,
        NotificationKind.warning => Icons.warning_amber_rounded,
        NotificationKind.urgent => Icons.priority_high_rounded,
      };

  Color get foreground => switch (this) {
        NotificationKind.info => AppColors.indigo700,
        NotificationKind.actionRequired => AppColors.amber700,
        NotificationKind.success => AppColors.emerald700,
        NotificationKind.warning => AppColors.orange700,
        NotificationKind.urgent => AppColors.rose700,
      };

  Color get background => switch (this) {
        NotificationKind.info => AppColors.indigo50,
        NotificationKind.actionRequired => AppColors.amber50,
        NotificationKind.success => AppColors.emerald50,
        NotificationKind.warning => AppColors.orange50,
        NotificationKind.urgent => AppColors.rose50,
      };
}
