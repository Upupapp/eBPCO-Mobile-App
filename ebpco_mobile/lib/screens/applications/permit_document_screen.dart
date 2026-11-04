import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../core/config/app_config.dart';
import '../../domain/models.dart';
import '../../domain/occupancy.dart';
import '../../domain/property_address.dart';
import '../../domain/reviewing_office.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../widgets/paper_document.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../payments/payments_list_screen.dart';

/// The citizen portal's `permit-document.page.ts`, ported: the same printable
/// document, section for section, on the same paper layout — real values
/// only (`GET /applications/{id}` and `GET /applications/{id}/permit`), each
/// missing one labelled as missing rather than invented, and a permanent
/// "SAMPLE — NOT AN OFFICIAL PERMIT" watermark, as on the portal.
class PermitDocumentScreen extends StatefulWidget {
  final String applicationId;
  final String? applicationReference;
  const PermitDocumentScreen({super.key, required this.applicationId, this.applicationReference});

  @override
  State<PermitDocumentScreen> createState() => _PermitDocumentScreenState();
}

String _formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? iso : DateFormat('MMMM d, y').format(parsed.toLocal());
}

/// What a Certificate of Occupancy says under "Valid Until": it has no fixed
/// term (the backend fills an expiry for every other type, 12 or 6 months).
const String occupancyNoExpiry = "No fixed expiry (valid while the building's use and occupancy stay the same)";

/// "Valid Until" on the printed permit: the date the office recorded at issue;
/// for a Certificate of Occupancy with none, that it does not expire; for any
/// other type with none (an old permit), a neutral "Not recorded".
String permitValidUntil({required bool issued, required String permitType, String? expiresOn}) {
  if (!issued) return 'Not yet assigned';
  final date = expiresOn?.trim() ?? '';
  if (date.isNotEmpty) return _formatDate(date);
  return permitType == 'Certificate of Occupancy' ? occupancyNoExpiry : 'Not recorded';
}

/// The Approval block's name and position: who approved it and for which
/// office, as recorded at issue (QA TC-04, TC-18); "Not recorded" for either
/// on an old permit that has none. Before issue: not assigned yet, under the
/// reviewing [office].
({String name, String position}) permitApproval({
  required bool issued,
  String? approvingOfficial,
  String? approvingOffice,
  required String office,
}) {
  if (!issued) return (name: 'Not yet assigned', position: office);
  String recorded(String? value) => (value?.trim().isEmpty ?? true) ? 'Not recorded' : value!.trim();
  return (name: recorded(approvingOfficial), position: recorded(approvingOffice));
}

class _PermitDocumentScreenState extends State<PermitDocumentScreen> {
  final _api = CitizenApi.instance;
  ApplicationSummary? _app;
  PermitInfo? _permit;
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
    try {
      final app = await _api.getApplication(widget.applicationId);
      PermitInfo? permit;
      try {
        permit = await _api.getPermit(widget.applicationId);
      } on ApiError catch (e) {
        // Not issued yet answers 404; the document then shows its placeholders.
        if (e.status != 404) rethrow;
      }
      if (!mounted) return;
      setState(() {
        _app = app;
        _permit = permit;
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
      title: 'Your Permit',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _app == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? "We couldn't find that application.")],
                )
              : _document(_app!, _permit),
    );
  }

  Widget _document(ApplicationSummary app, PermitInfo? permit) {
    final profile = context.watch<SessionService>().profile;
    final businesses = context.watch<BusinessesService>().businesses.where((b) => b.id == app.businessId);
    final business = businesses.isEmpty ? null : businesses.first;
    final office = reviewingOfficeFor(app.permitType);
    final order = app.orderOfPayment;
    final issued = permit != null;
    final verificationUrl =
        issued ? '${AppConfig.userPortalBaseUrl}/verify/${Uri.encodeComponent(permit.permitNumber)}' : null;
    final generatedOn = DateFormat('MMMM d, y h:mm a').format(DateTime.now());
    final approval = permitApproval(
      issued: issued,
      approvingOfficial: permit?.approvingOfficial,
      approvingOffice: permit?.approvingOffice,
      office: office,
    );

    return PaperDocumentViewer(
      page: PaperPage(
        watermark: 'Sample — not an official permit',
        children: [
          PaperHeader(office: office),
          PaperTitle(title: app.permitType),
          PaperNumberBlock(
            label: 'Permit No.',
            value: permit?.permitNumber ?? 'Not yet assigned',
            pending: !issued,
            facts: [
              ('Application No.', app.displayReference),
              ('Date Issued', issued ? _formatDate(permit.issuedDate) : 'Not yet assigned'),
              // As the office recorded it when issuing (QA TC-04); a Certificate
              // of Occupancy has no fixed term.
              (
                'Valid Until',
                permitValidUntil(issued: issued, permitType: app.permitType, expiresOn: permit?.expiresOn),
              ),
            ],
          ),
          // "Owner / Applicant", as box 1 of the LGU's Unified Application Form
          // reads — see the portal page's own note on why it is not "Citizen".
          PaperSection(
            title: 'Owner / Applicant',
            child: PaperFields(rows: [
              ('Owner / Permittee Name', profile?.fullName ?? 'Not on file'),
              ('Business / Project', (app.businessName ?? '').isEmpty ? 'Not provided' : app.businessName!),
              ('Contact Number', profile?.mobileNumber ?? 'Not on file'),
              ('Address', profile?.street ?? 'Not on file'),
            ]),
          ),
          PaperSection(
            title: 'Property',
            // The application's own property address; the business's only
            // when it gave none (a Residential one names no business).
            child: PaperFields(rows: propertyRows(location: app.location, business: business)),
          ),
          PaperSection(
            title: 'Project',
            child: PaperFields(rows: [
              ('Transaction', app.applicationAction),
              // As filed (ebpco-api 071), the portal's printed line; left out when absent.
              if (occupancyLabelOf(app.form) case final use?) (occupancyFieldLabel, use),
              ('Date Applied', app.dateSubmitted != null ? _formatDate(app.dateSubmitted!) : 'Pending'),
              if (permit?.scope != null) ('Scope', permit!.scope!),
            ]),
          ),
          PaperSection(
            title: 'Assessment / Payment',
            child: order == null
                ? const PaperNote('No assessment has been issued yet for this application.', placeholder: true)
                : PaperTable(rows: [
                    (['Total Amount Due', pesos(order.totalCentavos)], true),
                    (['Payment Status', app.paymentStatus], false),
                  ]),
          ),
          // The office's conditions, every one, verbatim — never summarised.
          PaperSection(
            title: 'Conditions',
            child: issued && permit.conditions.isNotEmpty
                ? PaperNumberedList(items: permit.conditions)
                : const PaperNote(
                    'The Municipality has not supplied the conditions for this permit. This does not mean there are '
                    'none — ask the Office of the Municipal Engineer before relying on this document.',
                    placeholder: true,
                  ),
          ),
          PaperSignature(
            heading: 'Approval',
            pendingLabel: 'Pending Authorized Signature',
            // Who approved it, as recorded at issue (QA TC-04, TC-18).
            name: approval.name,
            position: approval.position,
          ),
          PaperQr(
            url: verificationUrl,
            unavailable: 'QR verification not yet available — this permit has not been issued.',
          ),
          PaperFooter(lines: [
            issued
                ? 'This is a system-generated document issued by the Municipality of Castilla, Sorsogon.'
                : 'This is a system-generated preview produced by the eBPCO portal. It is not an issued permit and has '
                    'no legal effect. Only the Municipality of Castilla, Sorsogon issues permits.',
            'Document Ref. ${app.id} · Generated $generatedOn · Page 1 of 1',
          ]),
        ],
      ),
    );
  }
}
