/// The Payments screen's history (2026-10-01): every payment the citizen
/// sent, in their words. The portal's `payments-list.page.ts` decides the
/// same way, so the two read alike.
library;

import 'package:intl/intl.dart';

import 'models.dart';

enum PaymentTone { verified, pending, danger, neutral }

/// One payment sent, as the history shows it: a label, its colour, and the
/// line under it (the receipt, or why it did not count).
class PaymentAttemptView {
  /// 'Paid', 'Pending Verification', 'Rejected', 'Voided', 'Reversed',
  /// 'Refunded' or 'Overdue'.
  final String label;
  final PaymentTone tone;
  final String detail;
  const PaymentAttemptView(this.label, this.tone, this.detail);
}

String _day(String iso) {
  final when = DateTime.tryParse(iso)?.toLocal();
  return when == null ? iso : DateFormat('MMM d, yyyy').format(when);
}

/// The server keeps no "Rejected" status: a rejection resets the row to
/// 'Not Yet Available' and sets `rejectionReason`, so that is what marks one.
PaymentAttemptView paymentAttemptView(PaymentEntry p) {
  final rejection = p.rejectionReason;
  if (rejection != null) return PaymentAttemptView('Rejected', PaymentTone.danger, rejection);
  switch (p.status) {
    case 'Paid':
      final parts = [
        if (p.officialReceiptNumber != null) 'Official Receipt No. ${p.officialReceiptNumber}',
        if (p.verifiedAt != null) 'confirmed ${_day(p.verifiedAt!)}',
      ];
      return PaymentAttemptView(
        'Paid',
        PaymentTone.verified,
        parts.isEmpty ? 'Confirmed by the Treasurer’s Office.' : parts.join(' · '),
      );
    case 'Voided' || 'Reversed' || 'Refunded':
      return PaymentAttemptView(p.status, PaymentTone.neutral, p.exceptionReason ?? '');
    case 'Overdue':
      return const PaymentAttemptView('Overdue', PaymentTone.danger, 'The Order of Payment is past its due date.');
    default:
      return const PaymentAttemptView(
        'Pending Verification',
        PaymentTone.pending,
        'The Municipal Treasurer’s Office is checking this payment. Nothing more is needed from you.',
      );
  }
}

/// Where an Order of Payment stands. Each order is in exactly one, so the
/// filter counts add up to All.
enum OrderState { awaiting, rejected, verifying, paid }

/// [paymentStatus] is the application's own; [last] its most recent payment.
OrderState orderStateOf(String paymentStatus, PaymentAttemptView? last) {
  final canPay = paymentStatus == 'Not Yet Available' || paymentStatus == 'Overdue';
  if (canPay) return last?.label == 'Rejected' ? OrderState.rejected : OrderState.awaiting;
  return paymentStatus == 'Paid' ? OrderState.paid : OrderState.verifying;
}
