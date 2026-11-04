import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/assessment_view.dart';
import '../../domain/dates.dart';
import '../../domain/lgu_contact.dart';
import '../../domain/models.dart';
import '../../domain/permit_fields.dart';
import '../../domain/property_address.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../widgets/paper_document.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

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
    // The Property section falls back to the business list (an application
    // with no address of its own), which is only loaded once My Businesses
    // has been opened.
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
    final isOfficial = tx.officialReceiptNumber != null;
    final gateCleared = tx.status == 'Paid' && tx.officialReceiptNumber != null && tx.rejectionReason == null;
    final order = app.orderOfPayment;
    final generatedOn = formatMoment(DateTime.now());
    final documentRef = PaymentDocumentText.receiptReference(
      orNumber: tx.officialReceiptNumber,
      orderNumber: order?.number,
      applicationNumber: app.displayReference,
    );

    // The portal's payment-receipt.page.ts, section for section and word for
    // word, on the same paper layout. The Municipal Treasurer's Office issues
    // an Official Receipt, so it heads the receipt (design review I2; it
    // named the Building Official).
    return PaperDocumentViewer(
      page: PaperPage(
        watermark: 'Sample — not an official receipt',
        children: [
          PaperHeader(office: municipalTreasurer.name),
          PaperTitle(title: isOfficial ? 'Official Receipt' : 'Payment Acknowledgment', subtitle: app.permitType),
          PaperNumberBlock(
            label: isOfficial ? 'OR No.' : 'Reference No.',
            value: tx.officialReceiptNumber ?? 'Not yet assigned',
            pending: tx.officialReceiptNumber == null,
            facts: [
              ('Application No.', app.displayReference),
              ('Date submitted', formatDate(tx.submittedAt)),
              ('Date verified', tx.verifiedAt != null ? formatDate(tx.verifiedAt!) : 'Pending'),
            ],
          ),
          PaperSection(
            title: 'Payor',
            child: PaperFields(rows: [
              ('Name', (profile?.fullName ?? '').isEmpty ? 'Not on file' : profile!.fullName),
              // A business's name only on a business application (design review I6).
              if (app.businessNameOnDocument case final name?) (PermitLabels.businessName, name),
            ]),
          ),
          PaperSection(
            title: 'Property',
            // The application's own property address, printed once; the
            // business's only when it gave none.
            child: PaperFields(rows: propertyRows(location: app.location, business: business), wide: permitWideLabels),
          ),
          PaperSection(
            title: 'Project',
            child: PaperFields(rows: [
              (PermitLabels.applicationType, app.applicationAction),
              (PermitLabels.dateApplied, app.dateSubmitted != null ? formatDate(app.dateSubmitted!) : 'Pending'),
            ]),
          ),
          PaperSection(
            title: 'Payment Details',
            child: PaperFields(rows: [
              // The Municipal Treasurer's Office collects every permit fee ('OBO/LGU' was a placeholder).
              ('Collecting agency', municipalTreasurer.name),
              ('Payment method', tx.method),
              ('Reference / proof', tx.referenceNumber),
              ('Status', tx.status),
              if (tx.rejectionReason != null) ('Reason', tx.rejectionReason!),
            ]),
          ),
          PaperSection(
            title: 'Amount',
            child: order == null
                ? PaperNote('Amount paid: ${pesos(tx.amountCentavos)}')
                : PaperTable(
                    header: const [PermitLabels.fee, PermitLabels.amount],
                    rows: [
                      // Only the fees that apply: a ₱0.00 line read as a charge (QA TC-05).
                      for (final line in feeLinesOf(order)) ([line.name, pesos(line.amountCentavos)], false),
                      (['Amount paid', pesos(tx.amountCentavos)], true),
                      (
                        [
                          gateCleared ? balanceLabel : '$balanceLabel (once verified)',
                          pesos(tx.status == 'Paid' ? 0 : order.totalCentavos),
                        ],
                        false,
                      ),
                    ],
                  ),
          ),
          // The Cashier, of the Municipal Treasurer's Office: the office that
          // issues an Official Receipt (design review I2).
          PaperSignature(
            heading: 'Received By',
            pendingLabel: gateCleared ? null : 'Pending Cashier verification',
            name: municipalTreasurer.cashierLabel,
            position: municipalTreasurer.name,
          ),
          PaperFooter(lines: [
            PaymentDocumentText.receiptFooter(
              verified: gateCleared,
              method: tx.method,
              reference: tx.referenceNumber,
              orNumber: tx.officialReceiptNumber,
            ),
            // Never the payment's internal id.
            'Document Ref. $documentRef · Generated $generatedOn · Page 1 of 1',
          ]),
        ],
      ),
    );
  }
}
