/// The printed permit's one field map (design review I3, 4 Nov 2026): the
/// office's copy (the Admin Portal's preview) and the citizen's disagreed on
/// about six fields for the same permit, which made one of them look forged.
/// Every label the app's permit shows comes from here, in this order — the
/// Citizen Portal's `core/domain/permit-fields.ts`, which the Admin Portal
/// prints too. Pinned, copied, in test/permit_fields_test.dart; change all
/// three together.
///
/// Sources: the owner's name, contact and address from the citizen's account
/// (the application record carries no owner; a snapshot on the permit row is
/// a backend job, as on both portals); Location from the application's own
/// site, printed once; Business name only on a business application, so the
/// occupancy is the only statement of use.
library;

import 'assessment_view.dart';
import 'dates.dart';
import 'lgu_contact.dart';
import 'models.dart';
import 'occupancy.dart';
import 'property_address.dart';
import 'reviewing_office.dart';

abstract final class PermitLabels {
  static const permitNo = 'Permit No.';
  static const applicationNo = 'Application No.';
  static const dateIssued = 'Date issued';
  static const validUntil = 'Valid until';
  static const ownerName = 'Owner / Permittee name';
  static const businessName = 'Business name';
  static const contactNumber = 'Contact number';
  static const address = 'Address';
  static const location = 'Location';
  static const applicationType = 'Application type';
  static const dateApplied = 'Date applied';
  static const occupancy = occupancyFieldLabel;
  static const scope = 'Scope';
  static const fee = 'Fee';
  static const amount = 'Amount';
  static const totalAmountDue = totalAmountDueLabel;
  static const balance = balanceLabel;
  static const orderOfPaymentNo = 'Order of Payment No.';
}

/// The rows that take a line of their own on A4.
const permitWideLabels = {PermitLabels.address, PermitLabels.location, PermitLabels.occupancy, PermitLabels.scope};

/// The permit's sections, in order. "Owner / Applicant" mirrors BOX 1 of the
/// LGU's Unified Application Form, so it is not "Citizen".
const permitSections = ['Owner / Applicant', 'Property', 'Project', 'Assessment / Payment', 'Conditions', 'Approval'];

/// What the Conditions section says when the office recorded none: a fact,
/// in normal ink, never a warning (it told the citizen to ask another office
/// before relying on the permit).
const noConditionsNote = 'No conditions were recorded by the office.';

/// The Approval block's line over the signature: an issued permit says where
/// the signed copy is ("Pending Authorized Signature" stayed on issued ones).
const signedCopyNote = 'Signed copy available at the release desk';
const pendingSignatureNote = 'Pending authorized signature';

/// A value the office left out when it issued the permit.
const notRecorded = 'Not recorded';

/// What a Certificate of Occupancy says under "Valid until": it has no fixed
/// term (the backend fills an expiry for every other type, 12 or 6 months).
const String occupancyNoExpiry = "No fixed expiry (valid while the building's use and occupancy stay the same)";

/// "Valid until" on the printed permit: the date the office recorded at issue;
/// for a Certificate of Occupancy with none, that it does not expire; for any
/// other type with none (an old permit), a neutral "Not recorded".
String permitValidUntil({required bool issued, required String permitType, String? expiresOn}) {
  if (!issued) return 'Not yet assigned';
  final date = expiresOn?.trim() ?? '';
  if (date.isNotEmpty) return formatDate(date);
  return permitType == 'Certificate of Occupancy' ? occupancyNoExpiry : notRecorded;
}

/// The Approval block's name and position, as the portal prints them: who
/// approved it, as recorded at issue (QA TC-04, TC-18), else "Not recorded";
/// for which office, else the permit type's issuing [office] (design review
/// I5).
({String name, String position}) permitApproval({
  required bool issued,
  String? approvingOfficial,
  String? approvingOffice,
  required String office,
}) {
  String? recorded(String? value) => (value?.trim().isEmpty ?? true) ? null : value!.trim();
  return (
    name: (issued ? recorded(approvingOfficial) : null) ?? notRecorded,
    position: (issued ? recorded(approvingOffice) : null) ?? office,
  );
}

/// The assessment on the permit: the fees, then Total amount due and Balance,
/// and the Order of Payment's number under the table.
typedef PermitAssessment = ({List<(String, String)> fees, String total, String balance, String orderNumber});

/// Everything the printed permit shows, worked out once from the records, so
/// the screen only lays it out and a test can read it.
class PermitDocumentContent {
  const PermitDocumentContent({
    required this.office,
    required this.title,
    required this.number,
    required this.numberPending,
    required this.facts,
    required this.owner,
    required this.property,
    required this.project,
    required this.assessment,
    required this.conditions,
    required this.approvalNote,
    required this.approvalName,
    required this.approvalPosition,
    required this.verificationUrl,
    required this.permitNumber,
    required this.footer,
  });

  /// The office the header and the signature name (the permit type's issuer).
  final String office;
  final String title;
  final String number;
  final bool numberPending;

  /// Application No., Date issued, Valid until.
  final List<(String, String)> facts;
  final List<(String, String)> owner;
  final List<(String, String)> property;
  final List<(String, String)> project;

  /// Null until an Order of Payment is issued.
  final PermitAssessment? assessment;

  /// The office's conditions, every one, verbatim; empty when none was recorded.
  final List<String> conditions;
  final String approvalNote;
  final String approvalName;
  final String approvalPosition;

  /// The verification link the QR code holds, once the permit is issued.
  final String? verificationUrl;
  final String? permitNumber;
  final List<String> footer;

  /// Every label the permit shows, in reading order: what the field map pins.
  List<String> get labels => [
        PermitLabels.permitNo,
        for (final (label, _) in [...facts, ...owner, ...property, ...project]) label,
        if (assessment != null) ...[
          PermitLabels.fee,
          PermitLabels.amount,
          PermitLabels.totalAmountDue,
          PermitLabels.balance,
          PermitLabels.orderOfPaymentNo,
        ],
      ];
}

/// The printed permit for [app], from its permit record ([permit], null until
/// issued), the citizen's account ([owner]), the business it names, and the
/// citizen portal's address for the verification link ([verifyBaseUrl]).
PermitDocumentContent permitDocumentContent({
  required ApplicationSummary app,
  PermitInfo? permit,
  CitizenProfile? owner,
  Business? business,
  required String verifyBaseUrl,
  DateTime? now,
}) {
  final office = reviewingOfficeFor(app.permitType);
  final issued = permit != null;
  final approval = permitApproval(
    issued: issued,
    approvingOfficial: permit?.approvingOfficial,
    approvingOffice: permit?.approvingOffice,
    office: office,
  );
  final order = app.orderOfPayment;
  String onFile(String? value) => (value?.trim().isEmpty ?? true) ? 'Not on file' : value!.trim();
  final address = owner == null ? '' : addressLine([owner.street, owner.barangay, owner.city, owner.province]);
  final fullName = owner?.fullName ?? '';

  return PermitDocumentContent(
    office: office,
    title: app.permitType,
    number: permit?.permitNumber ?? 'Not yet assigned',
    numberPending: !issued,
    facts: [
      (PermitLabels.applicationNo, app.displayReference),
      (PermitLabels.dateIssued, permit == null ? 'Not yet assigned' : formatDate(permit.issuedDate)),
      (
        PermitLabels.validUntil,
        permitValidUntil(issued: issued, permitType: app.permitType, expiresOn: permit?.expiresOn),
      ),
    ],
    owner: [
      (PermitLabels.ownerName, onFile(fullName)),
      // Only a business application names a business (design review I6).
      if (app.businessNameOnDocument case final name?) (PermitLabels.businessName, name),
      (PermitLabels.contactNumber, onFile(owner?.mobileNumber)),
      // The whole address, as the Admin Portal prints it; it printed the street alone.
      (PermitLabels.address, onFile(address)),
    ],
    property: [
      for (final (_, value) in propertyRows(location: app.location, business: business)) (PermitLabels.location, value),
    ],
    project: [
      (PermitLabels.applicationType, app.applicationAction),
      (PermitLabels.dateApplied, app.dateSubmitted != null ? formatDate(app.dateSubmitted!) : 'Pending'),
      // As filed (ebpco-api 071); left out when absent.
      if (occupancyLabelOf(app.form) case final use?) (PermitLabels.occupancy, use),
      if (permit?.scope case final scope? when scope.trim().isNotEmpty) (PermitLabels.scope, scope.trim()),
    ],
    assessment: order == null
        ? null
        : (
            fees: [for (final line in feeLinesOf(order)) (line.name, pesos(line.amountCentavos))],
            total: pesos(order.totalCentavos),
            balance: pesos(balanceOf(order, paymentStatus: app.paymentStatus)),
            orderNumber: order.number,
          ),
    conditions: permit?.conditions ?? const [],
    approvalNote: issued ? signedCopyNote : pendingSignatureNote,
    approvalName: approval.name,
    approvalPosition: approval.position,
    verificationUrl: permit == null ? null : '$verifyBaseUrl/verify/${Uri.encodeComponent(permit.permitNumber)}',
    permitNumber: permit?.permitNumber,
    footer: [
      issued
          ? 'This is a system-generated document issued by the Municipality of Castilla, Sorsogon.'
          : 'This is a system-generated preview produced by the eBPCO portal. It is not an issued permit and has '
              'no legal effect. Only the Municipality of Castilla, Sorsogon issues permits.',
      // The application's reference number, never its internal id.
      'Document Ref. ${app.displayReference} · Generated ${formatMoment(now ?? DateTime.now())} · Page 1 of 1',
    ],
  );
}

/// The receipt's and Order of Payment's office lines, the portal's words.
abstract final class PaymentDocumentText {
  /// The Order of Payment's note under its fees.
  static String orderPayNote(String? feeScheduleVersion) =>
      '${feeScheduleVersion == null ? '' : 'Fee schedule $feeScheduleVersion. '}Pay the full amount at the '
      '${municipalTreasurer.name} (${municipalTreasurer.cashierLabel}), ${municipalTreasurer.place}, and keep the '
      'Official Receipt it gives you.';

  /// The Order of Payment's footer.
  static const orderFooter = 'A copy of the Order of Payment issued through eBPCO by the Municipality of Castilla, '
      "Sorsogon. Present it at the Municipal Treasurer's Office when you pay.";

  /// The receipt's footer: a GCash payment has no stamped paper receipt to
  /// call the original (whether the Treasurer issues one is a question for
  /// the LGU); one paid in person does.
  static String receiptFooter({
    required bool verified,
    required String method,
    required String reference,
    String? orNumber,
  }) {
    if (verified && method == 'GCash') {
      return 'This is an electronic copy of an Official Receipt recorded by the Municipality of Castilla, Sorsogon. '
          'Paid online through GCash, ref $reference; Official Receipt No. $orNumber recorded by the '
          '${municipalTreasurer.cashierLabel}.';
    }
    if (verified) {
      return 'This is an electronic copy of an Official Receipt recorded by the Municipality of Castilla, Sorsogon. '
          'The stamped paper receipt from the ${municipalTreasurer.name} is the original.';
    }
    return 'This is a system-generated preview produced by the eBPCO portal. It is not an issued Official Receipt '
        "and has no legal effect. Only the Municipality of Castilla's Treasurer's Office issues an Official Receipt, "
        'upon verifying a payment it actually received.';
  }

  /// The receipt footer's reference: the OR number, else the Order of
  /// Payment's, else the application's. Never the payment's internal id.
  static String receiptReference({String? orNumber, String? orderNumber, required String applicationNumber}) =>
      orNumber ?? orderNumber ?? applicationNumber;
}
