/// The assessment as both portals show it (design review I15, 4 Nov 2026):
/// the Order of Payment's own fees, then "Total amount due" and "Balance" —
/// on the application, the pay screen, the Order of Payment, the receipt and
/// the permit alike. The portal's `assessment-view.ts`.
library;

import 'package:intl/intl.dart';

import 'models.dart';

final _pesos = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

/// An amount in centavos as pesos: "₱6,820.50".
String pesos(int centavos) => _pesos.format(centavos / 100);

/// The labels the assessment's totals carry, on screen and on paper.
const totalAmountDueLabel = 'Total amount due';
const balanceLabel = 'Balance';

const _feeNames = [
  ('filing', 'Filing Fee'),
  ('processing', 'Processing Fee'),
  ('architectural', 'Architectural Fee'),
  ('structural', 'Structural Fee'),
  ('electrical', 'Electrical Fee'),
  ('others', 'Other Fees'),
];

/// The Order of Payment's own fees, only those that apply: ₱0.00 lines beside
/// the real ones read as charges (QA TC-05).
List<({String code, String name, int amountCentavos})> feeLinesOf(OrderOfPayment order) => [
      for (final (code, name) in _feeNames)
        if ((order.fees[code] ?? 0) > 0) (code: code, name: name, amountCentavos: order.fees[code]!),
    ];

/// What is still owed: nothing once paid, the whole total until then (a
/// payment waiting for the Cashier settles nothing yet).
int balanceOf(OrderOfPayment order, {required String paymentStatus}) => paymentStatus == 'Paid' ? 0 : order.totalCentavos;
