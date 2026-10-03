import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../domain/reviewing_office.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../widgets/paper_document.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import 'payments_list_screen.dart';

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

const _feeLines = [
  ('filing', 'Filing Fee'),
  ('processing', 'Processing Fee'),
  ('architectural', 'Architectural Fee'),
  ('structural', 'Structural Fee'),
  ('electrical', 'Electrical Fee'),
  ('others', 'Other Fees'),
];

String _formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? iso : DateFormat('MMMM d, y').format(parsed.toLocal());
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
    // The Property line reads the business list, loaded only once My Businesses has been opened.
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
    final generatedOn = DateFormat('MMMM d, y h:mm a').format(DateTime.now());
    final lines = [
      for (final line in _feeLines)
        if ((order.fees[line.$1] ?? 0) > 0) ([line.$2, pesos(order.fees[line.$1]!)], false),
    ];

    return PaperDocumentViewer(
      page: PaperPage(
        children: [
          PaperHeader(office: reviewingOfficeFor(app.permitType)),
          PaperTitle(title: 'Order of Payment', subtitle: app.permitType),
          PaperNumberBlock(
            label: 'Order No.',
            value: order.number,
            facts: [
              ('Application No.', app.displayReference),
              ('Date Issued', _formatDate(order.assessedAt)),
              ('Pay On or Before', order.dueDate != null ? _formatDate(order.dueDate!) : 'Not set by the office'),
            ],
          ),
          PaperSection(
            title: 'Payor',
            child: PaperFields(rows: [
              ('Name', profile?.fullName ?? 'Not on file'),
              ('Business / Project', (app.businessName ?? '').isEmpty ? 'Not provided' : app.businessName!),
              ('Transaction', app.applicationAction),
              (
                'Property',
                business == null ? 'Not on file' : '${business.street}, ${business.barangay}, ${business.city}',
              ),
            ]),
          ),
          PaperSection(
            title: 'Fees',
            child: PaperTable(
              header: const ['Fee', 'Amount'],
              rows: [
                ...lines,
                (['Total Amount Due', pesos(order.totalCentavos)], true),
              ],
            ),
          ),
          const PaperNote(
            "Pay the full amount at the Municipal Treasurer's Office and keep the Official Receipt it gives you.",
          ),
          PaperFooter(lines: [
            'A copy of the Order of Payment issued through eBPCO by the Municipality of Castilla, Sorsogon. '
                "Show it at the Municipal Treasurer's Office when you pay.",
            'Generated $generatedOn · Page 1 of 1',
          ]),
        ],
      ),
    );
  }
}
