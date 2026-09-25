import 'package:flutter/material.dart';
import 'inbox_channel.dart';
import 'notification_kind.dart';

/// One entry in the derived notification feed (see notification_feed.dart)
/// — carries a stable [id] so [NotificationsService] can track read/unread
/// state for something that's otherwise recomputed fresh on every build,
/// never stored as its own persisted object.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final IconData icon;
  final String title;
  final String body;
  final String? time;
  final VoidCallback? onTap;
  final String? actionLabel;

  /// When this notification actually happened — the single source of truth
  /// for ordering the whole feed newest-first (see
  /// notification_feed.dart's own final sort). Every source supplies a real
  /// value: a genuine event uses its own timestamp (a status-history entry's
  /// `at`, a [FlaggedRequirement.flaggedAt]); an evergreen/contextual
  /// reminder with no real event (profile completion, a duplicate-account
  /// alert) uses a fixed, deliberately old sentinel so it naturally sorts
  /// below anything that actually happened, without being hardcoded to a
  /// specific position in the list; illustrative sample content computes a
  /// timestamp matching its own displayed relative-time text ("1 hr ago"
  /// etc.) so it sorts consistently with what it claims.
  final DateTime at;

  /// A second, distinct destination for [actionLabel] — when set, tapping
  /// the action text/arrow calls this instead of [onTap] (which the rest of
  /// the card still uses). Every existing notification leaves this null, so
  /// the action label stays exactly what it always was: a description of
  /// where the whole card already leads. Only a request-correction
  /// notification (see notification_feed.dart) sets both: [onTap] opens the
  /// request in general, [onAction] jumps straight to the one flagged
  /// requirement's own replacement uploader.
  final VoidCallback? onAction;

  /// Content chip this row belongs to. Null rows stay on All only.
  final InboxChannel? channel;

  /// Coloured kind line on the G5 tile. Null keeps [NotificationKind.badgeLabel].
  final InboxTileStyle? tile;

  /// Forces the Earlier group even when [at] falls on today's date.
  final bool earlier;

  /// Request rows. Hidden from the guest bell, and a direct open shows the
  /// guest gate instead of the landing.
  final bool personal;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    required this.at,
    this.time,
    this.onTap,
    this.actionLabel,
    this.onAction,
    this.channel,
    this.tile,
    this.earlier = false,
    this.personal = false,
  });
}
