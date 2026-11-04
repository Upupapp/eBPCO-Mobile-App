import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../core/config/app_config.dart';
import '../../domain/models.dart';
import '../../domain/permit_fields.dart';
import '../../services/businesses_service.dart';
import '../../services/session_service.dart';
import '../../widgets/paper_document.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// The citizen portal's `permit-document.page.ts`, ported: the same printable
/// document, section for section and label for label (the one field map,
/// `domain/permit_fields.dart`), on the same paper layout — real values only
/// (`GET /applications/{id}` and `GET /applications/{id}/permit`), each
/// missing one labelled as missing rather than invented, and a permanent
/// "SAMPLE — NOT AN OFFICIAL PERMIT" watermark, as on the portal. On a phone
/// the page reflows and scrolls ([PaperDocumentViewer]).
class PermitDocumentScreen extends StatefulWidget {
  final String applicationId;
  final String? applicationReference;
  const PermitDocumentScreen({super.key, required this.applicationId, this.applicationReference});

  @override
  State<PermitDocumentScreen> createState() => _PermitDocumentScreenState();
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
    final app = _app;
    return SoftPageScaffold(
      title: 'Your Permit',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : app == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [SoftEmptyCard(_error ?? "We couldn't find that application.")],
                )
              : PermitDocumentView(content: _content(app)),
    );
  }

  PermitDocumentContent _content(ApplicationSummary app) {
    final businesses = context.watch<BusinessesService>().businesses.where((b) => b.id == app.businessId);
    return permitDocumentContent(
      app: app,
      permit: _permit,
      // The citizen's account, as both portals read it (the record carries no owner).
      owner: context.watch<SessionService>().profile,
      business: businesses.isEmpty ? null : businesses.first,
      verifyBaseUrl: AppConfig.userPortalBaseUrl,
    );
  }
}

/// The printed permit, laid out from [content]: the sections in the field
/// map's order, then the approval, the QR code and the footer.
class PermitDocumentView extends StatelessWidget {
  const PermitDocumentView({super.key, required this.content});

  final PermitDocumentContent content;

  @override
  Widget build(BuildContext context) {
    final c = content;
    final assessment = c.assessment;
    return PaperDocumentViewer(
      page: PaperPage(
        watermark: 'Sample — not an official permit',
        children: [
          PaperHeader(office: c.office),
          PaperTitle(title: c.title),
          PaperNumberBlock(label: PermitLabels.permitNo, value: c.number, pending: c.numberPending, facts: c.facts),
          // "Owner / Applicant", as box 1 of the LGU's Unified Application Form
          // reads — see the portal page's own note on why it is not "Citizen".
          PaperSection(title: permitSections[0], child: PaperFields(rows: c.owner, wide: permitWideLabels)),
          // Where the project is, printed once.
          PaperSection(title: permitSections[1], child: PaperFields(rows: c.property, wide: permitWideLabels)),
          PaperSection(title: permitSections[2], child: PaperFields(rows: c.project, wide: permitWideLabels)),
          PaperSection(
            title: permitSections[3],
            child: assessment == null
                ? const PaperNote('No assessment has been issued yet for this application.', placeholder: true)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PaperTable(
                        header: const [PermitLabels.fee, PermitLabels.amount],
                        rows: [
                          for (final (name, amount) in assessment.fees) ([name, amount], false),
                          ([PermitLabels.totalAmountDue, assessment.total], true),
                          ([PermitLabels.balance, assessment.balance], false),
                        ],
                      ),
                      PaperNote('${PermitLabels.orderOfPaymentNo}: ${assessment.orderNumber}'),
                    ],
                  ),
          ),
          // The office's conditions, every one, verbatim — never summarised;
          // none recorded is stated as a fact, in normal ink.
          PaperSection(
            title: permitSections[4],
            child: c.conditions.isNotEmpty
                ? PaperNumberedList(items: c.conditions)
                : const PaperNote(noConditionsNote, fact: true),
          ),
          PaperSignature(
            heading: permitSections[5],
            pendingLabel: c.approvalNote,
            name: c.approvalName,
            position: c.approvalPosition,
          ),
          PaperQr(
            url: c.verificationUrl,
            number: c.permitNumber,
            unavailable: 'QR verification not yet available — this permit has not been issued.',
          ),
          PaperFooter(lines: c.footer),
        ],
      ),
    );
  }
}
