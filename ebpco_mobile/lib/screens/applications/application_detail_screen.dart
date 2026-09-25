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
  bool _loading = true;
  bool _cancelling = false;
  String? _error;

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
      if (!mounted) return;
      setState(() {
        _application = results[0] as ApplicationSummary;
        _timeline = results[1] as List<TimelineEntry>;
        _documents = results[2] as List<DocumentEntry>;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
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
          child: StatusBadge(label: app.applicantStatus),
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
        const SizedBox(height: 14),
        const SoftSectionHeader(title: 'Documents'),
        if (_documents.isEmpty)
          const SoftEmptyCard('No documents attached yet.')
        else
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _documents.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: SoftColors.line),
                  _DocumentRow(doc: _documents[i]),
                ],
              ],
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

class _DocumentRow extends StatelessWidget {
  final DocumentEntry doc;
  const _DocumentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DocumentViewerScreen(documentId: doc.id, title: doc.label),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SoftIconTile(
              icon: Icons.insert_drive_file_outlined,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.label, style: SoftType.tileTitle),
                  const SizedBox(height: 2),
                  Text(
                    doc.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SoftType.tileSub,
                  ),
                ],
              ),
            ),
            if (doc.reviewStatus != null) ...[
              const SizedBox(width: 8),
              Flexible(child: StatusBadge(label: doc.reviewStatus!)),
            ],
            const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
          ],
        ),
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
