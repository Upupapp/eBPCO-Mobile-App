import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../models/inbox_channel.dart';
import '../models/notification_kind.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../screens/notifications/duplicate_account_details_screen.dart';
import '../screens/notifications/unverified_duplicate_resolution_screen.dart';
import '../screens/profile/resident_profile/resident_profile_overview_screen.dart';
import '../screens/notifications/g5/g5_samples.dart';
import '../screens/shared/request_detail_screen.dart';
import 'citizen_session_service.dart';
import 'mock_catalog.dart';
import 'notifications_service.dart';
import 'requests_service.dart';
import 'resident_profile_service.dart';

/// Timestamp for evergreen/contextual notifications that have no real event
/// of their own (a profile-completion reminder, a duplicate-account alert)
/// — recomputed relative to wall-clock time on every call (not a fixed
/// date) so these consistently sort as "recent": newer than genuinely old
/// content (yesterday's illustrative announcements, a request update from
/// earlier in the day) but older than anything that just happened moments
/// ago (e.g. a live-demo correction notification just created by flagging a
/// document), so a brand-new event still surfaces above these without them
/// being manually pinned to a fixed list position.
///
/// [priority] gives evergreen items a stable relative order *among
/// themselves* (lower = newer/higher in the list) — without it, each call
/// site independently calling `DateTime.now()` would let ordinary clock
/// jitter (plus List.sort's own lack of a stability guarantee) shuffle
/// their relative order from one rebuild to the next, which previously
/// broke a test's scroll-then-tap targeting since the pixel offset above
/// its target shifted between runs. The separation between priority levels
/// (whole seconds) is far larger than realistic jitter between two calls
/// milliseconds apart, so it stays deterministic regardless of exactly when
/// each call executes.
DateTime _evergreenNotificationTime([int priority = 0]) =>
    DateTime.now().subtract(Duration(minutes: 30, seconds: priority));

/// Builds the same notification feed [NotificationsScreen] shows, as a
/// plain list with stable IDs — shared with [AlertsAction] (the bell icon)
/// so both surfaces agree on exactly what counts as a notification and
/// whether it's read, without keeping two separate copies of this
/// derivation logic. Combines three sources, each visually distinguished
/// by [NotificationKind] (icon + label, never color alone):
///
/// 1. A profile-completion reminder — derived live from
///    [ResidentProfileService], not a stored notification, so it appears
///    exactly while the signed-in citizen's profile is incomplete and
///    disappears the moment it reaches 100%, and never shown to a Guest.
/// 2. Real request-status updates — every non-citizen entry in a
///    request's statusHistory (the "Mobile Reflection" half of the
///    citizen/admin flow model). This is also how the pre-made Dokyu/
///    Tulong status simulations (see MockCatalog demo seed) surface their
///    own Approved/Pending/Rejected notifications — they're just requests
///    with statusHistory like any other, so no separate notification
///    producer was needed for them.
/// 3. Sample notifications for types this frontend-only build has no real
///    producer for yet — illustrative only, never wired to any real state
///    change.
///
/// The returned list is always sorted newest-first by [AppNotification.at]
/// — a single, uniform chronological ordering across every source above
/// rather than sorting each source internally then concatenating, so a
/// brand-new event (e.g. a just-flagged correction) always surfaces at the
/// very top without needing to be specially pinned there.
/// Ids from the latest [buildNotificationFeed] call. The shell paints the
/// bell during build, so a test can read this list on the next frame.
List<String> latestNotificationFeedIds = const [];

List<AppNotification> buildNotificationFeed(BuildContext context) {
  final session = context.watch<CitizenSessionService>();
  final account = session.account;
  final requests = context.watch<RequestsService>().all;

  final items = <AppNotification>[];

  ResidentProfileService? profileService;
  if (account != null) profileService = context.watch<ResidentProfileService>();
  final profile = account != null ? profileService!.profileFor(account) : null;
  if (profile != null && profile.overallCompletionPercent < 100) {
    items.add(
      AppNotification(
        id: 'profile-reminder-${account!.id}',
        kind: NotificationKind.actionRequired,
        icon: Icons.badge_outlined,
        title: 'Complete Your Profile',
        body:
            'Finish your Resident Profile so Teresa, Rizal LGU can verify your account and unlock full access. ${profile.overallCompletionPercent}% complete.',
        at: _evergreenNotificationTime(0),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ResidentProfileOverviewScreen(),
          ),
        ),
        actionLabel: 'Complete Profile',
      ),
    );
  }

  if (account != null) {
    final duplicateAlerts = context.watch<NotificationsService>();
    items.addAll(
      _duplicateAccountNotifications(context, account.id, duplicateAlerts),
    );
    items.addAll(
      _unverifiedDuplicateNotifications(context, account.id, duplicateAlerts),
    );
  }

  items.addAll(_correctionNotifications(context, requests));

  final requestItems = <(ServiceRequest, StatusHistoryEntry)>[];
  for (final r in requests) {
    for (final h in r.statusHistory) {
      if (h.actor == 'Citizen') continue;
      // A "Flagged for Replacement" event gets its own, richer per-
      // requirement correction notification below instead of this generic
      // one — same underlying event, never both (see the exact-timestamp
      // match, guaranteed by RequestsService.flagAdditionalDocuments writing
      // both with the same DateTime instant). The "Needs Manual
      // Verification" flavor of Under Review has no matching
      // FlaggedRequirement, so it still gets the plain generic notification
      // exactly as before.
      final isFlaggingEvent =
          h.status == RequestMilestones.underReview &&
          r.flaggedRequirements.any((f) => f.flaggedAt == h.at);
      if (isFlaggingEvent) continue;
      requestItems.add((r, h));
    }
  }
  requestItems.sort((a, b) => b.$2.at.compareTo(a.$2.at));

  for (final (request, entry) in requestItems) {
    items.add(
      AppNotification(
        id: 'req-${request.id}-${entry.at.toIso8601String()}-${entry.status}',
        kind: _kindFor(entry.status),
        icon: _iconFor(entry.status),
        title: '${request.typeName} — ${entry.status}',
        body: entry.remarks ?? 'Updated by ${entry.actor}.',
        time: request.referenceNumber,
        at: entry.at,
        channel: InboxChannel.requests,
        personal: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(requestId: request.id),
          ),
        ),
      ),
    );
  }

  items.addAll(g5LiveSamples(context));

  if (account == null) {
    items.removeWhere(
      (item) => item.personal || item.channel == InboxChannel.requests,
    );
  }

  items.sort((a, b) => b.at.compareTo(a.at));
  latestNotificationFeedIds = [for (final item in items) item.id];
  return items;
}

/// One notification per Dokyu/Tulong request that has ever had a
/// requirement flagged (works identically for both modules — nothing here
/// is service-specific; every value comes from the request/requirement
/// themselves) — see [FlaggedRequirement]'s own doc comment for why
/// deriving straight from this durable, never-deleted list (rather than
/// statusHistory) is what makes the notification set stable across app
/// reopens (same id -> [NotificationsService] remembers it was already
/// read) while still producing a genuinely new, unread notification the
/// moment a requirement is flagged again in a later verification cycle (a
/// new [FlaggedRequirement] with its own id/flaggedAt).
///
/// A request with exactly ONE currently-unresolved flag gets its own
/// specific notification (id keyed by that flag's id) with a "Replace
/// Document" action that jumps straight to that one requirement's own
/// uploader. A request with MORE THAN ONE unresolved flag at once gets a
/// single combined notification instead (id keyed by the sorted set of
/// currently-unresolved flag ids, so it changes — a genuinely new
/// notification — the moment that set changes, e.g. a new one is flagged or
/// one is resolved) with a "Review Documents" action, since stacking one
/// card per flagged item on the same request read as noisy/unclear rather
/// than as one coherent correction request. Either way [onTap] (the whole
/// card) always opens the request in general.
///
/// Once resolved, or once the request has moved on (approved/rejected/
/// etc.), a flag's notification becomes read-only history — no action
/// offered — see RequestsService.replaceFlaggedRequirement's own no-op
/// guard for the matching safety net on the data side. Resolved entries are
/// still shown individually (never bundled): there's no stacked-CTA
/// confusion to avoid once nothing is actionable.
List<AppNotification> _correctionNotifications(
  BuildContext context,
  List<ServiceRequest> requests,
) {
  final items = <(DateTime sortKey, AppNotification notification)>[];

  for (final r in requests) {
    if (r.flaggedRequirements.isEmpty) continue;
    final unresolved = r.flaggedRequirements
        .where((f) => !f.isResolved)
        .toList();
    final resolved = r.flaggedRequirements.where((f) => f.isResolved).toList();
    final isActive =
        r.status == RequestMilestones.underReview && unresolved.isNotEmpty;

    if (isActive && unresolved.length > 1) {
      final sortedIds = unresolved.map((f) => f.id).toList()..sort();
      final latest = unresolved
          .map((f) => f.flaggedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      items.add((
        latest,
        AppNotification(
          id: 'correction-${r.id}-multi-${sortedIds.join('+')}',
          kind: NotificationKind.actionRequired,
          icon: Icons.description_outlined,
          title: 'Application Needs Correction',
          body:
              '${r.typeName}\n\n'
              '${unresolved.length} documents require correction.\n\n'
              '${unresolved.map((f) => '${f.requirementLabel}\nReason: ${f.reason}').join('\n\n')}',
          time: r.referenceNumber,
          at: latest,
          channel: InboxChannel.requests,
          personal: true,
          actionLabel: 'Review Documents',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(requestId: r.id),
            ),
          ),
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(requestId: r.id),
            ),
          ),
        ),
      ));
    } else {
      // isActive is false here either because the request has moved past
      // Under Review (rejected/approved/etc — nothing left to replace) or
      // because there's at most one unresolved flag; only in the latter
      // case is a replacement still actually offered.
      for (final f in unresolved) {
        items.add((
          f.flaggedAt,
          _correctionNotificationFor(context, r, f, canStillReplace: isActive),
        ));
      }
    }
    for (final f in resolved) {
      items.add((
        f.flaggedAt,
        _correctionNotificationFor(context, r, f, canStillReplace: false),
      ));
    }
  }

  items.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, n) in items) n];
}

AppNotification _correctionNotificationFor(
  BuildContext context,
  ServiceRequest request,
  FlaggedRequirement flagged, {
  required bool canStillReplace,
}) {
  return AppNotification(
    id: 'correction-${request.id}-${flagged.id}',
    kind: NotificationKind.actionRequired,
    icon: Icons.description_outlined,
    title: 'Application Needs Correction',
    body:
        '${request.typeName}\n\n'
        'Your ${request.typeName} application needs a correction.\n\n'
        '${flagged.requirementLabel}\n'
        'Reason: ${flagged.reason}\n\n'
        '${canStillReplace ? 'Please replace the flagged document to continue your application.' : 'This item has already been addressed.'}',
    time: request.referenceNumber,
    at: flagged.flaggedAt,
    channel: InboxChannel.requests,
    personal: true,
    actionLabel: canStillReplace ? 'Replace Document' : null,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(requestId: request.id),
      ),
    ),
    onAction: canStillReplace
        ? () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                requestId: request.id,
                focusFlaggedRequirementId: flagged.id,
              ),
            ),
          )
        : null,
  );
}

/// Phase 6 — "One Person, One Account" duplicate-account demo (FRONTEND
/// SIMULATION ONLY, see duplicate_account_details_screen.dart). Two
/// alert scenarios ('a'/'b') on the real Perlita Quiambao's own account so
/// both the "Yes, this is me" and "No, this is not me" resolutions can be
/// demonstrated without resetting the app, plus one informational entry
/// on the duplicate account itself. Every id is unique and unrelated to
/// any real request/profile state, so this can never collide with or
/// affect the notification sources above.
List<AppNotification> _duplicateAccountNotifications(
  BuildContext context,
  String accountId,
  NotificationsService duplicateAlerts,
) {
  const originalId = 'ESP-RES-2024-9002';
  final duplicateId = MockCatalog.duplicateVerifiedDemoAccount.id;

  if (accountId == originalId) {
    const scenarioIds = ['a', 'b'];
    return [
      for (var i = 0; i < scenarioIds.length; i++)
        _duplicateAlertFor(
          context,
          scenarioIds[i],
          duplicateAlerts,
          priority: i + 1,
        ),
    ];
  }

  if (accountId == duplicateId) {
    // No resolution choice on this side — see the class doc comment on
    // DuplicateAccountDetailsScreen for why (only enough information for
    // the *original* resident to confirm ownership, nothing exposed here).
    final resolvedAsSameOwner =
        duplicateAlerts.duplicateResolutionFor('a') == 'confirmed' ||
        duplicateAlerts.duplicateResolutionFor('b') == 'confirmed';
    final resolvedAsReported =
        duplicateAlerts.duplicateResolutionFor('a') == 'reported' ||
        duplicateAlerts.duplicateResolutionFor('b') == 'reported';
    return [
      AppNotification(
        id: 'duplicate-under-review-status',
        kind: resolvedAsSameOwner
            ? NotificationKind.warning
            : NotificationKind.actionRequired,
        icon: Icons.person_search_rounded,
        title: resolvedAsSameOwner
            ? 'Duplicate / Verification Blocked'
            : resolvedAsReported
            ? 'Duplicate Account Flagged for Investigation'
            : 'Duplicate Account Under Review',
        body: resolvedAsSameOwner
            ? 'The original resident confirmed this registration is theirs. Teresa, Rizal allows one account per '
                  'resident, so verification cannot continue on this account — sign in with your original account '
                  'instead.'
            : resolvedAsReported
            ? 'This registration has been flagged for administrative investigation. Verification remains on '
                  'hold while it is reviewed.'
            : 'An existing Teresa, Rizal account appears to match the information submitted for this account. '
                  'Verification is temporarily restricted while the account is reviewed.',
        at: _evergreenNotificationTime(1),
      ),
    ];
  }

  return const [];
}

/// The Unverified+Unverified duplicate demo — independent of
/// [_duplicateAccountNotifications] above, see
/// screens/notifications/unverified_duplicate_resolution_screen.dart.
List<AppNotification> _unverifiedDuplicateNotifications(
  BuildContext context,
  String accountId,
  NotificationsService duplicateAlerts,
) {
  final aId = MockCatalog.unverifiedDuplicateAccountA.id;
  final bId = MockCatalog.unverifiedDuplicateAccountB.id;
  if (accountId != aId && accountId != bId) return const [];

  final thisLabel = accountId == aId ? 'A' : 'B';
  final kept = duplicateAlerts.unverifiedDuplicateKeptAccountId;

  final String title;
  final String body;
  final NotificationKind kind;
  if (kept == null) {
    title = 'Possible Duplicate Registration Detected';
    body =
        'Two unverified Teresa, Rizal registrations appear to contain matching resident information. Choose which '
        'one to continue using for verification.';
    kind = NotificationKind.warning;
  } else if (kept == thisLabel) {
    title = 'Unverified — Continue Verification';
    body =
        'You chose to continue verification with this account. It is still Pending Review — an LGU officer '
        'still has to approve it; this did not make it Verified automatically.';
    kind = NotificationKind.info;
  } else {
    title = 'Duplicate Registration — Verification Cancelled';
    body =
        'This registration was marked as a duplicate after the other account was chosen. Its verification has '
        'been cancelled.';
    kind = NotificationKind.warning;
  }

  return [
    AppNotification(
      id: 'unverified-duplicate-$thisLabel',
      kind: kind,
      icon: Icons.person_search_rounded,
      title: title,
      body: body,
      at: _evergreenNotificationTime(thisLabel == 'A' ? 3 : 4),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const UnverifiedDuplicateResolutionScreen(),
        ),
      ),
    ),
  ];
}

AppNotification _duplicateAlertFor(
  BuildContext context,
  String scenarioId,
  NotificationsService duplicateAlerts, {
  required int priority,
}) {
  final resolution = duplicateAlerts.duplicateResolutionFor(scenarioId);
  final label = scenarioId == 'a' ? 'Scenario A' : 'Scenario B';
  return AppNotification(
    id: 'duplicate-alert-$scenarioId',
    kind: resolution == null ? NotificationKind.warning : NotificationKind.info,
    icon: Icons.person_search_rounded,
    title: resolution == null
        ? 'Possible Duplicate Account Detected'
        : 'Possible Duplicate Account Detected ($label — Resolved)',
    body: resolution == null
        ? 'Another Teresa, Rizal account was created using information that appears to match your identity. Please '
              'confirm whether the account belongs to you.'
        : resolution == 'confirmed'
        ? 'You confirmed this duplicate account is yours — it remains blocked from verification. Tap to view details.'
        : 'You reported this duplicate account does not belong to you — it has been flagged for '
              'administrative investigation. Tap to view details.',
    at: _evergreenNotificationTime(priority),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuplicateAccountDetailsScreen(scenarioId: scenarioId),
      ),
    ),
  );
}

NotificationKind _kindFor(String status) => switch (status) {
  'Approved' || 'Released' || 'Completed' => NotificationKind.success,
  'Rejected' => NotificationKind.warning,
  'Waiting Requirements' => NotificationKind.actionRequired,
  _ => NotificationKind.info,
};

IconData _iconFor(String status) => switch (status) {
  'Approved' => Icons.check_circle_outline_rounded,
  'Rejected' => Icons.cancel_outlined,
  'Released' || 'Completed' => Icons.task_alt_rounded,
  'Waiting Requirements' => Icons.warning_amber_rounded,
  // 'Ready for Release' is the retired label this replaced (see the
  // status-terminology correction pass) — kept so anything still
  // showing it briefly (pre-migration) gets the same icon.
  'Mark to Release' || 'Ready for Release' => Icons.inventory_2_outlined,
  _ => Icons.info_outline_rounded,
};
