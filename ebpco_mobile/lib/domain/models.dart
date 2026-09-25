/// Wire models for the citizen-facing eBPCO API, ported field-for-field
/// from `ebpco-user-portal/src/app/core/api/citizen-api.models.ts` — that
/// file is itself pinned against `contract/citizen-endpoints.openapi.yaml`
/// in eBPCOBackend, so these describe what the server actually sends, not
/// what this app imagines it sends.
library;

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

  const OrderOfPayment({required this.number, required this.assessedAt, required this.dueDate, required this.totalCentavos});

  factory OrderOfPayment.fromJson(Map<String, dynamic> json) => OrderOfPayment(
        number: json['number'] as String,
        assessedAt: json['assessedAt'] as String,
        dueDate: json['dueDate'] as String?,
        totalCentavos: json['totalCentavos'] as int,
      );
}

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
  /// The raw, 19-value internal status (e.g. "Under Evaluation").
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
  });

  factory ApplicationSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    final orderOfPaymentJson = payment?['orderOfPayment'] as Map<String, dynamic>?;
    final pledgeJson = json['pledge'] as Map<String, dynamic>?;
    return ApplicationSummary(
      id: json['id'] as String,
      referenceNumber: json['referenceNumber'] as String,
      permitType: json['permitType'] as String,
      applicationAction: json['applicationAction'] as String,
      businessId: json['businessId'] as String?,
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
      form: (json['form'] as Map<String, dynamic>?) ?? const {},
      pledge: pledgeJson == null ? null : Pledge.fromJson(pledgeJson),
      paymentStatus: payment?['status'] as String? ?? 'Not Yet Available',
      orderOfPayment: orderOfPaymentJson == null ? null : OrderOfPayment.fromJson(orderOfPaymentJson),
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

class RequirementDoc {
  final String code;
  final String label;
  final String description;
  final bool required;
  final List<String> documentIds;
  final String status;

  const RequirementDoc({
    required this.code,
    required this.label,
    required this.description,
    required this.required,
    required this.documentIds,
    required this.status,
  });

  bool get isProvided => status == 'provided';

  factory RequirementDoc.fromJson(Map<String, dynamic> json) => RequirementDoc(
        code: json['code'] as String,
        label: json['label'] as String,
        description: json['description'] as String? ?? '',
        required: json['required'] as bool? ?? true,
        documentIds: (json['documentIds'] as List<dynamic>?)?.cast<String>() ?? const [],
        status: json['status'] as String? ?? 'not-provided',
      );

  /// From the pre-filing catalog (`GET /requirements/{permitType}`), which
  /// has no `documentIds`/`status` yet — nothing has been attached because
  /// no application exists yet.
  factory RequirementDoc.fromCatalogJson(Map<String, dynamic> json) => RequirementDoc(
        code: json['code'] as String,
        label: json['label'] as String,
        description: json['description'] as String? ?? '',
        required: json['required'] as bool? ?? true,
        documentIds: const [],
        status: 'not-provided',
      );
}

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
  final String? reviewStatus;

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
    required this.reviewStatus,
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
        reviewStatus: json['reviewStatus'] as String?,
      );
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

  const MeProfile({
    required this.id,
    required this.email,
    required this.emailVerifiedAt,
    required this.mobileVerifiedAt,
    required this.hasPhoto,
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
