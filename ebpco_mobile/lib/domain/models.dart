/// Wire models for the citizen-facing eBPCO API, ported field-for-field
/// from `ebpco-user-portal/src/app/core/api/citizen-api.models.ts` — that
/// file is itself pinned against `contract/citizen-endpoints.openapi.yaml`
/// in eBPCOBackend, so these describe what the server actually sends, not
/// what this app imagines it sends.
library;

import 'account_verification.dart';
import 'applying_as.dart';

class Pledge {
  final int pledgedWorkingDays;
  final String? dueDate;
  final bool approximate;
  final bool suspended;
  final String? suspendedSince;

  const Pledge({
    required this.pledgedWorkingDays,
    required this.dueDate,
    required this.approximate,
    required this.suspended,
    required this.suspendedSince,
  });

  factory Pledge.fromJson(Map<String, dynamic> json) => Pledge(
        pledgedWorkingDays: json['pledgedWorkingDays'] as int,
        dueDate: json['dueDate'] as String?,
        approximate: json['approximate'] as bool? ?? false,
        suspended: json['suspended'] as bool? ?? false,
        suspendedSince: json['suspendedSince'] as String?,
      );
}

class OrderOfPayment {
  final String number;
  final String assessedAt;
  final String? dueDate;
  final int totalCentavos;

  /// filing / processing / architectural / structural / electrical / others,
  /// in centavos — the Order of Payment's own breakdown.
  final Map<String, int> fees;

  /// The fee schedule the office assessed by, printed on the Order of
  /// Payment as the portal prints it; null when the server sent none.
  final String? feeScheduleVersion;

  const OrderOfPayment({
    required this.number,
    required this.assessedAt,
    required this.dueDate,
    required this.totalCentavos,
    this.fees = const {},
    this.feeScheduleVersion,
  });

  factory OrderOfPayment.fromJson(Map<String, dynamic> json) => OrderOfPayment(
        number: json['number'] as String,
        assessedAt: json['assessedAt'] as String,
        dueDate: json['dueDate'] as String?,
        totalCentavos: json['totalCentavos'] as int,
        fees: {
          for (final e in ((json['fees'] as Map<String, dynamic>?) ?? const {}).entries)
            if (e.value is int) e.key: e.value as int,
        },
        feeScheduleVersion: switch (json['feeScheduleVersion']) {
          final String version when version.trim().isNotEmpty => version.trim(),
          _ => null,
        },
      );
}

const draftReferencePrefix = 'DRAFT-';
const draftReferenceLabel = 'Draft (no number yet)';

/// The portal's `isTerminalStatus`: completed, withdrawn, rejected or expired.
const closedStatuses = {'Completed', 'Cancelled', 'Rejected', 'Expired'};

class ApplicationSummary {
  final String id;
  final String referenceNumber;
  final String permitType;
  final String applicationAction;
  final String? businessId;
  final String? businessName;
  final String? location;
  final String? renewsPermitNumber;
  final String? priorPermitClaim;
  /// The raw, 20-value internal status (e.g. "Under Evaluation"); one the
  /// app does not know yet is shown as the server's [applicantStatus].
  final String lifecycleStatus;
  /// The coarse, citizen-facing projection — prefer this for display.
  final String applicantStatus;
  final bool requiresApplicantAction;
  final String? dateSubmitted;
  final String updatedAt;
  final int openInstructionCount;
  final Map<String, dynamic> form;
  final Pledge? pledge;
  final String paymentStatus;
  final OrderOfPayment? orderOfPayment;

  /// 'residential' or 'business' (ebpco-api 067). The server derives it; an
  /// older server's answer is read the same way from the form and business.
  final String applyingAs;

  const ApplicationSummary({
    required this.id,
    required this.referenceNumber,
    required this.permitType,
    required this.applicationAction,
    required this.businessId,
    required this.businessName,
    required this.location,
    required this.renewsPermitNumber,
    required this.priorPermitClaim,
    required this.lifecycleStatus,
    required this.applicantStatus,
    required this.requiresApplicantAction,
    required this.dateSubmitted,
    required this.updatedAt,
    required this.openInstructionCount,
    required this.form,
    required this.pledge,
    required this.paymentStatus,
    required this.orderOfPayment,
    this.applyingAs = applyingAsBusiness,
  });

  /// Filed for the citizen's home or other private property, not a business.
  bool get isResidential => applyingAs == applyingAsResidential;

  /// Who it is for, under "Applying as": the business's name, or "Private
  /// individual" (design review I6) — the portal's `applicantLabel`.
  String? get applicantLabel => isResidential ? privateIndividualLabel : businessName;

  /// The business's name on a printed document, or null for a private
  /// individual's application: no "Business name" row then, so the occupancy
  /// is the only statement of use (design review I6).
  String? get businessNameOnDocument {
    if (isResidential) return null;
    final name = businessName?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  /// The property owner a residential application filed before the 2026-10-28
  /// ruling named, when the applicant was not the owner. History only.
  String? get propertyOwnerName => isResidential ? propertyOwnerNameOf(form) : null;

  /// What the status pill reads — the portal's `applicantStatusLabel`. The
  /// citizen's own withdrawal says "Cancelled"; filed under Rejected for
  /// filters and counts, it would otherwise read as the Municipality
  /// having turned them down.
  /// The word on the badge, the same as the citizen portal's `applicantStatusLabel`: the coarse
  /// status, except where it would say the wrong thing — a completed application read "Ready for
  /// Release", and one waiting on the citizen read as the office still working on it.
  /// Out for Delivery (ebpco-api 070) is on its way by courier, not waiting at
  /// the office; it still counts as Ready for Release.
  String get statusLabel => switch (lifecycleStatus) {
        'Cancelled' => 'Cancelled',
        'Out for Delivery' => 'Out for Delivery',
        'Released' => 'Released',
        'Completed' => 'Completed',
        'Payment Verified' || 'For Approval' => 'Payment Verified',
        'Revision Required' => 'Revision Required',
        'Assessed' => 'Awaiting Payment',
        _ => applicantStatus,
      };

  /// A draft's number, since server migration 064 (QA TC-37, 2026-10-03), is a
  /// `DRAFT-` placeholder: the official E-BPCO number is assigned when the
  /// application is filed, so an abandoned draft leaves no gap in the numbering.
  bool get hasOfficialReference => !referenceNumber.startsWith(draftReferencePrefix);

  /// What to show for the application's number — the portal's `displayReference`.
  String get displayReference => hasOfficialReference ? referenceNumber : draftReferenceLabel;

  /// Finished one way or another: no progress to show, nothing "active" about it.
  bool get isClosed => closedStatuses.contains(lifecycleStatus);

  factory ApplicationSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    final orderOfPaymentJson = payment?['orderOfPayment'] as Map<String, dynamic>?;
    final pledgeJson = json['pledge'] as Map<String, dynamic>?;
    final form = (json['form'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final businessId = json['businessId'] as String?;
    final applyingAs = json['applyingAs'];
    return ApplicationSummary(
      id: json['id'] as String,
      referenceNumber: json['referenceNumber'] as String,
      permitType: json['permitType'] as String,
      applicationAction: json['applicationAction'] as String,
      businessId: businessId,
      businessName: json['businessName'] as String?,
      location: json['location'] as String?,
      renewsPermitNumber: json['renewsPermitNumber'] as String?,
      priorPermitClaim: json['priorPermitClaim'] as String?,
      lifecycleStatus: json['lifecycleStatus'] as String,
      applicantStatus: json['applicantStatus'] as String,
      requiresApplicantAction: json['requiresApplicantAction'] as bool? ?? false,
      dateSubmitted: json['dateSubmitted'] as String?,
      updatedAt: json['updatedAt'] as String? ?? '',
      openInstructionCount: json['openInstructionCount'] as int? ?? 0,
      form: form,
      pledge: pledgeJson == null ? null : Pledge.fromJson(pledgeJson),
      paymentStatus: payment?['status'] as String? ?? 'Not Yet Available',
      orderOfPayment: orderOfPaymentJson == null ? null : OrderOfPayment.fromJson(orderOfPaymentJson),
      applyingAs: applyingAs == applyingAsResidential || applyingAs == applyingAsBusiness
          ? applyingAs as String
          : applyingAsOf(form, businessId),
    );
  }
}

class TimelineEntry {
  final String status;
  final String occurredAt;
  final String? remarks;

  const TimelineEntry({required this.status, required this.occurredAt, required this.remarks});

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
        status: json['status'] as String,
        occurredAt: json['occurredAt'] as String,
        remarks: json['remarks'] as String?,
      );
}

/// A Letter of Instruction: what the office asked for when it returned an
/// application (`GET /applications/{id}/instructions`). Merged from
/// eBPCOMobile's letter of instruction; the citizen portal shows the same
/// items under "What the office needs from you".
class InstructionLetter {
  final String letterId;
  final String issuedAt;
  final List<InstructionItem> items;

  const InstructionLetter({required this.letterId, required this.issuedAt, required this.items});

  factory InstructionLetter.fromJson(Map<String, dynamic> json) => InstructionLetter(
        letterId: json['letterId'] as String,
        issuedAt: json['issuedAt'] as String,
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) => InstructionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One thing the office asked for, in the evaluator's own words.
class InstructionItem {
  final String id;
  final String subject;
  final String remark;
  final String? resolvedAt;

  const InstructionItem({required this.id, required this.subject, required this.remark, required this.resolvedAt});

  factory InstructionItem.fromJson(Map<String, dynamic> json) => InstructionItem(
        id: json['id'] as String,
        subject: json['subject'] as String? ?? '',
        remark: json['remark'] as String? ?? '',
        resolvedAt: json['resolvedAt'] as String?,
      );
}

/// The server's answer to "may this permit number be renewed or amended on
/// this filing?" — see `CitizenApi.renewalCheck`. [message] is written for
/// the citizen and shown under the permit number field as-is.
class RenewalCheck {
  final bool valid;
  final String? reason;
  final String? message;
  final String? permitNumber;
  final String? permitType;
  final String? businessName;
  final String? issuedDate;

  const RenewalCheck({
    required this.valid,
    this.reason,
    this.message,
    this.permitNumber,
    this.permitType,
    this.businessName,
    this.issuedDate,
  });

  factory RenewalCheck.fromJson(Map<String, dynamic> json) {
    final permit = json['permit'] as Map<String, dynamic>?;
    return RenewalCheck(
      valid: json['valid'] as bool,
      reason: json['reason'] as String?,
      message: json['message'] as String?,
      permitNumber: permit?['permitNumber'] as String?,
      permitType: permit?['permitType'] as String?,
      businessName: permit?['businessName'] as String?,
      issuedDate: permit?['issuedDate'] as String?,
    );
  }
}

class RequirementDoc {
  final String code;
  final String label;
  final String description;
  final bool required;
  final List<String> documentIds;
  final String status;

  /// How many paper copies the office also needs (ebpco-api 071): 0 unless
  /// the LGU asks; the BFP asks one. Absent (an older server) reads as 0.
  final int hardCopies;

  /// Where or why, under the count (the BFP's: where to submit it); null when there is none.
  final String? hardCopyNote;

  /// 'business' on a row asked only of a business application (the
  /// signatory's authority, ebpco-api 068); null on a row for everyone.
  final String? applicantKind;

  const RequirementDoc({
    required this.code,
    required this.label,
    required this.description,
    required this.required,
    required this.documentIds,
    required this.status,
    this.hardCopies = 0,
    this.hardCopyNote,
    this.applicantKind,
  });

  /// Asked only of a business application: the Requirements sheet lists it
  /// under "Business applications only".
  bool get isBusinessOnly => applicantKind == 'business';

  bool get isProvided => status == 'provided';

  static int _hardCopiesOf(Map<String, dynamic> json) => switch (json['hardCopies']) {
        final int n when n > 0 => n,
        _ => 0,
      };

  static String? _hardCopyNoteOf(Map<String, dynamic> json) => switch (json['hardCopyNote']) {
        final String note when note.trim().isNotEmpty => note.trim(),
        _ => null,
      };

  static String? _applicantKindOf(Map<String, dynamic> json) => switch (json['applicantKind']) {
        'residential' => 'residential',
        'business' => 'business',
        _ => null,
      };

  factory RequirementDoc.fromJson(Map<String, dynamic> json) => RequirementDoc(
        code: json['code'] as String,
        label: json['label'] as String,
        description: withoutIfApplicablePrefix(json['description'] as String?),
        required: json['required'] as bool? ?? true,
        documentIds: (json['documentIds'] as List<dynamic>?)?.cast<String>() ?? const [],
        status: json['status'] as String? ?? 'not-provided',
        hardCopies: _hardCopiesOf(json),
        hardCopyNote: _hardCopyNoteOf(json),
        applicantKind: _applicantKindOf(json),
      );

  /// From the pre-filing catalog (`GET /requirements/{permitType}`), which
  /// has no `documentIds`/`status` yet — nothing has been attached because
  /// no application exists yet.
  factory RequirementDoc.fromCatalogJson(Map<String, dynamic> json) => RequirementDoc(
        code: json['code'] as String,
        label: json['label'] as String,
        description: withoutIfApplicablePrefix(json['description'] as String?),
        required: json['required'] as bool? ?? true,
        documentIds: const [],
        status: 'not-provided',
        hardCopies: _hardCopiesOf(json),
        hardCopyNote: _hardCopyNoteOf(json),
        applicantKind: _applicantKindOf(json),
      );
}

/// The one line above a document list that says how documents are sent;
/// each one needing paper says so itself — the portal's `ONLINE_ONLY_NOTE`.
const onlineOnlyNote = 'Upload everything online. Paper copies only where marked.';

/// The chip on a document that needs paper copies ("Hard copies: 1"; ebpco-api
/// 071); null for one sent online only. "Online only" is said once above a
/// list ([onlineOnlyNote]), not on every row: 21 rows of "Online only, no hard
/// copy" buried the one real paper requirement (design review I13).
String? hardCopiesText(int hardCopies) => hardCopies > 0 ? 'Hard copies: $hardCopies' : null;

/// A description without the "Only if applicable:" it opens with on some
/// server rows: the section already says If applicable, and the two read as
/// the same words twice (design review I13) — the portal's
/// `withoutIfApplicablePrefix`. Empty for none.
String withoutIfApplicablePrefix(String? description) {
  final text = (description ?? '').trim();
  final rest = text.replaceFirst(RegExp(r'^only if applicable\s*[:—-]\s*', caseSensitive: false), '');
  if (rest == text || rest.isEmpty) return rest;
  return rest[0].toUpperCase() + rest.substring(1);
}

/// The tag on a document: needed before submitting, or only when the project
/// includes that work ("If applicable", not "Optional": LGU, 4 Nov 2026).
String requirementTag({required bool required}) => required ? 'Required' : 'If applicable';

class DocumentEntry {
  final String id;
  final String label;
  final String fileName;
  final String contentType;
  final String uploadedAt;
  final String? requirementCode;
  final bool scanCleared;
  final bool quarantined;
  final String? applicationId;
  final String? applicationReference;

  /// The officer's verdict. Null means nobody has looked yet — not "fine".
  final String? reviewStatus;
  final String? reviewReasonLabel;
  final String? reviewRemark;
  final String? supersedesDocumentId;
  final String? supersededByDocumentId;
  final String? expiresOn;

  /// Every application a copy of this FILE is on (`GET /documents/me` shows
  /// each file once, however many copies reuse made — ebpco-api 061). Empty
  /// from an older server and on an application's own document list.
  final List<String> usedOn;

  const DocumentEntry({
    required this.id,
    required this.label,
    required this.fileName,
    required this.contentType,
    required this.uploadedAt,
    required this.requirementCode,
    required this.scanCleared,
    required this.quarantined,
    required this.applicationId,
    required this.applicationReference,
    required this.reviewStatus,
    this.reviewReasonLabel,
    this.reviewRemark,
    this.supersedesDocumentId,
    this.supersededByDocumentId,
    this.expiresOn,
    this.usedOn = const [],
  });

  factory DocumentEntry.fromJson(Map<String, dynamic> json) => DocumentEntry(
        id: json['id'] as String,
        label: json['label'] as String,
        fileName: json['fileName'] as String,
        contentType: json['contentType'] as String,
        uploadedAt: json['uploadedAt'] as String,
        requirementCode: json['requirementCode'] as String?,
        scanCleared: json['scanCleared'] as bool? ?? false,
        quarantined: json['quarantined'] as bool? ?? false,
        applicationId: json['applicationId'] as String?,
        applicationReference: json['applicationReference'] as String?,
        reviewStatus: json['reviewStatus'] as String?,
        reviewReasonLabel: (json['reviewReason'] as Map<String, dynamic>?)?['label'] as String?,
        reviewRemark: json['reviewRemark'] as String?,
        supersedesDocumentId: json['supersedesDocumentId'] as String?,
        supersededByDocumentId: json['supersededByDocumentId'] as String?,
        expiresOn: json['expiresOn'] as String?,
        usedOn: [
          for (final application in (json['applications'] as List<dynamic>? ?? const []))
            if ((application as Map<String, dynamic>)['referenceNumber'] is String) application['referenceNumber'] as String,
        ],
      );

  /// The applications this file is on, for one line; null when none.
  String? get usedOnLabel {
    final references = usedOn.isNotEmpty ? usedOn : [?applicationReference];
    return references.isEmpty ? null : references.join(', ');
  }

  /// The portal's `rejectionExplanation`: cited reason and remark together.
  String? get explanation {
    final parts = [reviewReasonLabel, reviewRemark].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' — ');
  }

  /// The portal's `canResubmit`: the newest version, and the office asked.
  bool get canReplace =>
      supersededByDocumentId == null && (reviewStatus == 'Rejected' || reviewStatus == 'Revision Required');

  /// While the application is returned for revision the office's remarks may
  /// name a document it did not flag ("the Valid ID is expired"), so any
  /// document not yet accepted can be replaced, as the server allows. The
  /// portal's application-documents `canReplace`.
  bool canReplaceWhile({required bool returned}) =>
      canReplace || (returned && supersededByDocumentId == null && reviewStatus != 'Accepted');
}

/// The portal's `groupDocumentChains`: each current document with the
/// earlier versions it replaced, newest first.
List<({DocumentEntry current, List<DocumentEntry> superseded})> groupDocumentChains(List<DocumentEntry> docs) {
  final byId = {for (final d in docs) d.id: d};
  final chains = <({DocumentEntry current, List<DocumentEntry> superseded})>[];
  for (final head in docs.where((d) => d.supersededByDocumentId == null)) {
    final superseded = <DocumentEntry>[];
    final seen = {head.id};
    var cursor = head.supersedesDocumentId;
    while (cursor != null && byId.containsKey(cursor) && !seen.contains(cursor)) {
      final prev = byId[cursor]!;
      superseded.add(prev);
      seen.add(prev.id);
      cursor = prev.supersedesDocumentId;
    }
    chains.add((current: head, superseded: superseded));
  }
  final claimed = {for (final c in chains) ...[c.current.id, ...c.superseded.map((s) => s.id)]};
  for (final orphan in docs.where((d) => !claimed.contains(d.id))) {
    chains.add((current: orphan, superseded: const []));
  }
  return chains;
}

class PermitRelease {
  final String status;
  /// 'Courier Delivery' once a delivered permit is confirmed or closed (ebpco-api 070).
  final String? method;
  final String? releasedAt;

  /// Where, when and with what to collect it, as the Releasing Officer typed
  /// them. Null when not given, or from an older server.
  final String? claimLocation;
  final String? officeHours;
  final List<String> bringWithYou;

  const PermitRelease({
    required this.status,
    required this.method,
    required this.releasedAt,
    this.claimLocation,
    this.officeHours,
    this.bringWithYou = const [],
  });

  factory PermitRelease.fromJson(Map<String, dynamic> json) => PermitRelease(
        status: json['status'] as String,
        method: json['method'] as String?,
        releasedAt: json['releasedAt'] as String?,
        claimLocation: json['claimLocation'] as String?,
        officeHours: json['officeHours'] as String?,
        bringWithYou: (json['bringWithYou'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
      );
}

class PermitInfo {
  final String permitNumber;
  final String issuedDate;
  final String? scope;
  final List<String> conditions;
  final PermitRelease? release;

  /// What the permit prints about itself, since server migration 064 (QA
  /// TC-04, TC-18): its last valid day (YYYY-MM-DD), who approved it, for which
  /// office. Null on a permit issued without them, or from an older server.
  final String? expiresOn;
  final String? approvingOfficial;
  final String? approvingOffice;

  /// The Owner / Applicant block as the permit was issued, kept on the permit
  /// row since server migration 073, so a later profile edit does not rewrite
  /// an issued permit: each field null where nothing was on file (contact is
  /// the mobile number). Null as a whole from an older server, which sends no
  /// `ownerName`; the permit then prints the citizen's account, as before.
  final ({String? name, String? address, String? contact})? keptOwner;

  const PermitInfo({
    required this.permitNumber,
    required this.issuedDate,
    required this.scope,
    required this.conditions,
    required this.release,
    this.expiresOn,
    this.approvingOfficial,
    this.approvingOffice,
    this.keptOwner,
  });

  factory PermitInfo.fromJson(Map<String, dynamic> json) {
    final releaseJson = json['release'] as Map<String, dynamic>?;
    return PermitInfo(
      permitNumber: json['permitNumber'] as String,
      issuedDate: json['issuedDate'] as String,
      scope: json['scope'] as String?,
      conditions: (json['conditions'] as List<dynamic>?)?.cast<String>() ?? const [],
      release: releaseJson == null ? null : PermitRelease.fromJson(releaseJson),
      expiresOn: json['expiresOn'] as String?,
      approvingOfficial: json['approvingOfficial'] as String?,
      approvingOffice: json['approvingOffice'] as String?,
      keptOwner: json.containsKey('ownerName')
          ? (
              name: json['ownerName'] as String?,
              address: json['ownerAddress'] as String?,
              contact: json['ownerContact'] as String?,
            )
          : null,
    );
  }
}

class QuietHours {
  final bool enabled;
  final String start;
  final String end;
  const QuietHours({required this.enabled, required this.start, required this.end});

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
        enabled: json['enabled'] as bool? ?? false,
        start: json['start'] as String? ?? '22:00',
        end: json['end'] as String? ?? '07:00',
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'start': start, 'end': end};
}

const notificationCategories = ['applicationUpdates', 'payments', 'permitStatus', 'documentReminders', 'appointments', 'account'];
const notificationCategoryLabels = {
  'applicationUpdates': 'Application updates',
  'payments': 'Payments',
  'permitStatus': 'Permit status',
  'documentReminders': 'Document reminders',
  'appointments': 'Appointments',
  'account': 'Account',
};

class NotificationPreferences {
  final Map<String, bool> categories;
  final QuietHours quietHours;
  const NotificationPreferences({required this.categories, required this.quietHours});

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as Map<String, dynamic>?) ?? const {};
    return NotificationPreferences(
      categories: {for (final c in notificationCategories) c: rawCategories[c] as bool? ?? true},
      quietHours: QuietHours.fromJson((json['quietHours'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {'categories': categories, 'quietHours': quietHours.toJson()};
}

class NotificationEntry {
  final String id;
  final String type;
  final String category;
  final String? applicationId;
  final String title;
  final String body;
  final String? deepLink;
  final String createdAt;
  final String? readAt;
  final bool requiresAction;

  const NotificationEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.applicationId,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.createdAt,
    required this.readAt,
    required this.requiresAction,
  });

  bool get isRead => readAt != null;

  factory NotificationEntry.fromJson(Map<String, dynamic> json) => NotificationEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        category: json['category'] as String,
        applicationId: json['applicationId'] as String?,
        title: json['title'] as String,
        body: json['body'] as String,
        deepLink: json['deepLink'] as String?,
        createdAt: json['createdAt'] as String,
        readAt: json['readAt'] as String?,
        requiresAction: json['requiresAction'] as bool? ?? false,
      );
}

class CitizenProfile {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? street;
  final String? barangay;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? dateOfBirth;
  final String? sex;
  final String? civilStatus;
  final String? nationality;

  const CitizenProfile({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.mobileNumber,
    required this.street,
    required this.barangay,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.dateOfBirth,
    required this.sex,
    required this.civilStatus,
    required this.nationality,
  });

  String get fullName => [firstName, middleName, lastName].where((p) => p != null && p.isNotEmpty).join(' ');

  static Map<String, dynamic> _base(Map<String, dynamic> json) => json;

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    final j = _base(json);
    return CitizenProfile(
      firstName: j['firstName'] as String?,
      middleName: j['middleName'] as String?,
      lastName: j['lastName'] as String?,
      mobileNumber: j['mobileNumber'] as String?,
      street: j['street'] as String?,
      barangay: j['barangay'] as String?,
      city: j['city'] as String?,
      province: j['province'] as String?,
      postalCode: j['postalCode'] as String?,
      dateOfBirth: j['dateOfBirth'] as String?,
      sex: j['sex'] as String?,
      civilStatus: j['civilStatus'] as String?,
      nationality: j['nationality'] as String?,
    );
  }
}

class MeProfile extends CitizenProfile {
  final String id;
  final String email;
  final String? emailVerifiedAt;
  final String? mobileVerifiedAt;
  final bool hasPhoto;

  /// What the citizen said at sign-up they will mainly apply for:
  /// 'residential', 'business', 'both', or null (never asked). Only a
  /// starting point for the wizard's "Applying as".
  final String? registeredAs;

  /// Where the account's verification stands (ebpco-api 067); null from an
  /// older server. Filing needs 'verified'.
  final AccountVerification? verification;

  const MeProfile({
    required this.id,
    required this.email,
    required this.emailVerifiedAt,
    required this.mobileVerifiedAt,
    required this.hasPhoto,
    this.registeredAs,
    this.verification,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.mobileNumber,
    required super.street,
    required super.barangay,
    required super.city,
    required super.province,
    required super.postalCode,
    required super.dateOfBirth,
    required super.sex,
    required super.civilStatus,
    required super.nationality,
  });

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    final base = CitizenProfile.fromJson(json);
    return MeProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      mobileVerifiedAt: json['mobileVerifiedAt'] as String?,
      hasPhoto: json['hasPhoto'] as bool? ?? false,
      registeredAs: json['registeredAs'] as String?,
      verification: json['verification'] is Map<String, dynamic>
          ? AccountVerification.fromJson(json['verification'] as Map<String, dynamic>)
          : null,
      firstName: base.firstName,
      middleName: base.middleName,
      lastName: base.lastName,
      mobileNumber: base.mobileNumber,
      street: base.street,
      barangay: base.barangay,
      city: base.city,
      province: base.province,
      postalCode: base.postalCode,
      dateOfBirth: base.dateOfBirth,
      sex: base.sex,
      civilStatus: base.civilStatus,
      nationality: base.nationality,
    );
  }
}

class Business {
  final String id;
  final String name;
  final String category;
  final String street;
  final String barangay;
  final String city;
  final String province;
  final String registrationNumber;
  final String dateRegistered;
  final String status;

  /// In the Municipality's business registry before eBPCO, imported from it
  /// and matched to this account by an officer (ebpco-api 069). Shown as
  /// "Issued before eBPCO"; the citizen files for it like any other
  /// business. False from an older server.
  final bool importedBeforeEbpco;

  const Business({
    required this.id,
    required this.name,
    required this.category,
    required this.street,
    required this.barangay,
    required this.city,
    required this.province,
    required this.registrationNumber,
    required this.dateRegistered,
    required this.status,
    this.importedBeforeEbpco = false,
  });

  bool get isActive => status == 'Active';

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        street: json['street'] as String,
        barangay: json['barangay'] as String,
        city: json['city'] as String,
        province: json['province'] as String,
        registrationNumber: json['registrationNumber'] as String,
        dateRegistered: json['dateRegistered'] as String,
        status: json['status'] as String,
        importedBeforeEbpco: json['importedBeforeEbpco'] == true,
      );
}

class PaymentEntry {
  final String id;
  final String referenceNumber;
  final String method;
  final int amountCentavos;
  final String status;
  final String submittedAt;
  final String? verifiedAt;
  final String? officialReceiptNumber;
  final String? rejectionReason;

  /// Why a settled payment was later Voided, Reversed or Refunded.
  final String? exceptionReason;

  const PaymentEntry({
    required this.id,
    required this.referenceNumber,
    required this.method,
    required this.amountCentavos,
    required this.status,
    required this.submittedAt,
    required this.verifiedAt,
    required this.officialReceiptNumber,
    required this.rejectionReason,
    this.exceptionReason,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
        id: json['id'] as String,
        referenceNumber: json['referenceNumber'] as String,
        method: json['method'] as String,
        amountCentavos: json['amountCentavos'] as int,
        status: json['status'] as String,
        submittedAt: json['submittedAt'] as String,
        verifiedAt: json['verifiedAt'] as String?,
        officialReceiptNumber: json['officialReceiptNumber'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        exceptionReason: json['exceptionReason'] as String?,
      );
}

class ErasureReceipt {
  final String acceptedAt;
  final List<String> erasedCategories;
  final List<RetainedCategory> retainedCategories;

  const ErasureReceipt({required this.acceptedAt, required this.erasedCategories, required this.retainedCategories});

  factory ErasureReceipt.fromJson(Map<String, dynamic> json) => ErasureReceipt(
        acceptedAt: json['acceptedAt'] as String,
        erasedCategories: (json['erasedCategories'] as List<dynamic>?)?.cast<String>() ?? const [],
        retainedCategories: (json['retainedCategories'] as List<dynamic>?)
                ?.map((e) => RetainedCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class RetainedCategory {
  final String category;
  final String basis;
  final String? until;
  const RetainedCategory({required this.category, required this.basis, required this.until});
  factory RetainedCategory.fromJson(Map<String, dynamic> json) => RetainedCategory(
        category: json['category'] as String,
        basis: json['basis'] as String,
        until: json['until'] as String?,
      );
}
