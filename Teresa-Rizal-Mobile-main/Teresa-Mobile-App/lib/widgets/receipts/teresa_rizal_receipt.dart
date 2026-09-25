import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/receipt.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/teresa_rizal_seal.dart';

final _orNumber = RegExp(r'^OR[-\s]*([0-9].*)$', caseSensitive: false);

/// A stored official-receipt number is never shown. It renders as a local
/// DEMO-PAY reference using the last four digits. Values already stored as
/// DEMO-PAY- stay as they are.
String _paymentReferenceLabel(String raw) {
  final trimmed = raw.trim();
  if (_orNumber.hasMatch(trimmed) || trimmed.startsWith('DEMO-PAY-')) {
    return 'Local reference';
  }
  return 'Transaction Reference No.';
}

String _paymentReferenceValue(String raw) {
  final trimmed = raw.trim();
  final match = _orNumber.firstMatch(trimmed);
  if (match == null) return trimmed;
  final digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'DEMO-PAY-0000';
  final nnnn = digits.length <= 4 ? digits.padLeft(4, '0') : digits.substring(digits.length - 4);
  return 'DEMO-PAY-$nnnn';
}

/// The single Teresa, Rizal municipal payment receipt — used for every payment
/// method (Onsite, GCash, Maya). There is deliberately only one visual
/// design: a citizen who paid via GCash or Maya still receives an
/// Teresa, Rizal municipal receipt, not a wallet-app-styled one. The only
/// difference between payment methods is the "Mode of Payment" row's label
/// and small brand graphic (see [_paymentModeLabel]/[_PaymentModeBadge]) —
/// every other value comes from this request's own [Receipt].
/// FRONTEND SIMULATION ONLY — no real payment/print integration.
class TeresaRizalReceipt extends StatelessWidget {
  final Receipt receipt;
  const TeresaRizalReceipt({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.slate50,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                // Header — municipal identity.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy900, AppColors.brand700],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(teresaRizalSealAsset, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Municipality of Teresa, Rizal',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Payment record (demo)',
                        style: TextStyle(
                          color: AppColors.gold300,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _badgeColors.$1,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _badgeColors.$2.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _badgeLabel,
                          style: TextStyle(
                            color: _badgeColors.$2,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _row('Resident Name', receipt.residentName),
                      _row('Service', receipt.serviceName),
                      _row('Request Reference No.', receipt.requestReferenceNumber),
                      _row(_amountLabel, receipt.amount, emphasize: true),
                      _modeOfPaymentRow(),
                      _row('Date & Time', _fmt(receipt.dateTime)),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      _row(
                        _paymentReferenceLabel(receipt.referenceNumber),
                        _paymentReferenceValue(receipt.referenceNumber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'This is a frontend simulation. No real payment transaction was made.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 16 : 12.5,
                fontWeight: FontWeight.w700,
                color: emphasize ? AppColors.brand700 : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The one row that differs by payment method — a label plus a small,
  /// size-capped brand graphic (see [_PaymentModeBadge]), never a separate
  /// receipt theme. GCash/Maya branding stays confined to this single
  /// badge + label so the receipt still reads as an Teresa, Rizal municipal
  /// document first.
  Widget _modeOfPaymentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text('Mode of Payment', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Expanded + Flexible, matching every other row's label/value
          // split: a fixed-size trailing Row can't shrink, so the longer
          // "Onsite — Municipal Office" label overflowed at phone widths
          // until the value side could wrap like the rest of the receipt.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _PaymentModeBadge(type: receipt.type),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _paymentModeLabel(receipt.type),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _paymentModeLabel(ReceiptType type) => switch (type) {
    ReceiptType.gcash => 'GCash',
    ReceiptType.maya => 'Maya',
    ReceiptType.onsite => 'Onsite — Municipal Office',
    ReceiptType.free => 'No Payment Required',
    // Never name a method we cannot read. See ReceiptType.unknown.
    ReceiptType.unknown => '—',
  };

  /// GCash/Maya genuinely completed a (simulated) digital payment, so the
  /// badge/amount row can honestly say "Paid". Onsite hasn't paid anything
  /// yet — the fee is settled in person later — so it must never claim
  /// "Paid" or present the fee as already collected (that's the whole
  /// point of the Onsite receipt rule). Free has nothing to pay at all.
  String get _badgeLabel => switch (receipt.type) {
    ReceiptType.gcash || ReceiptType.maya => 'PAID IN DEMO',
    ReceiptType.onsite => 'DUE ONSITE',
    ReceiptType.free => 'RECEIVED',
    // The one that mattered: an unreadable type used to render as
    // "DUE ONSITE". It must claim neither payment nor debt.
    ReceiptType.unknown => '—',
  };

  (Color, Color) get _badgeColors => switch (receipt.type) {
    ReceiptType.gcash || ReceiptType.maya => (AppColors.emerald50, AppColors.emerald700),
    ReceiptType.onsite => (AppColors.amber50, AppColors.amber700),
    ReceiptType.free => (AppColors.emerald50, AppColors.emerald700),
    // Neutral, so the badge does not read as settled (green) or owing (amber).
    ReceiptType.unknown => (AppColors.slate100, AppColors.slate600),
  };

  String get _amountLabel => switch (receipt.type) {
    ReceiptType.gcash || ReceiptType.maya => 'Amount (sample)',
    ReceiptType.onsite => 'Amount Due',
    ReceiptType.free => 'Amount',
    // "Amount" is true regardless; "Paid"/"Due" would not be.
    ReceiptType.unknown => 'Amount',
  };

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// The small graphic identifying the payment method, next to its text
/// label. GCash/Maya render their real bundled brand logos
/// (assets/images/gcash_logo.svg, assets/images/Maya_logo.svg.webp) —
/// explicitly size-capped (fixed width/height + BoxFit.contain) so their
/// own large/wide source dimensions can never drive this row's layout,
/// overflow, stretch, or dominate the receipt, which stays an Teresa, Rizal
/// municipal document first. Onsite keeps its original Teresa-appropriate
/// storefront glyph, unchanged, rather than repeating the seal shown above.
class _PaymentModeBadge extends StatelessWidget {
  final ReceiptType type;
  const _PaymentModeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ReceiptType.gcash:
        // gcash_logo.svg's own viewBox is ~135x114 (roughly square) — a
        // small fixed box keeps it in scale with the text beside it.
        return SvgPicture.asset('assets/images/gcash_logo.svg', height: 18, width: 20, fit: BoxFit.contain);
      case ReceiptType.maya:
        // Maya_logo.svg.webp is a very wide wordmark raster (source is
        // 3840x1116) — capping both height and width to a small box, with
        // BoxFit.contain, is what actually keeps it from taking over the
        // row; height alone would let its width balloon.
        return Image.asset('assets/images/Maya_logo.svg.webp', height: 14, width: 34, fit: BoxFit.contain);
      case ReceiptType.onsite:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.brand700, shape: BoxShape.circle),
          child: const Icon(Icons.storefront_rounded, size: 11, color: Colors.white),
        );
      case ReceiptType.free:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.emerald500, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
        );
      case ReceiptType.unknown:
        // No brand mark and no storefront glyph — either would assert a
        // payment method. A neutral question mark says what is true.
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.slate400, shape: BoxShape.circle),
          child: const Icon(Icons.question_mark_rounded, size: 11, color: AppColors.surface),
        );
    }
  }
}
