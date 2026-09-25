import 'attachment.dart';
import 'receipt.dart';

enum ServiceCategory {
  dokyu,
  tulong,
  sakunaIncident,

  /// A persisted request whose service category this build cannot read.
  ///
  /// **Never generated** — it exists only so [ServiceRequest.fromJson] has
  /// something honest to decode into. The previous fallback was [dokyu], which
  /// silently re-filed a citizen's Tulong (assistance) or Sakuna (incident)
  /// application as a document request: wrong tab, wrong catalogue, wrong flow,
  /// and no indication anything was amiss.
  ///
  /// The record is kept rather than dropped, because the reference number,
  /// dates, status history and attachments on it are all still true and the
  /// citizen cannot reconstruct them. It is excluded from the Dokyu and Tulong
  /// tabs and counts, and labelled as unrecognised wherever it does appear.
  unknown,
}

extension ServiceCategoryX on ServiceCategory {
  /// The citizen-facing name of this category.
  ///
  /// Lives here rather than in each screen because the screens used to derive
  /// it with `category == dokyu ? 'Dokyu' : 'Tulong'`, which labels anything
  /// that is not Dokyu as Tulong — including [ServiceCategory.unknown], which
  /// is precisely the mislabelling `unknown` exists to prevent.
  String get label => switch (this) {
    ServiceCategory.dokyu => 'Dokyu',
    ServiceCategory.tulong => 'Tulong',
    ServiceCategory.sakunaIncident => 'Sakuna',
    ServiceCategory.unknown => 'Unrecognised',
  };
}

/// One "Flagged for Replacement" event on a single requirement — created by
/// [RequestsService.flagAdditionalDocuments] and never mutated except to set
/// [resolvedAt] once the citizen replaces that exact document (see
/// [RequestsService.replaceFlaggedRequirement]). Kept in
/// [ServiceRequest.flaggedRequirements] permanently (never removed) so:
/// - a still-unresolved entry ([isResolved] false) drives the correction UI
///   and the "Application Needs Correction" notification for that
///   requirement, keyed by [id] so it never regenerates a duplicate
///   notification just because the app reopened;
/// - a resolved entry stays as read-only history (its own notification, if
///   already seen, simply stops offering a replacement action);
/// - flagging the *same* requirement again later (a new verification cycle)
///   creates a brand-new entry with its own [id]/[flaggedAt], which is
///   exactly what makes that a genuinely new, unread notification.
class FlaggedRequirement {
  final String id;
  final String requirementLabel;
  final String reason;
  final DateTime flaggedAt;
  DateTime? resolvedAt;

  FlaggedRequirement({
    required this.id,
    required this.requirementLabel,
    required this.reason,
    required this.flaggedAt,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requirementLabel': requirementLabel,
        'reason': reason,
        'flaggedAt': flaggedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory FlaggedRequirement.fromJson(Map<String, dynamic> json) => FlaggedRequirement(
        id: json['id'],
        requirementLabel: json['requirementLabel'],
        reason: json['reason'],
        flaggedAt: DateTime.parse(json['flaggedAt']),
        resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      );
}

/// One entry in a request's audit trail — what the Web Admin's "Admin
/// Actions" produce and what the mobile app's "Mobile Reflection" reads.
/// See TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md Section 3 (Flow Matrix).
class StatusHistoryEntry {
  final String status;
  final DateTime at;
  final String? remarks;
  final String actor; // 'Citizen' or an admin role label, e.g. 'MSWDO Staff'

  StatusHistoryEntry({
    required this.status,
    required this.at,
    this.remarks,
    required this.actor,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'at': at.toIso8601String(),
        'remarks': remarks,
        'actor': actor,
      };

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) => StatusHistoryEntry(
        status: json['status'],
        at: DateTime.parse(json['at']),
        remarks: json['remarks'],
        actor: json['actor'],
      );
}

/// A citizen-submitted Dokyu (document) or Tulong (assistance) request.
/// Field names deliberately match the shape a future Laravel API resource
/// would return (id, referenceNumber, applicantId, type, category,
/// submittedAt, status, statusHistory, attachments, remarks, adminRemarks)
/// so swapping the mock DataService for real HTTP calls later only touches
/// the service layer, never these models or the screens that use them.
class ServiceRequest {
  final String id;
  final String referenceNumber;
  final String applicantId;
  final String applicantName;
  final String typeName;
  final ServiceCategory category;
  final String office;
  final String purpose;
  final DateTime submittedAt;
  String status;
  final List<StatusHistoryEntry> statusHistory;
  final List<Attachment> attachments;
  String? citizenRemarks;
  String? adminRemarks;

  /// Optional "what you can do about it" hint shown alongside [adminRemarks]
  /// when a request is Rejected (see RequestDetailScreen's Application
  /// Rejected panel) — null for every request that doesn't have a specific
  /// suggested next step, in which case the panel falls back to a generic
  /// "submit a new application" message built from [typeName] instead.
  /// Mutable (not final) for the same reason [adminRemarks] is — a stale
  /// seeded copy from before this field existed gets backfilled in place,
  /// see RequestsService._migrateEducationalRejectionReason.
  String? rejectionGuidance;

  /// Every "Flagged for Replacement" event ever recorded on this request
  /// (see [FlaggedRequirement]'s own doc comment) — supports more than one
  /// requirement being flagged at once (see
  /// RequestsService.flagAdditionalDocuments), and is never cleared/removed,
  /// only ever appended to or marked resolved, so it doubles as this
  /// request's own correction history. An entry with [FlaggedRequirement.
  /// isResolved] false is still awaiting a citizen re-upload; the request is
  /// Under Review with at least one unresolved entry here, or Under Review
  /// with this list either empty or fully resolved (the "Needs Manual
  /// Verification" flavor — see RequestsService.flagManualVerification).
  final List<FlaggedRequirement> flaggedRequirements;
  final String expectedDays;
  final Map<String, dynamic> formFields;

  /// Whether this service has a real fee (from the catalog item's own
  /// `fee` field — never invented here) — decides whether the milestone
  /// simulation includes payment steps at all. See
  /// docs on the milestone/payment simulation (frontend-only).
  final bool requiresPayment;

  /// The catalog item's own fee text (e.g. "₱50.00"), captured at
  /// submission time — same pattern as [office]/[expectedDays] already
  /// being a snapshot rather than a live re-lookup. Only meaningful when
  /// [requiresPayment] is true.
  final String fee;

  /// 'Onsite' / 'GCash' / 'Maya' once chosen at the Waiting for Payment
  /// milestone — simulation only, never a real transaction.
  String? paymentMethod;

  /// Generated once the milestone simulation reaches
  /// RequestMilestones.receiptGenerated — this request's own permanent
  /// receipt for the rest of the demo session. Never shared across
  /// requests; each one that gets paid generates and keeps its own.
  Receipt? receipt;

  ServiceRequest({
    required this.id,
    required this.referenceNumber,
    required this.applicantId,
    required this.applicantName,
    required this.typeName,
    required this.category,
    required this.office,
    required this.purpose,
    required this.submittedAt,
    required this.status,
    required this.statusHistory,
    required List<Attachment> attachments,
    this.citizenRemarks,
    this.adminRemarks,
    this.rejectionGuidance,
    List<FlaggedRequirement>? flaggedRequirements,
    required this.expectedDays,
    this.formFields = const {},
    this.requiresPayment = false,
    this.fee = '',
    this.paymentMethod,
    this.receipt,
  }) : attachments = List<Attachment>.of(attachments),
       flaggedRequirements = List<FlaggedRequirement>.of(flaggedRequirements ?? const []);

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'typeName': typeName,
        'category': category.name,
        'office': office,
        'purpose': purpose,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status,
        'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'citizenRemarks': citizenRemarks,
        'adminRemarks': adminRemarks,
        'rejectionGuidance': rejectionGuidance,
        'flaggedRequirements': flaggedRequirements.map((f) => f.toJson()).toList(),
        'expectedDays': expectedDays,
        'formFields': formFields,
        'requiresPayment': requiresPayment,
        'fee': fee,
        'paymentMethod': paymentMethod,
        'receipt': receipt?.toJson(),
      };

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: json['id'],
        referenceNumber: json['referenceNumber'],
        applicantId: json['applicantId'],
        applicantName: json['applicantName'],
        typeName: json['typeName'],
        // Falls back to `unknown`, never to a real service: see
        // ServiceCategory.unknown. Guessing re-files the citizen's request.
        category: ServiceCategory.values
            .firstWhere((c) => c.name == json['category'], orElse: () => ServiceCategory.unknown),
        office: json['office'],
        purpose: json['purpose'],
        submittedAt: DateTime.parse(json['submittedAt']),
        status: json['status'],
        // These two were the only unguarded list casts left in any model —
        // `flaggedRequirements` and `formFields` below already default, as does
        // every list in Announcement and ResidentProfile. A record written
        // before either field existed threw on a bare `as List`, and because
        // nothing awaits the restore that throw used to strand the app; it now
        // costs the whole record instead. Neither is a good price for a field
        // whose absence simply means "none recorded".
        //
        // Empty is the honest default: a missing history means the history is
        // unknown, and it must not be invented from `status` + `submittedAt`,
        // which would assert a time the status was reached. Consumers that
        // read the latest entry handle empty explicitly rather than assuming.
        statusHistory: (json['statusHistory'] as List? ?? []).map((e) => StatusHistoryEntry.fromJson(e)).toList(),
        attachments: (json['attachments'] as List? ?? []).map((e) => Attachment.fromJson(e)).toList(),
        citizenRemarks: json['citizenRemarks'],
        adminRemarks: json['adminRemarks'],
        rejectionGuidance: json['rejectionGuidance'],
        // Backward-compatible with the older single-flag shape
        // ('flaggedRequirementLabel', a plain string) for any request
        // already persisted locally before this became a list — migrated
        // in place as a single unresolved entry rather than lost.
        flaggedRequirements: json['flaggedRequirements'] != null
            ? (json['flaggedRequirements'] as List).map((e) => FlaggedRequirement.fromJson(e)).toList()
            : json['flaggedRequirementLabel'] != null
                ? [
                    FlaggedRequirement(
                      id: '${json['id']}-legacy-flag',
                      requirementLabel: json['flaggedRequirementLabel'],
                      reason: json['adminRemarks'] ?? 'Please provide an updated copy of the flagged requirement.',
                      flaggedAt: DateTime.parse(json['submittedAt']),
                    ),
                  ]
                : const [],
        expectedDays: json['expectedDays'],
        formFields: Map<String, dynamic>.from(json['formFields'] ?? {}),
        // Defaults false/null so requests persisted before this field
        // existed still deserialize cleanly.
        requiresPayment: json['requiresPayment'] ?? false,
        fee: json['fee'] ?? '',
        paymentMethod: json['paymentMethod'],
        receipt: json['receipt'] != null ? Receipt.fromJson(json['receipt']) : null,
      );
}
