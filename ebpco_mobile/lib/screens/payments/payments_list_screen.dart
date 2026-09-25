import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../applications/application_detail_screen.dart';
import 'payment_flow_screen.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payments')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ApplicationsService>().refresh(),
          child: apps.loading && apps.applications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Text(
                            'No assessments issued yet. Once your application is evaluated, its Order of Payment will appear here.',
                            style: AppTypography.body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _PaymentRow(application: rows[i]),
                      ),
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

  Color get _tone => switch (application.paymentStatus) {
        'Paid' => AppColors.success,
        'Overdue' => AppColors.danger,
        _ => AppColors.warning,
      };

  Color get _toneBg => switch (application.paymentStatus) {
        'Paid' => AppColors.success100,
        'Overdue' => AppColors.danger100,
        _ => AppColors.warning100,
      };

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(application.referenceNumber, style: AppTypography.cardTitle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _toneBg, borderRadius: BorderRadius.circular(999)),
                child: Text(application.paymentStatus, style: AppTypography.caption.copyWith(color: _tone, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(pesos(application.orderOfPayment!.totalCentavos), style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _canPay
                ? ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentFlowScreen(applicationId: application.id))),
                    child: const Text('Pay Now'),
                  )
                : OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: application.id))),
                    child: const Text('View Details'),
                  ),
          ),
        ],
      ),
    );
  }
}
