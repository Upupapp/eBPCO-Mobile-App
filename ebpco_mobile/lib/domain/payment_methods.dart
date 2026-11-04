/// How a citizen may pay an Order of Payment (ebpco-api 071): the methods the
/// LGU accepts right now (`GET /payment-methods`), and the GCash checkout. The
/// same rules and words as the citizen portal's `payment-flow.page.ts`.
library;

import 'models.dart';

const paymentMethodBankTransfer = 'Bank Transfer';
const paymentMethodGcash = 'GCash';
const paymentMethodOnsite = 'Onsite';

/// The methods this app can take a payment by; any other the server lists is
/// left out.
const knownPaymentMethods = {paymentMethodBankTransfer, paymentMethodGcash, paymentMethodOnsite};

/// One method the LGU accepts, as `GET /payment-methods` lists it. [mode] is
/// 'test' for GCash while there is no merchant account: no money moves.
class PaymentMethodOption {
  final String method;
  final String label;
  final String instructions;
  final String? mode;

  const PaymentMethodOption({required this.method, required this.label, this.instructions = '', this.mode});

  bool get isTestMode => mode == 'test';

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => PaymentMethodOption(
        method: json['method'] as String? ?? '',
        label: json['label'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        mode: json['mode'] as String?,
      );
}

const onsiteOption = PaymentMethodOption(method: paymentMethodOnsite, label: 'Onsite');

/// What the screen offered before the server listed methods: Onsite, and Bank
/// Transfer once a deposit account is published.
List<PaymentMethodOption> localPaymentMethods({required bool bankPublished}) => [
      if (bankPublished) const PaymentMethodOption(method: paymentMethodBankTransfer, label: 'Bank Transfer'),
      onsiteOption,
    ];

/// What the server listed, less what this app cannot offer: a method it does
/// not know, and Bank Transfer while no deposit account is published. Nothing
/// left (or nothing read) is Onsite, as before the list existed.
List<PaymentMethodOption> offeredPaymentMethods(List<PaymentMethodOption> listed, {required bool bankPublished}) {
  final usable = listed
      .where((m) => knownPaymentMethods.contains(m.method) && (m.method != paymentMethodBankTransfer || bankPublished))
      .toList();
  return usable.isEmpty ? const [onsiteOption] : usable;
}

/// Bank Transfer first once it is offered (as before), else Onsite, else what there is.
String defaultPaymentMethod(List<PaymentMethodOption> offered) {
  for (final preferred in const [paymentMethodBankTransfer, paymentMethodOnsite]) {
    if (offered.any((m) => m.method == preferred)) return preferred;
  }
  return offered.isEmpty ? paymentMethodOnsite : offered.first.method;
}

/// The card's title.
String paymentMethodTitle(PaymentMethodOption m) => switch (m.method) {
      paymentMethodBankTransfer => 'Bank Transfer',
      paymentMethodGcash => 'GCash',
      paymentMethodOnsite => 'Onsite Payment',
      _ => m.label,
    };

/// The line under the card's title.
String paymentMethodBlurb(PaymentMethodOption m) => switch (m.method) {
      paymentMethodGcash => m.isTestMode ? 'Pay online. Test mode: no real money is charged.' : 'Pay online with GCash.',
      paymentMethodBankTransfer => "Deposit to the Municipality's account, then upload the proof.",
      _ => 'Pay at the Municipal Hall, then mark it paid here.',
    };

/// A GCash checkout just opened (`POST /applications/{id}/payments/gcash`):
/// the page to pay on, for the Order of Payment's amount.
class GcashCheckout {
  final String checkoutId;

  /// `GC-TEST-…` in test mode: the payment's reference once paid.
  final String reference;
  final int amountCentavos;
  final String expiresAt;
  final String mode;
  final String checkoutUrl;

  const GcashCheckout({
    required this.checkoutId,
    required this.reference,
    required this.amountCentavos,
    required this.expiresAt,
    required this.mode,
    required this.checkoutUrl,
  });

  factory GcashCheckout.fromJson(Map<String, dynamic> json) => GcashCheckout(
        checkoutId: json['checkoutId'] as String,
        reference: json['reference'] as String? ?? '',
        // The exact integer; `amount` (pesos) is for display only.
        amountCentavos: json['amountCentavos'] as int? ?? ((json['amount'] as num? ?? 0) * 100).round(),
        expiresAt: json['expiresAt'] as String? ?? '',
        mode: json['mode'] as String? ?? '',
        checkoutUrl: json['checkoutUrl'] as String,
      );
}

/// After the citizen comes back from the checkout: whether the payment
/// reached the Cashier (the application then reads Payment Submitted), or is
/// still to be finished on the checkout page.
bool gcashPaymentSent(ApplicationSummary app) {
  if (app.lifecycleStatus == 'Payment Submitted') return true;
  return app.orderOfPayment != null && app.paymentStatus != 'Not Yet Available' && app.paymentStatus != 'Overdue';
}
