import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../domain/permit_forms.dart';
import '../../domain/upload_file.dart';
import '../../services/applications_service.dart';
import '../../services/upload_limits.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';
import '../documents/document_viewer_screen.dart';
import '../payments/order_of_payment_screen.dart';
import '../payments/payment_flow_screen.dart';
import '../payments/payments_list_screen.dart';
import '../permits/application_wizard_screen.dart';
import 'permit_document_screen.dart';
import '../../widgets/blank_form_link.dart';
import '../../widgets/message_bar.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _api = CitizenApi.instance;
  ApplicationSummary? _application;
  List<TimelineEntry> _timeline = [];
  List<DocumentEntry> _documents = [];
  List<RequirementDoc> _requirements = [];
  /// What the office asked for, while the application is returned to the citizen.
  List<InstructionLetter> _letters = [];
  bool _loading = true;
  bool _cancelling = false;
  bool _sendingBack = false;
  String? _error;
  String? _busyDocumentKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getApplication(widget.applicationId),
        _api.getTimeline(widget.applicationId),
        _api.listApplicationDocuments(widget.applicationId),
      ]);
      List<RequirementDoc> requirements = const [];
      try {
        requirements = await _api.applicationRequirements(widget.applicationId);
      } on ApiError {
        // The checklist is only used to spot a missing required file; the
        // rest of the page stands without it.
      }
      List<InstructionLetter> letters = const [];
      if ((results[0] as ApplicationSummary).lifecycleStatus == 'Revision Required') {
        try {
          letters = await _api.instructions(widget.applicationId);
        } on ApiError {
          // The remarks are also on the timeline; the card stands without them.
        }
      }
      if (!mounted) return;
      setState(() {
        _letters = letters;
        _application = results[0] as ApplicationSummary;
        _timeline = results[1] as List<TimelineEntry>;
        _documents = results[2] as List<DocumentEntry>;
        _requirements = requirements;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(messageBar(message));

  /// Picks a file, makes it something the server accepts (`readyForUpload`),
  /// hands it to [send] and shows what [send] reports — or why it could not
  /// go. A file the phone would not read used to do nothing at all.
  Future<void> _sendPicked(String busyKey, Future<String> Function(ReadyUpload file) send) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final picked = result?.files.single;
    if (picked == null || !mounted) return;
    setState(() => _busyDocumentKey = busyKey);
    try {
      final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) throw const UploadRefused(unreadableFile);
      final done = await send(await readyForUpload(picked.name, bytes));
      if (!mounted) return;
      _toast(done);
      await _load();
    } on UploadRefused catch (e) {
      if (mounted) _toast(e.message);
    } on ApiError catch (e) {
      if (mounted) _toast(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busyDocumentKey = null);
    }
  }

  /// The portal's `onReplace`: a new version of a document the office
  /// rejected or asked to revise. Stripped metadata is reported, not hidden.
  Future<void> _replace(DocumentEntry doc) => _sendPicked(doc.id, (file) async {
        final removed = await _api.resubmitDocument(
          applicationId: widget.applicationId,
          documentId: doc.id,
          fileName: file.fileName,
          label: doc.label,
          contentBase64: base64Encode(file.bytes),
        );
        final stripped = removed.isEmpty ? '' : ' ${removed.join(', ')} was removed from the file.';
        return 'Replacement sent for "${doc.label}".$stripped';
      });

  /// The portal's `attachMissing`: first-time upload for a required document
  /// nothing has been sent for yet, attached to this application.
  Future<void> _attachMissing(RequirementDoc req) => _sendPicked(req.code, (file) async {
        final upload = await _api.uploadOrReuse(
          fileName: file.fileName,
          label: req.label,
          contentBase64: base64Encode(file.bytes),
          applicationId: widget.applicationId,
          requirementCode: req.code,
        );
        final reused = upload.reused;
        return reused == null
            ? '"${req.label}" sent.'
            : '"${req.label}" sent, using the copy of "${reused.fileName}" already in My Documents.';
      });

  /// The portal's `canCancel`: the applicant's own `-> Cancelled` transitions,
  /// and only before any fee has been assessed.
  bool get _canCancel {
    final app = _application;
    if (app == null || app.orderOfPayment != null) return false;
    const cancellable = {'Draft', 'Submitted', 'Received', 'Revision Required'};
    return cancellable.contains(app.lifecycleStatus);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this application?'),
        content: const Text(
          'This cannot be undone. You can file a new application later if you change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: SoftColors.danger),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cancelling = true);
    try {
      await _api.cancelApplication(widget.applicationId);
      await _load();
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(messageBar('Application withdrawn.'));
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(messageBar(e.citizenMessage));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Documents the office returned (Revision Required or Rejected) that no
  /// newer upload replaces yet — the same test the server's
  /// `returned-documents-replaced` precondition applies.
  List<DocumentEntry> get _returnedNotReplaced => _documents
      .where((d) =>
          (d.reviewStatus == 'Revision Required' || d.reviewStatus == 'Rejected') &&
          d.supersededByDocumentId == null)
      .toList();

  Future<void> _sendBack() async {
    setState(() => _sendingBack = true);
    try {
      await _api.sendBackToOffice(widget.applicationId);
      await _load();
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        messageBar('Sent back to the office for evaluation.'),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(messageBar(e.citizenMessage));
    } finally {
      if (mounted) setState(() => _sendingBack = false);
    }
  }

  Widget _sendBackCard() {
    final outstanding = _returnedNotReplaced;
    final ready = outstanding.isEmpty;
    final names = outstanding.map((d) => d.label).join(', ');
    return SoftCard(
      color: ready ? SoftColors.verifiedSoft : SoftColors.pendingCream,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_letters.any((letter) => letter.items.isNotEmpty)) ...[
            Text('What the office needs from you', style: SoftType.tileTitle),
            for (final letter in _letters)
              for (final item in letter.items)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.remark, style: SoftType.body.copyWith(color: SoftColors.ink)),
                      const SizedBox(height: 2),
                      Text('Sent ${_sentOn(letter.issuedAt)}', style: SoftType.tileSub),
                    ],
                  ),
                ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: SoftColors.line)),
          ],
          Text(
            ready ? 'Ready to send back' : 'The office returned this application',
            style: SoftType.tileTitle,
          ),
          const SizedBox(height: 6),
          Text(
            ready
                ? 'Every returned document has been replaced. Send the application back so the office can continue evaluating it.'
                : 'Replace ${outstanding.length == 1 ? 'the returned document' : 'the ${outstanding.length} returned documents'} '
                    'below ($names), then send the application back to the office.',
            style: SoftType.body.copyWith(color: SoftColors.ink),
          ),
          const SizedBox(height: 12),
          SoftPillButton(
            label: _sendingBack ? 'Sending…' : 'Send Back to the Office',
            icon: Icons.send_rounded,
            busy: _sendingBack,
            onPressed: ready && !_sendingBack ? _sendBack : null,
          ),
        ],
      ),
    );
  }

  static String _sentOn(String iso) {
    final when = DateTime.tryParse(iso)?.toLocal();
    return when == null ? iso : DateFormat('MMM d, yyyy, h:mm a').format(when);
  }

  /// Required checklist items the server has no document for at all — a
  /// rejected one is not missing, it has its own Replace action.
  List<RequirementDoc> get _missingRequired =>
      _requirements.where((r) => r.required && r.documentIds.isEmpty).toList();

  /// The reference is what a citizen reads out at the counter or types into
  /// a message, so it copies with a tap.
  void _copyReference(String reference) {
    Clipboard.setData(ClipboardData(text: reference));
    _toast('Reference number copied.');
  }

  void _open(Widget page, {bool reloadAfter = false}) {
    final pushed = Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (reloadAfter) pushed.then((_) => _load());
  }

  static String _day(String? iso) {
    if (iso == null) return 'Not yet';
    final when = DateTime.tryParse(iso)?.toLocal();
    return when == null ? iso : DateFormat('MMM d, yyyy').format(when);
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    return SoftPageScaffold(
      // The reference is on the header card, with its copy button.
      title: 'Application',
      body: _loading && app == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && app == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: AppTypography.error),
              ),
            )
          : app == null
          ? const SizedBox.shrink()
          : RefreshIndicator(onRefresh: _load, child: _body(app)),
    );
  }

  Widget _body(ApplicationSummary app) {
    final lifecycle = LifecycleStatusX.fromLabel(app.lifecycleStatus);
    final step = lifecycle.journeyStep;
    final settled = step == null || step >= journeySteps.length;
    final showPay =
        app.orderOfPayment != null &&
        (app.paymentStatus == 'Not Yet Available' ||
            app.paymentStatus == 'Overdue');
    final showPermit =
        app.applicantStatus == 'Approved' ||
        app.applicantStatus == 'Ready for Release';

    // What the citizen can do now. The first is the page's one main button.
    final actions = <(String, IconData, VoidCallback)>[
      if (lifecycle == LifecycleStatus.draft)
        ('Continue Application', Icons.edit_outlined,
            () => _open(ApplicationWizardScreen(draftId: app.id), reloadAfter: true)),
      if (showPay)
        ('Pay Now', Icons.payments_outlined,
            () => _open(PaymentFlowScreen(applicationId: app.id), reloadAfter: true)),
      if (showPermit)
        ('View Permit', Icons.verified_outlined,
            () => _open(PermitDocumentScreen(applicationId: app.id, applicationReference: app.displayReference))),
    ];

    final IconData nextIcon = step == null
        ? Icons.do_not_disturb_on_outlined
        : lifecycle == LifecycleStatus.draft
        ? Icons.edit_note_rounded
        : lifecycle == LifecycleStatus.revisionRequired
        ? Icons.assignment_return_outlined
        : showPay
        ? Icons.payments_outlined
        : showPermit || settled
        ? Icons.verified_outlined
        : Icons.hourglass_top_rounded;

    final details = <(IconData, String, String)>[
      (Icons.category_outlined, 'Application type', app.applicationAction),
      if (app.renewsPermitNumber case final permit?)
        (Icons.autorenew_rounded, app.applicationAction == 'Renewal' ? 'Renewing permit' : 'Amending permit', permit),
      (Icons.account_balance_wallet_outlined, 'Payment', app.paymentStatus),
      (Icons.send_outlined, 'Submitted', _day(app.dateSubmitted)),
      (Icons.update_rounded, 'Last updated', _day(app.updatedAt)),
      // What the citizen entered in the Details step (QA TC-23, 2026-10-03):
      // staff saw it, the citizen never did.
      for (final (icon, label, key) in const [
        (Icons.construction_outlined, 'Scope of work', 'scopeOfWork'),
        (Icons.engineering_outlined, 'Professional in charge', 'professionalName'),
        (Icons.badge_outlined, 'PRC License No.', 'prcNumber'),
      ])
        if (app.form[key] case final String value when value.trim().isNotEmpty) (icon, label, value.trim()),
    ];

    final chains = groupDocumentChains(_documents);
    final missing = !const {'Draft', 'Cancelled', 'Rejected', 'Expired', 'Released', 'Completed'}.contains(app.lifecycleStatus)
        ? _missingRequired
        : const <RequirementDoc>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _Header(app: app, step: step, onCopyReference: () => _copyReference(app.referenceNumber)),
        const SizedBox(height: 16),
        _NextStepCard(
          icon: nextIcon,
          eyebrow: settled ? 'Status' : 'What happens next',
          muted: step == null,
          text: lifecycle.nextStep,
          actions: [
            for (final (i, action) in actions.indexed)
              SoftPillButton(
                label: action.$1,
                icon: action.$2,
                kind: i == 0 ? SoftPillKind.primary : SoftPillKind.outline,
                onPressed: action.$3,
              ),
          ],
        ),
        if (lifecycle == LifecycleStatus.revisionRequired) ...[
          const SizedBox(height: 12),
          _sendBackCard(),
        ],
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoftCard(
            color: SoftColors.dangerSoft,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 20, color: SoftColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Missing Required Documents', style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600, color: SoftColors.danger)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('The Municipality still needs these to continue reviewing your application.', style: SoftType.body.copyWith(color: SoftColors.ink)),
                for (final req in missing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(req.label, style: SoftType.tileTitle)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 128,
                        child: SoftPillButton(
                          label: 'Choose File',
                          busy: _busyDocumentKey == req.code,
                          onPressed: _busyDocumentKey != null ? null : () => _attachMissing(req),
                        ),
                      ),
                    ],
                  ),
                  // A missing form to sign on paper: the blank one, to print.
                  if (blankFormFor(req.code) case final form?) ...[
                    const SizedBox(height: 10),
                    BlankFormLink(form: form),
                  ],
                ],
              ],
            ),
          ),
        ],
        if (app.orderOfPayment != null) ...[
          const SizedBox(height: 12),
          _AssessmentCard(
            order: app.orderOfPayment!,
            paid: app.paymentStatus == 'Paid',
            pendingVerification: !const {'Not Yet Available', 'Overdue', 'Paid'}.contains(app.paymentStatus),
            onView: () => _open(OrderOfPaymentScreen(applicationId: app.id)),
          ),
        ],
        const SizedBox(height: 26),
        const _SectionTitle('Details'),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, row) in details.indexed) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: SoftColors.line, indent: 32),
                _DetailRow(icon: row.$1, label: row.$2, value: row.$3),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        _SectionTitle('Documents', count: chains.isEmpty ? null : chains.length),
        if (chains.isEmpty)
          _EmptySection(
            icon: Icons.folder_open_rounded,
            title: 'No documents yet',
            message: lifecycle == LifecycleStatus.draft
                ? 'Attach them when you continue your application.'
                : 'Files sent with this application show here.',
          )
        else
          for (final chain in chains)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentChainCard(
                current: chain.current,
                superseded: chain.superseded,
                replacing: _busyDocumentKey == chain.current.id,
                onReplace: _busyDocumentKey != null ? null : () => _replace(chain.current),
                returned: lifecycle == LifecycleStatus.revisionRequired,
              ),
            ),
        const SizedBox(height: 26),
        const _SectionTitle('Timeline'),
        if (_timeline.isEmpty)
          const _EmptySection(icon: Icons.timeline_rounded, title: 'No activity yet', message: 'Each step the office takes shows here.')
        else
          SoftCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
            child: Column(
              children: [
                for (final (i, t) in _timeline.reversed.indexed)
                  _TimelineRow(
                    entry: t,
                    first: i == 0,
                    last: i == _timeline.length - 1,
                  ),
              ],
            ),
          ),
        if (_canCancel) ...[
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: _cancelling ? null : _cancel,
              style: TextButton.styleFrom(
                foregroundColor: SoftColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: SoftType.button,
              ),
              icon: _cancelling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SoftColors.danger))
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: Text(_cancelling ? 'Withdrawing…' : 'Withdraw Application'),
            ),
          ),
        ],
      ],
    );
  }
}

/// The page's top: what this application is, its status and reference, and
/// how far along it is — the dashboard's red feature card, so the screen
/// opens on the one thing a citizen came to check.
class _Header extends StatelessWidget {
  final ApplicationSummary app;
  final int? step;
  final VoidCallback onCopyReference;
  const _Header({required this.app, required this.step, required this.onCopyReference});

  static const _soft = Color(0xE0FFFFFF);
  static const _faint = Color(0x33FFFFFF);

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _soft),
          const SizedBox(width: 5),
          Flexible(child: Text(text, style: SoftType.tileSub.copyWith(color: _soft, fontSize: 13.5))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final status = statusStyleForLabel(app.statusLabel);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: SoftColors.primaryGradient,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        boxShadow: SoftShadows.feature,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _faint, borderRadius: BorderRadius.circular(SoftRadius.sm)),
                child: const Icon(Icons.apartment_rounded, color: SoftColors.white, size: 22),
              ),
              const Spacer(),
              // White, so the status keeps its own color on the red.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: SoftColors.white, borderRadius: BorderRadius.circular(SoftRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: status.foreground, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(app.statusLabel, style: SoftType.cellLabel.copyWith(color: status.foreground, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(app.permitType, style: SoftType.h1.copyWith(color: SoftColors.white, fontSize: 24)),
          const SizedBox(height: 4),
          if (!app.hasOfficialReference)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(app.displayReference, style: SoftType.cellValue.copyWith(color: _soft, fontSize: 14)),
            )
          else
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onCopyReference,
              borderRadius: BorderRadius.circular(SoftRadius.sm),
              child: Semantics(
                button: true,
                label: 'Reference ${app.referenceNumber}. Tap to copy.',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        app.referenceNumber,
                        style: SoftType.cellValue.copyWith(
                          color: _soft,
                          fontSize: 14,
                          letterSpacing: 0.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy_rounded, size: 14, color: _soft),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (app.businessName != null || app.location != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (app.businessName case final business?) _meta(Icons.storefront_outlined, business),
                if (app.location case final place?) _meta(Icons.place_outlined, place),
              ],
            ),
          ],
          if (step case final at?) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: _faint),
            const SizedBox(height: 16),
            _StepTracker(step: at),
          ],
        ],
      ),
    );
  }
}

/// [journeySteps] as dots on a line: done ticked, the current one ringed,
/// the rest hollow. Drawn on the header's red.
class _StepTracker extends StatelessWidget {
  final int step;
  const _StepTracker({required this.step});

  static const _faint = Color(0x4DFFFFFF);

  Widget _dot(int i) {
    if (i < step) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 14, color: SoftColors.primary),
      );
    }
    if (i == step) {
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x40FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: SoftColors.white, width: 2),
        ),
        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle)),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _faint, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = journeySteps.length;
    return Semantics(
      label: step >= count ? 'All steps done' : 'Step ${step + 1} of $count: ${journeySteps[step]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        Expanded(child: i == 0 ? const SizedBox.shrink() : Container(height: 2, color: i <= step ? SoftColors.white : _faint)),
                        _dot(i),
                        Expanded(child: i == count - 1 ? const SizedBox.shrink() : Container(height: 2, color: i < step ? SoftColors.white : _faint)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      journeySteps[i],
                      style: SoftType.cellLabel.copyWith(
                        fontSize: 11.5,
                        color: i <= step ? SoftColors.white : const Color(0xB3FFFFFF),
                        fontWeight: i == step ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What happens next, in the same words the portal uses, with the button
/// that does it right under the sentence that asks for it.
class _NextStepCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String text;
  final bool muted;
  final List<Widget> actions;
  const _NextStepCard({required this.icon, required this.eyebrow, required this.text, required this.muted, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftIconTile(
                icon: icon,
                size: 42,
                background: muted ? SoftColors.chipWash : SoftColors.primarySoft,
                foreground: muted ? SoftColors.muted : SoftColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: SoftType.cellLabel.copyWith(
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: muted ? SoftColors.muted : SoftColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: SoftType.body.copyWith(color: SoftColors.ink, fontSize: 15, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          for (final (i, action) in actions.indexed) ...[
            SizedBox(height: i == 0 ? 16 : 10),
            action,
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionTitle(this.title, {this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Text(title, style: SoftType.section.copyWith(fontSize: 18)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SoftColors.primarySoft, borderRadius: BorderRadius.circular(SoftRadius.pill)),
              child: Text('$count', style: SoftType.cellLabel.copyWith(color: SoftColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 19, color: SoftColors.muted),
          const SizedBox(width: 13),
          Text(label, style: SoftType.body),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: SoftType.cellValue.copyWith(fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// An empty section, said plainly, with what will fill it.
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptySection({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SoftIconTile(icon: icon, size: 42, background: SoftColors.chipWash, foreground: SoftColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SoftType.tileTitle),
                const SizedBox(height: 2),
                Text(message, style: SoftType.tileSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The portal's `app-application-documents`, one document chain per card:
/// the office's verdict (null is "Not yet reviewed", never a tick), the
/// cited reason, the scanner and validity notes on their own lines, View,
/// Replace when the office asked for it, and earlier versions kept visible.
class _DocumentChainCard extends StatefulWidget {
  final DocumentEntry current;
  final List<DocumentEntry> superseded;
  final bool replacing;
  final VoidCallback? onReplace;
  /// The application is back with the citizen for revision.
  final bool returned;
  const _DocumentChainCard({
    required this.current, required this.superseded, required this.replacing, required this.onReplace, required this.returned,
  });

  @override
  State<_DocumentChainCard> createState() => _DocumentChainCardState();
}

class _DocumentChainCardState extends State<_DocumentChainCard> {
  bool _showHistory = false;

  static const _expiryWarningDays = 60;

  /// The portal's `documentValidity`, in whole UTC days.
  (String, bool)? _validity(String? expiresOn) {
    if (expiresOn == null) return null;
    final due = DateTime.tryParse(expiresOn);
    if (due == null) return null;
    final today = DateTime.now().toUtc();
    final days = DateTime.utc(due.year, due.month, due.day).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final on = expiresOn.length >= 10 ? expiresOn.substring(0, 10) : expiresOn;
    if (days < 0) {
      final ago = -days;
      return ('This document expired on $on ($ago ${ago == 1 ? 'day' : 'days'} ago). The Municipality is likely to ask for a current one.', true);
    }
    if (days <= _expiryWarningDays) {
      return ('Valid until $on — ${days == 0 ? 'the last day' : '$days ${days == 1 ? 'day' : 'days'} left'}.', false);
    }
    return ('Valid until $on.', false);
  }

  void _view(DocumentEntry doc) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => DocumentViewerScreen(documentId: doc.id, title: doc.label)));

  @override
  Widget build(BuildContext context) {
    final doc = widget.current;
    final why = doc.explanation;
    final validity = _validity(doc.expiresOn);
    Widget note(String text, {bool danger = false}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(text, style: SoftType.cellLabel.copyWith(fontSize: 13, color: danger ? SoftColors.danger : SoftColors.muted)),
        );

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftIconTile(icon: Icons.insert_drive_file_outlined, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.label, style: SoftType.tileTitle),
                    const SizedBox(height: 2),
                    Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.tileSub),
                    const SizedBox(height: 8),
                    StatusBadge(label: doc.reviewStatus ?? 'Not yet reviewed'),
                  ],
                ),
              ),
            ],
          ),
          if (doc.quarantined)
            note('This file was held by the virus scanner and has not been reviewed. It is not a decision about your application.', danger: true)
          else if (!doc.scanCleared)
            note('Being checked for viruses.'),
          if (why != null) note('Why: $why', danger: true),
          if (validity != null) note(validity.$1, danger: validity.$2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SoftPillButton(label: 'View', kind: SoftPillKind.outline, icon: Icons.visibility_outlined, onPressed: () => _view(doc))),
              if (doc.canReplaceWhile(returned: widget.returned)) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SoftPillButton(label: 'Replace', icon: Icons.upload_file_rounded, busy: widget.replacing, onPressed: widget.onReplace),
                ),
              ],
            ],
          ),
          if (widget.superseded.isNotEmpty) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() => _showHistory = !_showHistory),
              child: Text(
                '${_showHistory ? 'Hide' : 'Show'} ${widget.superseded.length} earlier version${widget.superseded.length == 1 ? '' : 's'}',
              ),
            ),
            if (_showHistory)
              for (final old in widget.superseded)
                InkWell(
                  onTap: () => _view(old),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${old.fileName} — ${old.reviewStatus ?? 'Not yet reviewed'}', style: SoftType.cellValue.copyWith(fontSize: 13)),
                        if (old.explanation != null)
                          Text('Why: ${old.explanation}', style: SoftType.cellLabel.copyWith(color: SoftColors.danger)),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// The Order of Payment's own lines — the portal's assessment card.
class _AssessmentCard extends StatelessWidget {
  final OrderOfPayment order;
  final bool paid;
  final bool pendingVerification;
  final VoidCallback onView;
  const _AssessmentCard({required this.order, required this.paid, required this.pendingVerification, required this.onView});

  static const _lines = [
    ('filing', 'Filing Fee'),
    ('processing', 'Processing Fee'),
    ('architectural', 'Architectural Fee'),
    ('structural', 'Structural Fee'),
    ('electrical', 'Electrical Fee'),
    ('others', 'Other Fees'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: bold ? SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600) : SoftType.body)),
              Text(value, style: SoftType.cellValue.copyWith(fontWeight: bold ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        );
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order of Payment', style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'No. ${order.number}${order.dueDate != null ? ' · Due ${order.dueDate!.substring(0, 10)}' : ''}',
            style: SoftType.cellLabel.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final line in _lines)
            if ((order.fees[line.$1] ?? 0) > 0) row(line.$2, pesos(order.fees[line.$1]!)),
          const Divider(height: 16, color: SoftColors.line),
          row('Total', pesos(order.totalCentavos), bold: true),
          // The balance stands until the Cashier verifies a payment, and says so (QA TC-27).
          row('Balance', '${pesos(paid ? 0 : order.totalCentavos)}${pendingVerification ? ' — pending verification' : ''}'),
          const SizedBox(height: 10),
          // Onsite Payment asks for a copy of the Order (QA TC-26).
          SoftPillButton(label: 'View Order of Payment', kind: SoftPillKind.outline, icon: Icons.receipt_long_outlined, onPressed: onView),
        ],
      ),
    );
  }
}

/// One event, newest first: the latest one ringed in red, the office's
/// remark set apart under it.
class _TimelineRow extends StatelessWidget {
  final TimelineEntry entry;
  final bool first;
  final bool last;
  const _TimelineRow({
    required this.entry,
    required this.first,
    required this.last,
  });

  static String _when(String iso) {
    final when = DateTime.tryParse(iso)?.toLocal();
    return when == null ? iso : DateFormat('MMM d, yyyy · h:mm a').format(when);
  }

  @override
  Widget build(BuildContext context) {
    final remarks = entry.remarks;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: first ? 18 : 12,
                  height: first ? 18 : 12,
                  margin: EdgeInsets.only(top: first ? 0 : 3),
                  decoration: BoxDecoration(
                    color: first ? SoftColors.primary : SoftColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: first ? SoftColors.primarySoft : SoftColors.chevron,
                      width: first ? 4 : 2,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: SoftColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.status,
                    style: SoftType.tileTitle.copyWith(
                      fontWeight: first ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(_when(entry.occurredAt), style: SoftType.cellLabel),
                  if (remarks != null && remarks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: SoftColors.chipWash,
                        borderRadius: BorderRadius.circular(SoftRadius.sm),
                      ),
                      child: Text(remarks, style: SoftType.body.copyWith(color: SoftColors.ink, fontSize: 13.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
