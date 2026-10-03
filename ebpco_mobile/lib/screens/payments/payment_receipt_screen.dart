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

/// The citizen portal's `payment-receipt.page.ts`, ported: the latest real
/// payment on the application, the Order of Payment's fee lines, and the
/// same honesty rules — a permanent "SAMPLE — NOT AN OFFICIAL RECEIPT"
/// watermark (a reprint is never the stamped original), and the
/// "system-generated Official Receipt" wording only once a cashier has
/// verified the payment with a real OR number.
class PaymentReceiptScreen extends StatefulWidget {
  final String applicationId;
  const PaymentReceiptScreen({super.key, required this.applicationId});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
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

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  final _api = CitizenApi.instance;
  ApplicationSummary? _app;
  PaymentEntry? _payment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // The Property section reads the business list, which is only loaded
    // once My Businesses has been opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businesses = context.read<BusinessesService>();
      if (businesses.businesses.isEmpty && !businesses.loading) businesses.refresh();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = await _api.getApplication(widget.applicationId);
      List<PaymentEntry> payments = const [];
      try {
        payments = await _api.getPayments(widget.applicationId);
      } on ApiError {
        // None submitted yet answers like "no payment" — same as the portal.
      }
      if (!mounted) return;
      setState(() {
        _app = app;
        _payment = payments.isEmpty ? null : payments.last;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'Receipt',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _app == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? "We couldn't find that application.")],
                )
              : _payment == null
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: const [SoftEmptyCard('No payment has been submitted for this application yet.')],
                    )
                  : _receipt(_app!, _payment!),
    );
  }

  Widget _receipt(ApplicationSummary app, PaymentEntry tx) {
    final profile = context.watch<SessionService>().profile;
    final businesses = context.watch<BusinessesService>().businesses.where((b) => b.id == app.businessId);
    final business = businesses.isEmpty ? null : businesses.first;
    final office = reviewingOfficeFor(app.permitType);
    final isOfficial = tx.officialReceiptNumber != null;
    final gateCleared = tx.status == 'Paid' && tx.officialReceiptNumber != null && tx.rejectionReason == null;
    final order = app.orderOfPayment;
    final generatedOn = DateFormat('MMMM d, y h:mm a').format(DateTime.now());

    // The portal's payment-receipt.page.ts, section for section and word for
    // word, on the same paper layout.
    return PaperDocumentViewer(
      page: PaperPage(
        watermark: 'Sample — not an official receipt',
        children: [
          PaperHeader(office: office),
          PaperTitle(title: isOfficial ? 'Official Receipt' : 'Payment Acknowledgment', subtitle: app.permitType),
          PaperNumberBlock(
            label: isOfficial ? 'OR No.' : 'Reference No.',
            value: tx.officialReceiptNumber ?? 'Not yet assigned',
            pending: tx.officialReceiptNumber == null,
            facts: [
              ('Application No.', app.displayReference),
              ('Date Submitted', _formatDate(tx.submittedAt)),
              ('Date Verified', tx.verifiedAt != null ? _formatDate(tx.verifiedAt!) : 'Pending'),
            ],
          ),
          PaperSection(
            title: 'Payor',
            child: PaperFields(rows: [
              ('Name', profile?.fullName ?? 'Not on file'),
              ('Business / Project', (app.businessName ?? '').isEmpty ? 'Not provided' : app.businessName!),
            ]),
          ),
          PaperSection(
            title: 'Property',
            child: PaperFields(rows: [
              ('Barangay', business?.barangay ?? 'Not on file'),
              ('City / Municipality', business?.city ?? 'Not on file'),
              ('Street / Location', business?.street ?? 'Not on file'),
              ('Province', business?.province ?? 'Not on file'),
            ]),
          ),
          PaperSection(
            title: 'Project',
            child: PaperFields(rows: [
              ('Transaction', app.applicationAction),
              ('Date Applied', app.dateSubmitted != null ? _formatDate(app.dateSubmitted!) : 'Pending'),
            ]),
          ),
          PaperSection(
            title: 'Payment Details',
            child: PaperFields(rows: [
              ('Collecting Agency', 'OBO/LGU'),
              ('Payment Method', tx.method),
              ('Reference / Proof', tx.referenceNumber),
              ('Status', tx.status),
              if (tx.rejectionReason != null) ('Reason', tx.rejectionReason!),
            ]),
          ),
          PaperSection(
            title: 'Amount',
            child: order == null
                ? PaperNote('Amount Paid: ${pesos(tx.amountCentavos)}')
                : PaperTable(
                    header: const ['Fee', 'Amount'],
                    rows: [
                      // Only the fees that apply: a ₱0.00 line read as a charge (QA TC-05).
                      for (final line in _feeLines)
                        if ((order.fees[line.$1] ?? 0) > 0) ([line.$2, pesos(order.fees[line.$1]!)], false),
                      (['Amount Paid (this transaction)', pesos(tx.amountCentavos)], true),
                      (['Remaining Balance', pesos(tx.status == 'Paid' ? 0 : order.totalCentavos)], false),
                    ],
                  ),
          ),
          PaperSignature(
            heading: 'Received By',
            pendingLabel: gateCleared ? null : 'Pending Cashier Verification',
            name: "Municipal Treasurer's Office Cashier",
            position: gateCleared ? office : null,
          ),
          PaperFooter(lines: [
            gateCleared
                ? 'This is a system-generated Official Receipt issued by the Municipality of Castilla, Sorsogon.'
                : 'This is a system-generated preview produced by the eBPCO portal. It is not an issued Official Receipt '
                    "and has no legal effect. Only the Municipality of Castilla's Treasurer's Office issues an Official "
                    'Receipt, upon verifying a payment it actually received.',
            'Document Ref. ${tx.id} · Generated $generatedOn · Page 1 of 1',
          ]),
        ],
      ),
    );
  }
}
