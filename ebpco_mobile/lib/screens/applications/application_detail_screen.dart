import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';
import '../documents/document_viewer_screen.dart';
import '../payments/payment_flow_screen.dart';
import '../payments/payments_list_screen.dart';
import '../permits/application_wizard_screen.dart';
import 'permit_document_screen.dart';

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
  bool _loading = true;
  bool _cancelling = false;
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
      if (!mounted) return;
      setState(() {
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

  Future<({String name, List<int> bytes})?> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final picked = result?.files.single;
    if (picked == null) return null;
    final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
    if (bytes == null) return null;
    return (name: picked.name, bytes: bytes);
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// The portal's `onReplace`: a new version of a document the office
  /// rejected or asked to revise. Stripped metadata is reported, not hidden.
  Future<void> _replace(DocumentEntry doc) async {
    final file = await _pickFile();
    if (file == null || !mounted) return;
    setState(() => _busyDocumentKey = doc.id);
    try {
      final removed = await _api.resubmitDocument(
        applicationId: widget.applicationId,
        documentId: doc.id,
        fileName: file.name,
        label: doc.label,
        contentBase64: base64Encode(file.bytes),
      );
      if (!mounted) return;
      final stripped = removed.isEmpty ? '' : ' ${removed.join(', ')} was removed from the file.';
      _toast('Replacement sent for "${doc.label}".$stripped');
      await _load();
    } on ApiError catch (e) {
      if (mounted) _toast(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busyDocumentKey = null);
    }
  }

  /// The portal's `attachMissing`: first-time upload for a required document
  /// nothing has been sent for yet, attached to this application.
  Future<void> _attachMissing(RequirementDoc req) async {
    final file = await _pickFile();
    if (file == null || !mounted) return;
    setState(() => _busyDocumentKey = req.code);
    try {
      await _api.uploadDocument(
        fileName: file.name,
        label: req.label,
        contentBase64: base64Encode(file.bytes),
        applicationId: widget.applicationId,
        requirementCode: req.code,
      );
      if (!mounted) return;
      _toast('"${req.label}" sent.');
      await _load();
    } on ApiError catch (e) {
      if (mounted) _toast(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busyDocumentKey = null);
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application withdrawn.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Required checklist items the server has no document for at all — a
  /// rejected one is not missing, it has its own Replace action.
  List<RequirementDoc> get _missingRequired =>
      _requirements.where((r) => r.required && r.documentIds.isEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final app = _application;
    return SoftPageScaffold(
      title: app?.referenceNumber ?? 'Application',
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
    final showPay =
        app.orderOfPayment != null &&
        (app.paymentStatus == 'Not Yet Available' ||
            app.paymentStatus == 'Overdue');
    final showPermit =
        app.applicantStatus == 'Approved' ||
        app.applicantStatus == 'Ready for Release';
    final cells = <(String, String)>[
      ('Application type', app.applicationAction),
      ('Payment', app.paymentStatus),
      ('Submitted', app.dateSubmitted?.substring(0, 10) ?? 'Not yet'),
      ('Last updated', app.updatedAt.substring(0, 10)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusBadge(label: app.statusLabel),
        ),
        const SizedBox(height: 12),
        Text(app.permitType, style: SoftType.h1),
        const SizedBox(height: 4),
        Text(app.referenceNumber, style: SoftType.body.copyWith(fontSize: 15)),
        if (app.businessName != null || app.location != null) ...[
          const SizedBox(height: 4),
          Text(
            [app.businessName, app.location].whereType<String>().join(' · '),
            style: SoftType.body,
          ),
        ],
        const SizedBox(height: 16),
        SoftCard(
          color: SoftColors.primaryWash,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoftIconTile(
                icon: Icons.info_outline_rounded,
                background: SoftColors.white,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next step',
                      style: SoftType.cellLabel.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LifecycleStatusX.fromLabel(app.lifecycleStatus).nextStep,
                      style: SoftType.body.copyWith(color: SoftColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [for (final c in cells) _Cell(label: c.$1, value: c.$2)],
        ),
        const SizedBox(height: 20),
        if (app.lifecycleStatus == 'Draft') ...[
          SoftPillButton(
            label: 'Continue Application',
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => ApplicationWizardScreen(draftId: app.id),
                  ),
                )
                .then((_) => _load()),
          ),
          const SizedBox(height: 10),
        ],
        if (showPay) ...[
          SoftPillButton(
            label: 'Pay Now',
            icon: Icons.payments_outlined,
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => PaymentFlowScreen(applicationId: app.id),
                  ),
                )
                .then((_) => _load()),
          ),
          const SizedBox(height: 10),
        ],
        if (showPermit) ...[
          SoftPillButton(
            label: 'View Permit',
            kind: SoftPillKind.outline,
            icon: Icons.verified_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PermitDocumentScreen(
                  applicationId: app.id,
                  applicationReference: app.referenceNumber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_canCancel) ...[
          SoftPillButton(
            label: _cancelling ? 'Withdrawing…' : 'Withdraw Application',
            kind: SoftPillKind.dangerSoft,
            busy: _cancelling,
            onPressed: _cancelling ? null : _cancel,
          ),
          const SizedBox(height: 10),
        ],
        if (app.orderOfPayment != null) ...[
          const SizedBox(height: 14),
          _AssessmentCard(order: app.orderOfPayment!, paid: app.paymentStatus == 'Paid'),
        ],
        if (!const {'Draft', 'Cancelled', 'Rejected', 'Expired', 'Released', 'Completed'}.contains(app.lifecycleStatus) &&
            _missingRequired.isNotEmpty) ...[
          const SizedBox(height: 14),
          SoftCard(
            color: SoftColors.dangerSoft,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Missing Required Documents', style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600, color: SoftColors.danger)),
                const SizedBox(height: 4),
                Text('The Municipality still needs these to continue reviewing your application.', style: SoftType.body.copyWith(color: SoftColors.ink)),
                for (final req in _missingRequired) ...[
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
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SoftSectionHeader(title: 'Documents'),
        if (_documents.isEmpty)
          const SoftEmptyCard('No documents attached yet.')
        else
          for (final chain in groupDocumentChains(_documents))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentChainCard(
                current: chain.current,
                superseded: chain.superseded,
                replacing: _busyDocumentKey == chain.current.id,
                onReplace: _busyDocumentKey != null ? null : () => _replace(chain.current),
              ),
            ),
        const SizedBox(height: 24),
        const SoftSectionHeader(title: 'Timeline'),
        if (_timeline.isEmpty)
          const SoftEmptyCard('No activity yet.')
        else
          SoftCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
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
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: SoftType.cellLabel),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SoftType.cellValue.copyWith(fontWeight: FontWeight.w600),
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
  const _DocumentChainCard({required this.current, required this.superseded, required this.replacing, required this.onReplace});

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
              if (doc.canReplace) ...[
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
  const _AssessmentCard({required this.order, required this.paid});

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
          row('Balance', pesos(paid ? 0 : order.totalCentavos)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEntry entry;
  final bool first;
  final bool last;
  const _TimelineRow({
    required this.entry,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: first ? SoftColors.primary : SoftColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: first ? SoftColors.primary : SoftColors.chevron,
                      width: 2,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: SoftColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.status,
                    style: SoftType.tileTitle.copyWith(
                      color: first ? SoftColors.ink : SoftColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.occurredAt.substring(0, 10),
                    style: SoftType.cellLabel,
                  ),
                  if (entry.remarks != null && entry.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.remarks!, style: SoftType.body),
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
