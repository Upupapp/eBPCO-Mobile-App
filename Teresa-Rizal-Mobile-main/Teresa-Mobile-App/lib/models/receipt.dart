/// A generated receipt for one Dokyu request — FRONTEND SIMULATION ONLY,
/// see [ReceiptType]'s own doc comment. Generated once, synchronously,
/// the moment RequestsService.submit() creates the request — payment (when
/// the service has a real fee) happens during the application flow itself,
/// before the request exists, never as a later tracking milestone — and
/// then persisted on that request's own [Receipt] field for the rest of
/// the demo session. Tulong requests never get one (assistance
/// applications have no receipt concept).
enum ReceiptType {
  gcash,
  maya,
  onsite,

  /// A Free Dokyu service — still generates a formality/claim-stub
  /// receipt (so "Documents Uploaded"/Transactions/View Receipt keep
  /// working uniformly for every Dokyu request), but never with an
  /// invented monetary amount.
  free,

  /// A persisted receipt whose payment type this build cannot read — a value
  /// renamed or removed since it was written.
  ///
  /// **Never generated.** It exists only so [Receipt.fromJson] has something
  /// honest to decode into. The previous fallback was [onsite], which meant an
  /// unreadable payment type rendered on the citizen's own proof of payment as
  /// an on-site cash payment: a GCash or Maya payment shown as cash, or a free
  /// service shown as due at the municipal office. That is a fabricated
  /// statement about money, which this project forbids.
  ///
  /// Every display of it must say so rather than guess — "—", never a method,
  /// never PAID and never DUE. The receipt itself is still shown, because the
  /// amount, date, reference and service on it are all still true.
  unknown,
}

class Receipt {
  final ReceiptType type;

  /// The catalog item's own fee text (e.g. "₱50.00") — never a value
  /// copied from a visual reference screenshot.
  final String amount;

  /// A generated demo transaction/reference number — local only, never a
  /// real payment gateway's identifier.
  final String referenceNumber;

  final DateTime dateTime;
  final String residentName;
  final String serviceName;

  /// The request's own reference number (e.g. "DOC-2026-001"), shown on
  /// the receipt alongside the transaction reference above.
  final String requestReferenceNumber;

  const Receipt({
    required this.type,
    required this.amount,
    required this.referenceNumber,
    required this.dateTime,
    required this.residentName,
    required this.serviceName,
    required this.requestReferenceNumber,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amount': amount,
        'referenceNumber': referenceNumber,
        'dateTime': dateTime.toIso8601String(),
        'residentName': residentName,
        'serviceName': serviceName,
        'requestReferenceNumber': requestReferenceNumber,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        // Falls back to `unknown`, never to a payment method: see
        // ReceiptType.unknown. Claiming cash for an unreadable value is a
        // false statement about how this citizen paid.
        type: ReceiptType.values.firstWhere((t) => t.name == json['type'], orElse: () => ReceiptType.unknown),
        amount: json['amount'],
        referenceNumber: json['referenceNumber'],
        dateTime: DateTime.parse(json['dateTime']),
        residentName: json['residentName'],
        serviceName: json['serviceName'],
        requestReferenceNumber: json['requestReferenceNumber'],
      );
}
