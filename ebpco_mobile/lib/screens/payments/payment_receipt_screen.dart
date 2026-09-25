import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
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

/// The portal's `requirements-catalog.ts` reviewing offices, which pick the
/// document header (`agencyHeaderFor`).
String _reviewingOfficeFor(String permitType) {
  switch (permitType) {
    case 'Zoning / Locational Clearance':
      return 'Municipal Planning and Development Office (MPDO / Zoning)';
    case 'FSEC for Building Permit (BFP)':
    case 'FSIC for Occupancy Permit (BFP)':
      return 'Bureau of Fire Protection — Castilla Fire Station';
    case 'Certificate of Occupancy':
      return 'Office of the Building Official (OBO) / BFP';
    default:
      return 'Office of the Building Official (OBO)';
  }
}

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
    final office = _reviewingOfficeFor(app.permitType);
    final isBfp = RegExp('fire protection|bfp', caseSensitive: false).hasMatch(office);
    final isOfficial = tx.officialReceiptNumber != null;
    final gateCleared = tx.status == 'Paid' && tx.officialReceiptNumber != null && tx.rejectionReason == null;
    final order = app.orderOfPayment;
    final generatedOn = DateFormat('MMMM d, y h:mm a').format(DateTime.now());

    Widget section(String title, List<(String, String)> rows) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title.toUpperCase(), style: SoftType.eyebrow.copyWith(letterSpacing: 0.8, fontSize: 12)),
              const SizedBox(height: 6),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 130, child: Text(r.$1, style: SoftType.cellLabel.copyWith(fontSize: 13))),
                      Expanded(child: Text(r.$2, style: SoftType.cellValue.copyWith(fontSize: 14))),
                    ],
                  ),
                ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        'SAMPLE — NOT AN OFFICIAL RECEIPT',
                        textAlign: TextAlign.center,
                        style: SoftType.h1.copyWith(fontSize: 22, color: const Color(0x1AC81E2C)),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/ebpco_seal.png', width: 44, height: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Republic of the Philippines', style: SoftType.cellLabel),
                            Text(isBfp ? 'Department of the Interior and Local Government' : 'Province of Sorsogon', style: SoftType.cellLabel),
                            Text(isBfp ? 'Bureau of Fire Protection' : 'Municipality of Castilla', style: SoftType.cellValue.copyWith(fontWeight: FontWeight.w600)),
                            Text(office, style: SoftType.cellLabel),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: SoftColors.line),
                  Text(isOfficial ? 'Official Receipt' : 'Payment Acknowledgment', textAlign: TextAlign.center, style: SoftType.h1.copyWith(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(app.permitType, textAlign: TextAlign.center, style: SoftType.body),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: SoftColors.primaryWash, borderRadius: BorderRadius.circular(SoftRadius.sm)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOfficial ? 'OR No.' : 'Reference No.', style: SoftType.cellLabel),
                        Text(
                          tx.officialReceiptNumber ?? 'Not yet assigned',
                          style: SoftType.cellValue.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: isOfficial ? SoftColors.ink : SoftColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text('Application No.: ${app.referenceNumber}', style: SoftType.cellLabel.copyWith(fontSize: 13)),
                        Text('Date Submitted: ${_formatDate(tx.submittedAt)}', style: SoftType.cellLabel.copyWith(fontSize: 13)),
                        Text('Date Verified: ${tx.verifiedAt != null ? _formatDate(tx.verifiedAt!) : 'Pending'}', style: SoftType.cellLabel.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  section('Payor', [
                    ('Name', profile?.fullName ?? 'Not on file'),
                    ('Business / Project', (app.businessName ?? '').isEmpty ? 'Not provided' : app.businessName!),
                  ]),
                  section('Property', [
                    ('Barangay', business?.barangay ?? 'Not on file'),
                    ('City / Municipality', business?.city ?? 'Not on file'),
                    ('Street / Location', business?.street ?? 'Not on file'),
                    ('Province', business?.province ?? 'Not on file'),
                  ]),
                  section('Project', [
                    ('Transaction', app.applicationAction),
                    ('Date Applied', app.dateSubmitted != null ? _formatDate(app.dateSubmitted!) : 'Pending'),
                  ]),
                  section('Payment Details', [
                    ('Collecting Agency', 'OBO/LGU'),
                    ('Payment Method', tx.method),
                    ('Reference / Proof', tx.referenceNumber),
                    ('Status', tx.status),
                    if (tx.rejectionReason != null) ('Reason', tx.rejectionReason!),
                  ]),
                  section('Amount', [
                    if (order != null)
                      for (final line in _feeLines) (line.$2, order.fees.containsKey(line.$1) ? pesos(order.fees[line.$1]!) : 'Pending'),
                    ('Amount Paid (this transaction)', pesos(tx.amountCentavos)),
                    if (order != null) ('Remaining Balance', pesos(tx.status == 'Paid' ? 0 : order.totalCentavos)),
                  ]),
                  const SizedBox(height: 22),
                  Text('RECEIVED BY', style: SoftType.eyebrow.copyWith(letterSpacing: 0.8, fontSize: 12)),
                  if (!gateCleared) ...[
                    const SizedBox(height: 6),
                    Text('Pending Cashier Verification', style: SoftType.cellValue.copyWith(color: SoftColors.pendingInk)),
                  ],
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: SoftColors.ink),
                  const SizedBox(height: 4),
                  Text('Municipal Treasurer\'s Office Cashier', style: SoftType.cellValue),
                  if (gateCleared) Text(office, style: SoftType.cellLabel),
                  const SizedBox(height: 20),
                  Text(
                    gateCleared
                        ? 'This is a system-generated Official Receipt issued by the Municipality of Castilla, Sorsogon.'
                        : 'This is a system-generated preview produced by the eBPCO portal. It is not an issued Official Receipt '
                            'and has no legal effect. Only the Municipality of Castilla\'s Treasurer\'s Office issues an Official '
                            'Receipt, upon verifying a payment it actually received.',
                    style: SoftType.cellLabel.copyWith(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text('Document Ref. ${tx.id} · Generated $generatedOn · Page 1 of 1', style: SoftType.cellLabel.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
