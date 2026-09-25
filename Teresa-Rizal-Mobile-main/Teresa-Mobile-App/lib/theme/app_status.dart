import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'soft_widget.dart';

/// The Teresa, Rizal platform's universal status system — the status names and
/// color mappings from the Web Admin's
/// `resources/views/components/ui/badge.blade.php`. These names are shared
/// verbatim across Web Admin and Mobile; never invent new status labels
/// (see CLAUDE.md's "Universal status system" and
/// TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md Section 4).
///
/// **Check the canonical set against `origin/main` of the web repo, never a
/// local clone.** A clone a few dozen commits stale still carries labels that
/// have since been replaced, and will make this file look correct when it is
/// not. Measured against `origin/main` on 2026-08-29: `badge.blade.php` styles
/// **17** labels — two more than either project's CLAUDE.md prose list, which
/// omits [verified] and [unverified]. `status_parity_test.dart` is what keeps
/// this honest; the count is deliberately not restated here, because the
/// previous comment said "the exact 14" for a 15-value enum.
///
/// [underReview] is a deliberate, explicitly-authorized exception (Mobile-
/// only final request-flow correction pass): the citizen-facing Mobile
/// tracking timeline uses it instead of the Web Admin's "Waiting
/// Requirements", because it's what a citizen actually needs to understand.
/// Web Admin itself is untouched and keeps its own original vocabulary —
/// this is additive only, never a replacement for the values above, so
/// nothing already keyed to the rest (Web-Admin-parity contexts) is
/// affected.
///
/// [readyForRelease]'s own label was updated to "Mark to Release" (see the
/// status-terminology correction pass) to match the Web Admin's CURRENT
/// wording (its own badge.blade.php/CLAUDE.md status list — "Mark to
/// Release" replaced the older "Ready for Release" there); the enum
/// identifier is kept as-is since it's never shown to a user, only `.label`
/// is. [readyForPickup] (a since-retired Mobile-only label distinct from
/// this) has been removed — Dokyu/Tulong tracking uses [readyForRelease]
/// directly now, so the two are no longer needed side by side.
enum AppStatus {
  draft,
  submitted,
  pendingReview,
  underVerification,
  assigned,
  processing,
  waitingRequirements,
  approved,
  rejected,
  readyForRelease,
  released,
  completed,
  cancelled,
  archived,
  underReview,

  /// Canonical web-side (`badge.blade.php`, sky) and written into
  /// `statusHistory` as a literal by `requests_service.dart`. Mobile had no
  /// value for it, so `fromLabel('Resubmitted')` fell back to [draft] and a
  /// resubmitted request would have rendered as a grey "Draft".
  resubmitted,

  /// Account statuses, not request statuses — canonical in the same shared
  /// badge component. The Web Admin displays an account whose status is
  /// `Approved` as **`Verified`** (`constituents.blade.php`: `$acct['status']
  /// === 'Approved' ? 'Verified' : ...`, with its own comment noting that
  /// `Verified` grants full Dokyu/Tulong access).
  ///
  /// That made their absence here a live hazard rather than a missing colour:
  /// [CitizenSessionService.accessLevel] resolves an account through
  /// [AppStatusX.fromLabel], so a status arriving as `Verified` used to become
  /// [draft] and lock the citizen **out** of Dokyu — the exact opposite of what
  /// the same word means on the web.
  verified,
  unverified,
}

class StatusStyle {
  final Color background;
  final Color foreground;
  final Color dot;
  const StatusStyle(this.background, this.foreground, this.dot);
}

extension AppStatusX on AppStatus {
  /// The exact label shown to users — must match the Web Admin string
  /// exactly since these appear side-by-side across both apps.
  String get label => switch (this) {
    AppStatus.draft => 'Draft',
    AppStatus.submitted => 'Submitted',
    AppStatus.pendingReview => 'Pending Review',
    AppStatus.underVerification => 'Under Verification',
    AppStatus.assigned => 'Assigned',
    AppStatus.processing => 'Processing',
    AppStatus.waitingRequirements => 'Waiting Requirements',
    AppStatus.approved => 'Approved',
    AppStatus.rejected => 'Rejected',
    AppStatus.readyForRelease => 'Mark to Release',
    AppStatus.released => 'Released',
    AppStatus.completed => 'Completed',
    AppStatus.cancelled => 'Cancelled',
    AppStatus.archived => 'Archived',
    AppStatus.underReview => 'Under Review',
    AppStatus.resubmitted => 'Resubmitted',
    AppStatus.verified => 'Verified',
    AppStatus.unverified => 'Unverified',
  };

  StatusStyle get style => switch (this) {
    AppStatus.draft => const StatusStyle(AppColors.slate100, AppColors.slate600, AppColors.slate400),
    AppStatus.submitted => const StatusStyle(AppColors.blue50, AppColors.blue700, AppColors.blue500),
    AppStatus.pendingReview => const StatusStyle(AppColors.amber50, AppColors.amber700, AppColors.amber500),
    AppStatus.underVerification => const StatusStyle(AppColors.indigo50, AppColors.indigo700, AppColors.indigo500),
    AppStatus.assigned => const StatusStyle(AppColors.purple50, AppColors.purple700, AppColors.purple500),
    AppStatus.processing => const StatusStyle(AppColors.brand50, AppColors.brand700, AppColors.brand500),
    AppStatus.waitingRequirements => const StatusStyle(AppColors.orange50, AppColors.orange700, AppColors.orange500),
    AppStatus.approved => const StatusStyle(AppColors.emerald50, AppColors.emerald700, AppColors.emerald500),
    AppStatus.rejected => const StatusStyle(AppColors.rose50, AppColors.rose700, AppColors.rose500),
    AppStatus.readyForRelease => const StatusStyle(AppColors.teal50, AppColors.teal700, AppColors.teal500),
    AppStatus.released => const StatusStyle(AppColors.cyan50, AppColors.cyan700, AppColors.cyan500),
    AppStatus.completed => const StatusStyle(AppColors.green50, AppColors.green700, AppColors.green500),
    AppStatus.cancelled => const StatusStyle(SoftColors.blueWash, SoftColors.muted, SoftColors.muted),
    AppStatus.archived => const StatusStyle(AppColors.slate100, AppColors.slate400, AppColors.slate300),
    // Same meaning/coloring as waitingRequirements — "needs attention, not
    // rejected, not done" — just the Mobile-specific label above it.
    AppStatus.underReview => const StatusStyle(AppColors.orange50, AppColors.orange700, AppColors.orange500),
    // sky / emerald / amber, 1:1 with badge.blade.php. `Verified` deliberately
    // shares Approved's emerald and `Unverified` shares Pending Review's amber
    // — that aliasing is the web's own choice, not a shortcut taken here.
    AppStatus.resubmitted => const StatusStyle(AppColors.sky50, AppColors.sky700, AppColors.sky500),
    AppStatus.verified => const StatusStyle(AppColors.emerald50, AppColors.emerald700, AppColors.emerald500),
    AppStatus.unverified => const StatusStyle(AppColors.amber50, AppColors.amber700, AppColors.amber500),
  };

  /// Whether this status represents a finished/terminal state — mirrors the
  /// `doneStatuses` arrays used in document-requests.blade.php /
  /// assistance-requests.blade.php to split "Active" vs "Done" tabs.
  bool get isDone =>
      this == AppStatus.completed ||
      this == AppStatus.released ||
      this == AppStatus.rejected ||
      this == AppStatus.cancelled ||
      this == AppStatus.archived;

  /// Resolves a label to its status, or [AppStatus.draft] if it is unknown.
  ///
  /// The fallback is **loud on purpose**. A silent degrade to `Draft` is how
  /// the missing `Resubmitted` stayed invisible: the timeline printed the raw
  /// string, so nothing looked wrong, while anything routing through here
  /// showed a resubmitted request as a grey "Draft". In debug this now trips an
  /// assertion; in release it logs rather than crashing, because a wrong badge
  /// colour must never take the app down in a citizen's hand.
  static AppStatus fromLabel(String label) {
    for (final status in AppStatus.values) {
      if (status.label == label) return status;
    }
    developer.log(
      'Unknown status label "$label" — falling back to Draft. Check it against '
      'badge.blade.php on origin/main of the web repo.',
      name: 'teresa_rizal.status',
    );
    assert(false, 'Unknown status label "$label". Never invent a status label; add it to AppStatus if it is canonical.');
    return AppStatus.draft;
  }
}
