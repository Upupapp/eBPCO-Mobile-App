import 'package:flutter/material.dart';
import 'app_colors.dart';

/// eBPCO's own status vocabulary — ported field-for-field from the web
/// portals' shared `core/domain/status.model.ts`, whose own comment reads
/// "identical to ebpco-mobile's ApplicationStatus". This is that file.
/// Never invent a status label here: the backend's `lifecycle_status`
/// column is the authority (`lifecycle_transitions` table, seeded by
/// `eBPCOBackend`'s `domain/lifecycle.ts`), and this app only ever displays
/// the coarser citizen-facing projection the server itself computes and
/// returns as `applicantStatus` — never one derived locally from the raw
/// value, so a backend-side change to the projection is never silently
/// re-derived wrong here.
enum LifecycleStatus {
  draft,
  submitted,
  received,
  documentVerification,
  underEvaluation,
  revisionRequired,
  assessed,
  paymentSubmitted,
  paymentUnderVerification,
  paymentVerified,
  forApproval,
  approved,
  permitGenerated,
  readyForRelease,
  released,
  completed,
  rejected,
  cancelled,
  expired,
}

extension LifecycleStatusX on LifecycleStatus {
  String get label => switch (this) {
        LifecycleStatus.draft => 'Draft',
        LifecycleStatus.submitted => 'Submitted',
        LifecycleStatus.received => 'Received',
        LifecycleStatus.documentVerification => 'Document Verification',
        LifecycleStatus.underEvaluation => 'Under Evaluation',
        LifecycleStatus.revisionRequired => 'Revision Required',
        LifecycleStatus.assessed => 'Assessed',
        LifecycleStatus.paymentSubmitted => 'Payment Submitted',
        LifecycleStatus.paymentUnderVerification => 'Payment Under Verification',
        LifecycleStatus.paymentVerified => 'Payment Verified',
        LifecycleStatus.forApproval => 'For Approval',
        LifecycleStatus.approved => 'Approved',
        LifecycleStatus.permitGenerated => 'Permit Generated',
        LifecycleStatus.readyForRelease => 'Ready for Release',
        LifecycleStatus.released => 'Released',
        LifecycleStatus.completed => 'Completed',
        LifecycleStatus.rejected => 'Rejected',
        LifecycleStatus.cancelled => 'Cancelled',
        LifecycleStatus.expired => 'Expired',
      };

  /// Plain-language "what happens next", keyed by the raw lifecycle status —
  /// copied verbatim from `status.model.ts`'s `NEXT_STEP_TEXT` so the wording
  /// a citizen reads is the same regardless of which app they're using.
  String get nextStep => switch (this) {
        LifecycleStatus.draft => 'Finish your application and submit it when ready.',
        LifecycleStatus.submitted => 'Your application has been received and is queued for review.',
        LifecycleStatus.received => 'Your application has been received and is queued for review.',
        LifecycleStatus.documentVerification => 'Your submitted documents are being checked for completeness.',
        LifecycleStatus.underEvaluation => 'Your application is under technical evaluation by the reviewing office.',
        LifecycleStatus.revisionRequired => 'Please review the remarks on your application and resubmit the requested items.',
        LifecycleStatus.assessed => 'An Order of Payment has been issued. Please view your assessment and proceed to payment.',
        LifecycleStatus.paymentSubmitted => 'Your payment has been submitted and is awaiting verification.',
        LifecycleStatus.paymentUnderVerification => 'Your payment is being verified by the collecting office.',
        LifecycleStatus.paymentVerified => 'Your payment has been verified. Your application is proceeding to final approval.',
        LifecycleStatus.forApproval => 'Your application is awaiting final approval.',
        LifecycleStatus.approved => 'Your application has been approved. Your permit is being generated.',
        LifecycleStatus.permitGenerated => 'Your permit has been generated and is being prepared for release.',
        LifecycleStatus.readyForRelease => 'Your permit is ready for release. Visit the issuing office or check for pickup instructions.',
        LifecycleStatus.released => 'Your permit has been released.',
        LifecycleStatus.completed => 'This application is complete.',
        LifecycleStatus.rejected => 'Your application was rejected. See remarks for details.',
        LifecycleStatus.cancelled => 'This application was cancelled.',
        LifecycleStatus.expired => 'This application has expired.',
      };

  static LifecycleStatus fromLabel(String label) {
    for (final status in LifecycleStatus.values) {
      if (status.label == label) return status;
    }
    // Loud on purpose, same discipline as the reference app's own
    // fromLabel: a silent fallback here would render a real, unrecognized
    // status as something it isn't rather than surfacing the drift.
    assert(false, 'Unknown lifecycle status label "$label" — check it against eBPCOBackend/src/modules/applications/domain/lifecycle.ts.');
    return LifecycleStatus.draft;
  }
}

/// The coarse, citizen-facing status — what every screen in this app
/// renders. Prefer the server's own `applicantStatus` field over deriving
/// this locally; [ApplicantStatusX.fromLifecycle] exists for the few
/// contexts (e.g. the timeline) that only have the raw lifecycle string.
enum ApplicantStatus {
  draft,
  submitted,
  underReview,
  paymentVerification,
  approved,
  readyForRelease,
  rejected,
}

extension ApplicantStatusX on ApplicantStatus {
  String get label => switch (this) {
        ApplicantStatus.draft => 'Draft',
        ApplicantStatus.submitted => 'Submitted',
        ApplicantStatus.underReview => 'Under Review',
        ApplicantStatus.paymentVerification => 'Payment Verification',
        ApplicantStatus.approved => 'Approved',
        ApplicantStatus.readyForRelease => 'Ready for Release',
        ApplicantStatus.rejected => 'Rejected',
      };

  static ApplicantStatus fromLabel(String label) {
    for (final status in ApplicantStatus.values) {
      if (status.label == label) return status;
    }
    return ApplicantStatus.draft;
  }

  static ApplicantStatus fromLifecycle(LifecycleStatus status) => switch (status) {
        LifecycleStatus.draft => ApplicantStatus.draft,
        LifecycleStatus.submitted => ApplicantStatus.submitted,
        LifecycleStatus.received => ApplicantStatus.submitted,
        LifecycleStatus.documentVerification => ApplicantStatus.underReview,
        LifecycleStatus.underEvaluation => ApplicantStatus.underReview,
        LifecycleStatus.revisionRequired => ApplicantStatus.underReview,
        LifecycleStatus.assessed => ApplicantStatus.paymentVerification,
        LifecycleStatus.paymentSubmitted => ApplicantStatus.paymentVerification,
        LifecycleStatus.paymentUnderVerification => ApplicantStatus.paymentVerification,
        LifecycleStatus.paymentVerified => ApplicantStatus.paymentVerification,
        LifecycleStatus.forApproval => ApplicantStatus.paymentVerification,
        LifecycleStatus.approved => ApplicantStatus.approved,
        LifecycleStatus.permitGenerated => ApplicantStatus.approved,
        LifecycleStatus.readyForRelease => ApplicantStatus.readyForRelease,
        LifecycleStatus.released => ApplicantStatus.readyForRelease,
        LifecycleStatus.completed => ApplicantStatus.readyForRelease,
        LifecycleStatus.rejected => ApplicantStatus.rejected,
        LifecycleStatus.cancelled => ApplicantStatus.rejected,
        LifecycleStatus.expired => ApplicantStatus.rejected,
      };
}

/// The word actually shown on screen for a raw lifecycle status — distinct
/// from [ApplicantStatusX.fromLifecycle], which stays the categorization
/// every filter/count needs. Withdrawing your OWN application and having
/// the LGU reject it both categorize as "nothing more to do here" for
/// filtering, but they are not the same sentence to read — "Rejected" on an
/// application the citizen cancelled themselves would read as the
/// Municipality having turned them down. Ported verbatim from
/// `status.model.ts`'s `applicantStatusLabel`.
String applicantStatusLabel(LifecycleStatus status) {
  if (status == LifecycleStatus.cancelled) return 'Cancelled';
  return ApplicantStatusX.fromLifecycle(status).label;
}

class StatusStyle {
  final Color background;
  final Color foreground;
  const StatusStyle(this.background, this.foreground);
}

/// Colors resolved from the web portals' own badge classes
/// (`shared/ui/status-pill.component.ts`'s `APPLICANT_STATUS_CLASS`,
/// resolved against `styles.scss`'s `.badge-*` rules) — keyed by the exact
/// label text shown, the same way the web component keys it, so
/// "Cancelled" gets its own entry rather than inheriting Rejected's red.
final Map<String, StatusStyle> _statusStyleByLabel = {
  'Draft': const StatusStyle(AppColors.gray100, AppColors.gray700),
  'Submitted': const StatusStyle(AppColors.info100, AppColors.infoText),
  'Under Review': const StatusStyle(AppColors.primary100, AppColors.primary700),
  'Payment Verification': const StatusStyle(AppColors.warning100, AppColors.warningText),
  'Approved': const StatusStyle(AppColors.success100, AppColors.successText),
  'Ready for Release': const StatusStyle(AppColors.success100, AppColors.successText),
  'Rejected': const StatusStyle(AppColors.danger100, AppColors.dangerText),
  'Cancelled': const StatusStyle(AppColors.gray100, AppColors.gray700),
};

StatusStyle statusStyleForLabel(String label) => _statusStyleByLabel[label] ?? const StatusStyle(AppColors.gray100, AppColors.gray700);
