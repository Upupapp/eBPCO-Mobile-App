import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/assessment_view.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/permit_fields.dart';
import '../../domain/property_address.dart';
import '../../domain/reviewing_office.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../widgets/paper_document.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// The citizen portal's `order-of-payment.page.ts`, ported (QA finding TC-26,
/// 2026-10-03): Onsite Payment says "bring a copy of your Order of Payment",
/// and nothing offered one. Built from the Order the office issued — its
/// number, issue and due dates, and only the fees that apply — to show at
/// the Municipal Treasurer's Office.
class OrderOfPaymentScreen extends StatefulWidget {
  final String applicationId;
  const OrderOfPaymentScreen({super.key, required this.applicationId});

  @override
  State<OrderOfPaymentScreen> createState() => _OrderOfPaymentScreenState();
}

class _OrderOfPaymentScreenState extends State<OrderOfPaymentScreen> {
  final _api = CitizenApi.instance;
  ApplicationSummary? _app;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // The Property line falls back to the business list, loaded only once My Businesses has been opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businesses = context.read<BusinessesService>();
      if (businesses.businesses.isEmpty && !businesses.loading) businesses.refresh();
    });
  }

  Future<void> _load() async {
    try {
      final app = await _api.getApplication(widget.applicationId);
      if (!mounted) return;
      setState(() => _app = app);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    final order = app?.orderOfPayment;
    return SoftPageScaffold(
      title: 'Order of Payment',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : app == null || order == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? 'No Order of Payment has been issued for this application yet.')],
                )
              : _order(app, order),
    );
  }

  Widget _order(ApplicationSummary app, OrderOfPayment order) {
    final profile = context.watch<SessionService>().profile;
    final businesses = context.watch<BusinessesService>().businesses.where((b) => b.id == app.businessId);
    final business = businesses.isEmpty ? null : businesses.first;
    final generatedOn = formatMoment(DateTime.now());
    final lines = [for (final line in feeLinesOf(order)) ([line.name, pesos(line.amountCentavos)], false)];

    return PaperDocumentViewer(
      page: PaperPage(
        children: [
          // The office that assessed the fees (the permit type's issuer); the Treasurer collects them.
          PaperHeader(office: reviewingOfficeFor(app.permitType)),
          PaperTitle(title: 'Order of Payment', subtitle: app.permitType),
          PaperNumberBlock(
            label: 'Order No.',
            value: order.number,
            facts: [
              ('Application No.', app.displayReference),
              ('Date issued', formatDate(order.assessedAt)),
              ('Pay on or before', order.dueDate != null ? formatDate(order.dueDate!) : 'Not set by the office'),
            ],
          ),
          PaperSection(
            title: 'Payor',
            child: PaperFields(
              rows: [
                ('Name', (profile?.fullName ?? '').isEmpty ? 'Not on file' : profile!.fullName),
                // A business's name only on a business application: the occupancy is the one statement of use (design review I6).
                if (app.businessNameOnDocument case final name?) (PermitLabels.businessName, name),
                (PermitLabels.applicationType, app.applicationAction),
                // The application's own property address; the business's only when it gave none.
                ('Property', propertyLine(location: app.location, business: business)),
              ],
              wide: const {'Property'},
            ),
          ),
          PaperSection(
            title: 'Fees',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaperTable(
                  header: const [PermitLabels.fee, PermitLabels.amount],
                  rows: [
                    ...lines,
                    ([totalAmountDueLabel, pesos(order.totalCentavos)], true),
                  ],
                ),
                // Where to pay, word for word as the pay screen says it (design review I2).
                PaperNote(PaymentDocumentText.orderPayNote(order.feeScheduleVersion)),
              ],
            ),
          ),
          PaperFooter(lines: [
            PaymentDocumentText.orderFooter,
            'Document Ref. ${order.number} · Generated $generatedOn · Page 1 of 1',
          ]),
        ],
      ),
    );
  }
}
