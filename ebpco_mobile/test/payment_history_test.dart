import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/payment_history.dart';

PaymentEntry _entry({String status = 'Pending Verification', String? receipt, String? verifiedAt, String? rejection, String? exception}) =>
    PaymentEntry(
      id: 'p1',
      referenceNumber: 'ONSITE-1',
      method: 'Onsite',
      amountCentavos: 170000,
      status: status,
      submittedAt: '2026-10-01T02:00:00.000Z',
      verifiedAt: verifiedAt,
      officialReceiptNumber: receipt,
      rejectionReason: rejection,
      exceptionReason: exception,
    );

/// The Payments screen's history and filters (2026-10-01), the same words
/// as the portal's.
void main() {
  test('a payment still being checked says so', () {
    final view = paymentAttemptView(_entry());
    expect(view.label, 'Pending Verification');
    expect(view.tone, PaymentTone.pending);
  });

  test('a confirmed payment shows its Official Receipt number', () {
    final view = paymentAttemptView(_entry(status: 'Paid', receipt: 'OR-2026-1', verifiedAt: '2026-10-01T05:00:00.000Z'));
    expect(view.label, 'Paid');
    expect(view.detail, contains('OR-2026-1'));
  });

  test('a rejected payment is told by its reason, since the server keeps no Rejected status', () {
    final view = paymentAttemptView(_entry(status: 'Not Yet Available', rejection: 'The reference does not match.'));
    expect(view.label, 'Rejected');
    expect(view.detail, 'The reference does not match.');
  });

  test('a refunded payment says so, with the reason', () {
    final view = paymentAttemptView(_entry(status: 'Refunded', exception: 'Paid twice.'));
    expect(view.label, 'Refunded');
    expect(view.detail, 'Paid twice.');
  });

  test('an unpaid order whose last payment was rejected is Rejected, not merely awaiting', () {
    final rejected = paymentAttemptView(_entry(status: 'Not Yet Available', rejection: 'Short.'));
    expect(orderStateOf('Not Yet Available', rejected), OrderState.rejected);
    expect(orderStateOf('Not Yet Available', null), OrderState.awaiting);
    expect(orderStateOf('Overdue', null), OrderState.awaiting);
    expect(orderStateOf('Pending Verification', paymentAttemptView(_entry())), OrderState.verifying);
    expect(orderStateOf('Paid', null), OrderState.paid);
  });
}
