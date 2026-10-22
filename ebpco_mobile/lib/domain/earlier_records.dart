/// Records before eBPCO (ebpco-api migration 069): the permits the
/// Municipality issued on paper before eBPCO, imported from its register and
/// matched to a citizen's account by an officer, and the citizen's own
/// "this earlier permit is mine" requests. The citizen sees them labelled,
/// never mixed in with the applications they filed through eBPCO. The
/// portal's `core/domain/earlier-records.ts` decides the same way, in the
/// same words.
library;

import 'package:intl/intl.dart';

import '../core/api/problem.dart';
import 'permit_catalog.dart';

/// The label on every earlier permit, and on a business from the registry.
const String beforeEbpcoLabel = 'Issued before eBPCO';

/// A business is registered, not issued: its badge says so.
const String registeredBeforeEbpcoLabel = 'Registered before eBPCO';

/// Said once over the earlier permits: there is nothing to track, download or print.
const String beforeEbpcoNote =
    "Issued on paper before eBPCO. Keep your paper permit; this is the Municipality's register record.";

/// The answer to a sent request — the same whether or not the number is in
/// the register, so it never tells anyone which permits the Municipality holds.
const String earlierClaimSent = 'Sent. The Municipality will check its register and tell you.';

/// The permit number alone is not enough to ask with.
const String earlierClaimRule = 'Give the date issued or the OR number — at least one.';

/// `GET /me/earlier-permits`: a permit from the Municipality's register, once
/// an officer has matched it to this account. Finished history.
class EarlierPermit {
  final String id;

  /// eBPCO's own reference for the record, `PRE-<year>-<NNNNNN>`.
  final String referenceNumber;
  final String permitType;

  /// The number on the paper permit, as the register writes it (it may hold
  /// `/`, `.` or spaces).
  final String permitNumber;

  /// YYYY-MM-DD.
  final String dateIssued;

  /// YYYY-MM-DD, or null when the register gives none.
  final String? validUntil;
  final String? location;
  final String? scopeOfWork;
  final String? businessName;

  /// The business it was issued for, when that business is on this account.
  final String? businessId;
  final String? issuedBy;

  /// The register's own page or logbook reference.
  final String? registerRef;

  const EarlierPermit({
    required this.id,
    required this.referenceNumber,
    required this.permitType,
    required this.permitNumber,
    required this.dateIssued,
    this.validUntil,
    this.location,
    this.scopeOfWork,
    this.businessName,
    this.businessId,
    this.issuedBy,
    this.registerRef,
  });

  factory EarlierPermit.fromJson(Map<String, dynamic> json) => EarlierPermit(
        id: json['id'] as String,
        referenceNumber: json['referenceNumber'] as String? ?? '',
        permitType: json['permitType'] as String,
        permitNumber: json['permitNumber'] as String,
        dateIssued: json['dateIssued'] as String,
        validUntil: _text(json['validUntil']),
        location: _text(json['location']),
        scopeOfWork: _text(json['scopeOfWork']),
        businessName: _text(json['businessName']),
        businessId: _text(json['businessId']),
        issuedBy: _text(json['issuedBy']),
        registerRef: _text(json['registerRef']),
      );
}

/// `GET`/`POST /me/record-claims`: "this permit from before eBPCO is mine",
/// decided by an officer.
class RecordClaim {
  final String id;
  final String permitNumber;

  /// YYYY-MM-DD, as the citizen gave it.
  final String? dateIssued;
  final String? orNumber;

  /// 'pending', 'confirmed' or 'rejected'.
  final String status;

  /// The officer's note; when declined, the reason.
  final String? note;
  final String createdAt;
  final String? decidedAt;

  const RecordClaim({
    required this.id,
    required this.permitNumber,
    required this.status,
    required this.createdAt,
    this.dateIssued,
    this.orNumber,
    this.note,
    this.decidedAt,
  });

  factory RecordClaim.fromJson(Map<String, dynamic> json) => RecordClaim(
        id: json['id'] as String,
        permitNumber: json['permitNumber'] as String,
        dateIssued: _text(json['dateIssued']),
        orNumber: _text(json['orNumber']),
        status: json['status'] as String,
        note: _text(json['note']),
        createdAt: json['createdAt'] as String,
        decidedAt: _text(json['decidedAt']),
      );

  bool get isWaiting => status == 'pending';
}

String? _text(Object? value) => value is String && value.trim().isNotEmpty ? value : null;

/// Today's date in Castilla (Asia/Manila, UTC+8 all year), YYYY-MM-DD,
/// whatever the phone's own time zone.
String manilaToday([DateTime? now]) =>
    DateFormat('yyyy-MM-dd').format((now ?? DateTime.now()).toUtc().add(const Duration(hours: 8)));

/// 'Valid' or 'Expired' by the date the register gives; null when it gives
/// none. The last day itself still counts as Valid.
String? earlierPermitStanding(String? validUntil, String today) {
  if (validUntil == null || validUntil.isEmpty) return null;
  final lastDay = validUntil.length > 10 ? validUntil.substring(0, 10) : validUntil;
  return lastDay.compareTo(today) >= 0 ? 'Valid' : 'Expired';
}

/// A permit type eBPCO still files, so the earlier permit can be renewed
/// through the application wizard (the retired BFP types cannot).
bool canRenewEarlierPermit(String permitType) =>
    permitTypeGroups.any((group) => group.types.contains(permitType));

/// The words on a request's status pill.
String claimStatusLabel(String status) => switch (status) {
      'pending' => 'Waiting',
      'confirmed' => 'Confirmed',
      'rejected' => 'Not confirmed',
      _ => status,
    };

/// A register date (YYYY-MM-DD) or a timestamp, as the citizen reads it.
String registerDay(String value) {
  final dateOnly = value.length == 10;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('MMM d, y').format(dateOnly ? parsed : parsed.toLocal());
}

/// What the citizen gave on a request, and when they sent it.
String claimDetails(RecordClaim claim) => [
      if (claim.dateIssued != null) 'Date issued ${registerDay(claim.dateIssued!)}',
      if (claim.orNumber != null) 'OR ${claim.orNumber}',
      'Sent ${registerDay(claim.createdAt)}',
    ].join(' · ');

/// The permit number as it is sent: inner runs of spaces made one, ends trimmed.
String claimPermitNumber(String typed) => typed.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Why "Find my earlier permits" cannot be sent yet, or null. The server
/// refuses the same (400), so this only saves the citizen the round trip.
String? earlierClaimProblem({required String permitNumber, required String? dateIssued, required String orNumber}) {
  if (claimPermitNumber(permitNumber).length < 2) {
    return 'Type the permit number as it is printed on your paper permit.';
  }
  if ((dateIssued == null || dateIssued.isEmpty) && orNumber.trim().isEmpty) return earlierClaimRule;
  return null;
}

/// What to show when a request is refused: a 400 names its problem in
/// `errors[]` and carries no `detail`; a 409 (already waiting) or 429 (ten
/// waiting) says it in `detail`.
String earlierClaimMessage(Object error) {
  if (error is! ApiError) {
    return "We could not reach the Municipality's system. Check your connection and try again.";
  }
  final problem = error.problem;
  if ((problem?.detail ?? '').isEmpty) {
    final named = (problem?.fieldErrors ?? const <FieldError>[]).map((f) => f.message).where((m) => m.isNotEmpty).join(' ');
    if (named.isNotEmpty) return named;
  }
  return error.citizenMessage;
}
