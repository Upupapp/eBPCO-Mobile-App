import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/receipt.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import 'receipt_screen.dart';

/// Read-only history of every paid Dokyu/Tulong request — derived straight
/// from each [ServiceRequest]'s own [ServiceRequest.receipt] (see
/// RequestsService._generateReceipt), never a separate hardcoded list, so a
/// transaction here is always backed by a real request/receipt pair. Users
/// may view a transaction and re-open/re-download its receipt; they can
/// never edit the amount, payment method, or status from this screen.
///
/// Scoped to the currently signed-in account's own `applicantId` — this
/// app's request "database" is a single shared local store (see
/// RequestsService's own doc comment), so without this filter a second
/// account (e.g. the duplicate Perlita registration, or any other signed-in
/// demo account) would see the verified Perlita account's paid transactions
/// too. Requires a signed-in account; the drawer already only offers this
/// screen once signed in.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestsService>();
    final account = context.watch<CitizenSessionService>().account;
    // Free-type receipts (a Free Dokyu service's own formality/claim-stub
    // receipt — see RequestsService.submit) are deliberately excluded here:
    // this screen is specifically "paid transactions," and a Free request
    // never had a real payment method to show. Its receipt is still fully
    // viewable via "View Receipt" on the request's own detail screen.
    final paid =
        requests.all
            .where((r) => r.receipt != null && r.receipt!.type != ReceiptType.free && r.applicantId == account?.id)
            .toList()
          ..sort((a, b) => b.receipt!.dateTime.compareTo(a.receipt!.dateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: paid.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              description: 'Your demo Dokyu or Tulong payments will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: paid.length,
              itemBuilder: (context, i) => _TransactionCard(request: paid[i]),
            ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ServiceRequest request;
  const _TransactionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final receipt = request.receipt!;
    final methodLabel = switch (receipt.type) {
      ReceiptType.gcash => 'GCash',
      ReceiptType.maya => 'Maya',
      ReceiptType.onsite => 'Onsite / Municipal Office',
      // Never actually reached — this screen's own list filters Free-type
      // receipts out (see build()) — kept only so this switch stays
      // exhaustive against ReceiptType.
      ReceiptType.free => 'Free',
      // See ReceiptType.unknown — never guess a method on a payment record.
      ReceiptType.unknown => '—',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          // TODO(PR-L): route to payment detail
          MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.typeName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                const _PaidBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              receipt.requestReferenceNumber,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${receipt.amount} • $methodLabel',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand600),
            ),
            const SizedBox(height: 2),
            Text(_fmt(receipt.dateTime), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View payment record',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.brand600),
                ),
                Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.brand600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${_month(d.month)} ${d.day}, ${d.year} • $hour12:$minute $ampm';
  }

  String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(999)),
      child: const Text(
        'Paid in demo',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald700),
      ),
    );
  }
}
