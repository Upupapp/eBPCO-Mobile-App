import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'payment_flow_screen.dart';
import 'payment_receipt_screen.dart';

final _pesos = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
String pesos(int centavos) => _pesos.format(centavos / 100);

/// Applications with an issued assessment or payment history — real data
/// already held by [ApplicationsService], no separate fetch needed, same
/// as the web portal's own `payments-list.page.ts`.
class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final apps = context.watch<ApplicationsService>();
    final rows = apps.applications.where((a) => a.orderOfPayment != null).toList();

    return SoftPageScaffold(
      title: 'Payments',
      body: RefreshIndicator(
        onRefresh: () => context.read<ApplicationsService>().refresh(),
        child: apps.loading && apps.applications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : rows.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      SoftEmptyCard(
                        apps.error != null && apps.applications.isEmpty
                            ? apps.error!
                            : 'No assessments issued yet. Once your application is evaluated, its Order of Payment will appear here.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: rows.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PaymentRow(application: rows[i]),
                    ),
                  ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final ApplicationSummary application;
  const _PaymentRow({required this.application});

  // Only a status the Municipality is still owed for offers to take a
  // payment. 'Pending Verification' does not offer it again — a citizen who
  // already sent proof must not be invited to send it twice.
  bool get _canPay => application.paymentStatus == 'Not Yet Available' || application.paymentStatus == 'Overdue';

  SoftStatusTone get _tone => switch (application.paymentStatus) {
        'Paid' => SoftStatusTone.verified,
        'Overdue' => SoftStatusTone.danger,
        _ => SoftStatusTone.pending,
      };

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftIconTile(icon: Icons.receipt_long_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.permitType, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(application.referenceNumber, style: SoftType.tileSub),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  pesos(application.orderOfPayment!.totalCentavos),
                  style: SoftType.h1.copyWith(fontSize: 24),
                ),
              ),
              SoftStatusPill(label: application.paymentStatus, tone: _tone),
            ],
          ),
          const SizedBox(height: 14),
          _canPay
              ? SoftPillButton(
                  label: 'Pay Now',
                  icon: Icons.payments_outlined,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentFlowScreen(applicationId: application.id))),
                )
              : SoftPillButton(
                  label: 'View Receipt',
                  kind: SoftPillKind.outline,
                  icon: Icons.receipt_long_outlined,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentReceiptScreen(applicationId: application.id))),
                ),
        ],
      ),
    );
  }
}
