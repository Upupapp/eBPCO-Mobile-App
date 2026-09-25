import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/status_badge.dart';
import '../payments/payment_flow_screen.dart';
import '../permits/application_wizard_screen.dart';
import 'permit_document_screen.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
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
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canCancel {
    final status = _application?.lifecycleStatus;
    return status == 'Draft' || status == 'Submitted' || status == 'Received' || status == 'Revision Required';
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this application?'),
        content: const Text('This cannot be undone. You can file a new application later if you change your mind.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cancelling = true);
    try {
      await _api.cancelApplication(widget.applicationId);
      await _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(app?.referenceNumber ?? 'Application')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: AppTypography.error)))
                : app == null
                    ? const SizedBox.shrink()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 40),
                          children: [
                            SoftCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(app.permitType, style: AppTypography.h2)),
                                      StatusBadge(label: app.applicantStatus),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${app.applicationAction} · ${app.referenceNumber}', style: AppTypography.body),
                                  if (app.location != null) ...[
                                    const SizedBox(height: 8),
                                    Text(app.location!, style: AppTypography.caption),
                                  ],
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(color: AppColors.info100, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: AppColors.infoText, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            LifecycleStatusX.fromLabel(app.lifecycleStatus).nextStep,
                                            style: AppTypography.caption.copyWith(color: AppColors.infoText),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (app.lifecycleStatus == 'Draft')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => ApplicationWizardScreen(draftId: app.id)))
                                      .then((_) => _load()),
                                  child: const Text('Continue Application'),
                                ),
                              ),
                            if (app.orderOfPayment != null &&
                                (app.paymentStatus == 'Not Yet Available' || app.paymentStatus == 'Overdue'))
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => PaymentFlowScreen(applicationId: app.id)))
                                      .then((_) => _load()),
                                  child: const Text('Pay Now'),
                                ),
                              ),
                            if (app.applicantStatus == 'Approved' || app.applicantStatus == 'Ready for Release')
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => PermitDocumentScreen(applicationId: app.id, applicationReference: app.referenceNumber),
                                    )),
                                    child: const Text('View Permit'),
                                  ),
                                ),
                              ),
                            if (_canCancel && app.lifecycleStatus != 'Draft') ...[
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _cancelling ? null : _cancel,
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger100)),
                                  child: Text(_cancelling ? 'Withdrawing…' : 'Withdraw Application'),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                            Text('Documents', style: AppTypography.h3),
                            const SizedBox(height: AppSpacing.sm),
                            if (_documents.isEmpty)
                              Text('No documents attached yet.', style: AppTypography.caption)
                            else
                              ..._documents.map((d) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SoftCard(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(d.label, style: AppTypography.bodyMedium),
                                                Text(d.fileName, style: AppTypography.caption),
                                              ],
                                            ),
                                          ),
                                          if (d.reviewStatus != null) StatusBadge(label: d.reviewStatus!),
                                        ],
                                      ),
                                    ),
                                  )),
                            const SizedBox(height: AppSpacing.xxl),
                            Text('Timeline', style: AppTypography.h3),
                            const SizedBox(height: AppSpacing.sm),
                            ..._timeline.reversed.map((t) => _TimelineRow(entry: t)),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEntry entry;
  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary500, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.status, style: AppTypography.bodyMedium),
                Text(entry.occurredAt.substring(0, 10), style: AppTypography.caption),
                if (entry.remarks != null && entry.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.remarks!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
