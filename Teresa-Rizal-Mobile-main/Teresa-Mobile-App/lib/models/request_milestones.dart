import '../theme/app_status.dart';

/// The Mobile-only citizen tracking lifecycle for a Dokyu/Tulong request —
/// rewritten for the "Mobile-only final request flow correction" pass to
/// deliberately NOT show every internal processing/payment sub-state as a
/// numbered milestone. Payment now happens during the application/
/// submission flow itself (see ServiceRequestWizardScreen/NewRequestScreen's
/// own Payment Method step), before a request exists at all, so the
/// tracking timeline a citizen watches afterward never needs payment
/// sub-steps — it starts clean at Submitted.
///
/// [markToRelease]/[released] (renamed from the earlier [readyForPickup]/
/// `completed` during the status-terminology correction pass) now use the
/// Web Admin's own exact current wording instead of Mobile-only synonyms —
/// see [canonicalStatusFor] and [AppStatus.readyForRelease]'s own doc
/// comment. [AppStatus] stays the untouched, Web-Admin-shared status
/// vocabulary; [canonicalStatusFor] maps every stage here to it (plus the
/// one remaining Mobile-only addition, [AppStatus.underReview]) so
/// StatusChip/notification styling always has a real color to show,
/// without Web Admin's own status system ever being edited.
class RequestMilestones {
  RequestMilestones._();

  static const submitted = 'Submitted';
  static const underVerification = 'Under Verification';
  static const approved = 'Approved';
  static const markToRelease = 'Mark to Release';
  static const released = 'Released';

  /// Branch outcomes — reachable from [underVerification] (or, for
  /// [rejected], from anywhere active), never part of the fixed forward
  /// sequence below. [underReview] covers both "needs additional
  /// documents" (one or more specific flagged requirements — see
  /// ServiceRequest.flaggedRequirements) and "needs manual
  /// verification" (no specific requirement, just more staff review time)
  /// — both are the same non-terminal, resumable branch state from the
  /// citizen's point of view, distinguished only by what the panel shows.
  static const underReview = 'Under Review';
  static const rejected = 'Rejected';

  /// The one, single, always-the-same forward path a request's tracking
  /// timeline shows — no more payment-conditional branching, since payment
  /// (when applicable) already happened before the request existed.
  static const List<String> sequence = [submitted, underVerification, approved, markToRelease, released];

  /// Kept only so any remaining call site that still passes the old
  /// `requiresPayment:` flag keeps compiling during the transition — always
  /// returns the same fixed [sequence] now regardless of the argument.
  static List<String> sequenceFor({bool requiresPayment = false}) => sequence;

  static AppStatus canonicalStatusFor(String milestone) => switch (milestone) {
    underReview => AppStatus.underReview,
    rejected => AppStatus.rejected,
    // AppStatus.readyForRelease's own .label is 'Mark to Release' (see its
    // doc comment) — no separate Mobile-only AppStatus value needed for
    // this anymore. [released] falls through to the default branch below,
    // which already resolves 'Released' to AppStatus.released correctly.
    markToRelease => AppStatus.readyForRelease,
    _ => AppStatusX.fromLabel(milestone),
  };
}
