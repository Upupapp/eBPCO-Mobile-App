import 'package:flutter/material.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../services/requests_service.dart';
import '../widgets/app_dialogs.dart';

/// Per assistance type, per resident — Dokyu has no such restriction (a
/// document may legitimately be needed again for a different purpose, see
/// docs on Dokyu's own repeat-request rule), but the SAME Tulong assistance
/// may not be applied for again while a previous application for it is
/// still active or already succeeded. Reapplying to the same assistance is
/// only allowed once every prior application for it was Rejected (or
/// Cancelled — this project's existing business logic already treats a
/// citizen-cancelled request the same as "doesn't block anything further",
/// see RequestsService.cancel/the old tulong_application_limit.dart this
/// file replaces). This is a status check, not a count cap: a resident can
/// be rejected and reapply any number of times, but never holds two
/// concurrent (or one successful) applications for the same assistance.
enum TulongEligibility {
  eligible,

  /// A previous application for this assistance is still in progress
  /// (Submitted, Pending Review, Under Verification, Assigned, Processing,
  /// Waiting Requirements, or Approved — Approved sits in this project's
  /// "Active" tab, not "Done", since the benefit itself hasn't finished
  /// being released/completed yet).
  blockedActive,

  /// This assistance was already fully received — Mark to Release or
  /// Released (see the status-terminology correction pass — Mobile now uses
  /// the Web Admin's own exact wording for these two stages).
  blockedReceived,
}

class TulongEligibilityResult {
  final TulongEligibility status;

  /// The specific prior request that's blocking a new one — null only when
  /// [status] is [TulongEligibility.eligible].
  final ServiceRequest? blockingRequest;

  const TulongEligibilityResult(this.status, this.blockingRequest);

  bool get isEligible => status == TulongEligibility.eligible;
}

const _successfulTulongStatuses = {'Approved', RequestMilestones.markToRelease, RequestMilestones.released};
const _reapplicableTulongStatuses = {'Rejected', 'Cancelled'};

/// Whether [applicantId] may currently apply for the Tulong assistance
/// [typeName] — checks every one of their own past requests for this exact
/// assistance (newest first) and blocks on the first one that isn't
/// Rejected/Cancelled. A different assistance type is never affected; it
/// has its own independent history.
TulongEligibilityResult tulongEligibilityFor(
  RequestsService requests, {
  required String applicantId,
  required String typeName,
}) {
  final matches = requests.all
      .where((r) => r.applicantId == applicantId && r.category == ServiceCategory.tulong && r.typeName == typeName)
      .toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  for (final r in matches) {
    if (_reapplicableTulongStatuses.contains(r.status)) continue;
    final status = _successfulTulongStatuses.contains(r.status)
        ? TulongEligibility.blockedReceived
        : TulongEligibility.blockedActive;
    return TulongEligibilityResult(status, r);
  }
  return const TulongEligibilityResult(TulongEligibility.eligible, null);
}

/// Shows the appropriate blocked-application dialog for [result] (must not
/// be eligible) and returns true if the citizen chose to view the blocking
/// request — the caller is responsible for the actual navigation, since
/// this file has no screen dependency of its own.
Future<bool> showTulongBlockedDialog(BuildContext context, TulongEligibilityResult result) {
  final isReceived = result.status == TulongEligibility.blockedReceived;
  return AppDialogs.confirm(
    context,
    title: isReceived ? 'Assistance Already Received' : 'Active Application Exists',
    message: isReceived
        ? 'You have already received this assistance and cannot submit another application for the same '
            'assistance at this time.'
        : 'You already have an active application for this assistance.',
    confirmLabel: isReceived ? 'View Previous Request' : 'View Existing Request',
    cancelLabel: 'Close',
  );
}
