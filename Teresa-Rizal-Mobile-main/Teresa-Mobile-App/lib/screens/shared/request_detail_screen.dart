import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/request_milestones.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_flow_scaffold.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/request_milestone_timeline.dart';
import '../../widgets/requirement_uploader.dart';
import '../../widgets/status_chip.dart';
import '../../utils/requirement_document_type.dart';
import 'new_request_screen.dart';
import 'receipt_screen.dart';
import 'service_request_wizard_screen.dart';

/// Full request detail + status timeline — status/history is always
/// whatever [RequestsService] currently holds for this request, so a
/// future Web Admin/backend integration updating that data is reflected
/// here automatically; nothing citizen-facing on this screen is demo-only.
///
/// Dokyu/Tulong requests get the richer [RequestMilestoneTimeline] (Phase
/// 5 — frontend simulation, see docs) plus a clearly-separated "Demo
/// Controls" card for manually advancing the simulation during
/// presentations; Sakuna incident reports keep the older, simpler
/// newest-first history list since the milestone/payment system was never
/// meant to apply there.
class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  /// Set only when opened from an "Application Needs Correction"
  /// notification's Replace Document action (see notification_feed.dart) —
  /// scrolls straight to that one [FlaggedRequirement]'s own uploader card
  /// once the screen renders, so the citizen never has to search for it
  /// among other requirements. Ignored if that entry is already resolved or
  /// no longer exists (e.g. an old, already-actioned notification) — the
  /// screen just shows the request's current state instead.
  final String? focusFlaggedRequirementId;

  const RequestDetailScreen({super.key, required this.requestId, this.focusFlaggedRequirementId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _demoBusy = false;
  final _flaggedCardKeys = <String, GlobalKey>{};

  GlobalKey _keyFor(String flaggedId) => _flaggedCardKeys.putIfAbsent(flaggedId, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    final target = widget.focusFlaggedRequirementId;
    if (target == null) return;
    // One-shot, after the first frame this screen renders — by then the
    // targeted card's GlobalKey (assigned while building the corrections
    // section below) is attached, if that entry still exists and is still
    // unresolved. Nothing to scroll to (a stale/already-actioned
    // notification) simply leaves the screen showing the top as usual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _flaggedCardKeys[target]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
      }
    });
  }

  Future<void> _advance(RequestsService service) async {
    final next = service.nextMilestone(widget.requestId);
    if (next == null) return;
    setState(() => _demoBusy = true);
    AppHaptics.medium();
    await service.advanceMilestone(widget.requestId);
    if (mounted) setState(() => _demoBusy = false);
  }

  /// Prefers the requested service's own [CatalogItem.demoRejectionReason]
  /// (a realistic, service-specific reason — see A15 of the Mobile <-> Web
  /// Admin final alignment pass) and falls back to a generic-but-still-
  /// realistic ID-mismatch reason for any service that doesn't have one,
  /// so every Dokyu/Tulong request type keeps a working reject simulation.
  String _rejectionReasonFor(ServiceRequest request) {
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    for (final item in catalog) {
      if (item.name == request.typeName && item.demoRejectionReason != null) {
        return item.demoRejectionReason!;
      }
    }
    return 'The information you submitted did not match the information shown on your valid ID. '
        'Please review your details and submit the correct information.';
  }

  Future<void> _reject(RequestsService service, ServiceRequest request) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Reject this request? (Demo)',
      message: 'This simulates an admin rejecting the request, for demonstration purposes only. It cannot be undone.',
      confirmLabel: 'Reject (Demo)',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _demoBusy = true);
    AppHaptics.warning();
    await service.rejectDemo(widget.requestId, reason: _rejectionReasonFor(request));
    if (mounted) setState(() => _demoBusy = false);
  }

  /// The next genuinely-uploadable requirement for this request's own
  /// catalog item (skipping staff/office-process lines — see
  /// RequirementInfo.requiresUpload) that isn't already awaiting a
  /// replacement — the one a live demo of "Flagged for Replacement" flags
  /// next, so the walkthrough is deterministic and repeatable across every
  /// Dokyu/Tulong service without a separate per-service config, and so
  /// pressing the demo trigger again (while one is already flagged) flags a
  /// *different* requirement rather than re-flagging the same one —
  /// how the "multiple flagged documents" scenario is demoed. Null once
  /// every uploadable requirement is already flagged-and-unresolved, or if
  /// the item somehow has none at all (none currently do).
  RequirementInfo? _flaggableRequirementFor(ServiceRequest request) {
    final alreadyFlagged = request.flaggedRequirements.where((f) => !f.isResolved).map((f) => f.requirementLabel).toSet();
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    for (final item in catalog) {
      if (item.name != request.typeName) continue;
      final requirements = resolveRequirements(item.requirements);
      for (final r in requirements) {
        if (r.requiresUpload && !alreadyFlagged.contains(r.label)) return r;
      }
    }
    return null;
  }

  Future<void> _flagAdditionalDocuments(RequestsService service, ServiceRequest request) async {
    final requirement = _flaggableRequirementFor(request);
    if (requirement == null) return;
    final ok = await AppDialogs.confirm(
      context,
      title: 'Request additional documents? (Demo)',
      message: 'This simulates an admin flagging "${requirement.label}" as needing a new upload. The request stays '
          'active — it is not rejected.',
      confirmLabel: 'Flag Document (Demo)',
    );
    if (!ok || !mounted) return;
    setState(() => _demoBusy = true);
    AppHaptics.warning();
    await service.flagAdditionalDocuments(
      widget.requestId,
      requirementLabel: requirement.label,
      reason: 'The submitted "${requirement.label}" could not be verified. Please upload a clearer or updated copy.',
    );
    if (mounted) setState(() => _demoBusy = false);
  }

  Future<void> _resumeVerification(RequestsService service) async {
    setState(() => _demoBusy = true);
    AppHaptics.medium();
    await service.resumeVerification(widget.requestId);
    if (mounted) setState(() => _demoBusy = false);
  }

  Future<void> _replaceFlagged(RequestsService service, String flaggedId, Attachment newAttachment) async {
    setState(() => _demoBusy = true);
    AppHaptics.success();
    await service.replaceFlaggedRequirement(widget.requestId, flaggedId: flaggedId, newAttachment: newAttachment);
    if (mounted) setState(() => _demoBusy = false);
  }

  Future<void> _resubmitApplication(RequestsService service) async {
    setState(() => _demoBusy = true);
    AppHaptics.success();
    await service.resubmitApplication(widget.requestId);
    if (mounted) setState(() => _demoBusy = false);
  }

  /// "Apply Again" on a Rejected request's own Application Rejected panel —
  /// reopens a brand-new application for the same catalog item, reusing the
  /// exact same routing ServiceCatalogScreen's own item list already uses
  /// (formSpec present -> the wizard, otherwise the older single-step
  /// screen) rather than a second implementation. For Tulong, this still
  /// goes through the same eligibility check as opening the item fresh
  /// would (see utils/tulong_eligibility.dart) — a resident could have a
  /// second, still-active application for this same assistance even while
  /// looking at an earlier rejected one, and that must still block here
  /// exactly as it would from the catalog. Dokyu has no such restriction.
  /// The rejected request itself is never touched — submitting always
  /// creates a brand-new ServiceRequest with its own id/reference number
  /// (see RequestsService.submit).
  Future<void> _applyAgain(BuildContext context, ServiceRequest request, Color accent) async {
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    CatalogItem? item;
    for (final i in catalog) {
      if (i.name == request.typeName) {
        item = i;
        break;
      }
    }
    if (item == null) return; // no matching catalog item to reopen against

    if (request.category == ServiceCategory.tulong) {
      final account = context.read<CitizenSessionService>().account;
      if (account != null) {
        final result = tulongEligibilityFor(
          context.read<RequestsService>(),
          applicantId: account.id,
          typeName: item.name,
        );
        if (!result.isEligible) {
          final viewRequest = await showTulongBlockedDialog(context, result);
          if (viewRequest && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
            );
          }
          return;
        }
      }
    }

    if (!context.mounted) return;
    final resolvedItem = item;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => resolvedItem.formSpec != null
            ? ServiceRequestWizardScreen(category: request.category, item: resolvedItem, accent: accent)
            : NewRequestScreen(category: request.category, item: resolvedItem, accent: accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RequestsService>();
    final request = service.all.firstWhere((r) => r.id == widget.requestId);
    final status = AppStatusX.fromLabel(request.status);
    final accent = switch (request.category) {
      ServiceCategory.dokyu => SoftColors.blue,
      ServiceCategory.tulong => SoftColors.tulongInk,
      ServiceCategory.sakunaIncident => SoftColors.danger,
      ServiceCategory.unknown => SoftColors.muted,
    };
    final usesMilestones = request.category != ServiceCategory.sakunaIncident;

    return SoftFlowScaffold(
      title: request.referenceNumber,
      subtitle: request.typeName,
      resizeToAvoidBottomInset: true,
      body: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + MediaQuery.paddingOf(context).bottom + SoftIme.bottom(context)),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.typeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: SoftColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Flexible, not a bare fixed-size child — a longer
                      // status label ("Under Verification") plus a longer
                      // typeName together can exceed a narrow phone's width
                      // (see the matching fix in request_list_screen.dart's
                      // own _RequestTile row).
                      Flexible(child: StatusChip(status: status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(request.office, style: AppTypography.bodySmallRegular.copyWith(color: SoftColors.muted)),
                  const Divider(height: AppSpacing.xxl),
                  _infoRow('Purpose', request.purpose),
                  _infoRow('Expected processing time', request.expectedDays),
                  _infoRow('Submitted', _fmtFull(request.submittedAt)),
                  if (request.requiresPayment) _infoRow('Fee', request.fee),
                  if (request.paymentMethod != null) _infoRow('Payment method', request.paymentMethod!),
                  if (!usesMilestones && request.adminRemarks != null) _infoRow('Admin remarks', request.adminRemarks!),
                  // Permanently visible for the rest of this demo session
                  // once generated — not tied to the current milestone, so
                  // it stays reachable even after the request moves past
                  // Receipt Generated to Paid/Mark to Release/Released.
                  if (request.receipt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'View payment record',
                      icon: Icons.receipt_long_rounded,
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).push(
                        // TODO(PR-L): route to payment detail
                        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: request.receipt!)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_closedNotice(request) != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _closedNotice(request)!,
            ],
            // Noticeable, but only ever for a genuinely Rejected request
            // that actually has a reason on file — a seeded/older Rejected
            // demo request with no adminRemarks set simply doesn't show
            // this panel, exactly like before this feature existed.
            if (request.status == 'Rejected' && request.adminRemarks != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _RejectedApplicationCard(
                reason: request.adminRemarks!,
                guidance: request.rejectionGuidance ?? 'Submit a new ${request.typeName} application.',
                onApplyAgain: () => _applyAgain(context, request, accent),
              ),
            ],
            // Distinct from Rejected above — the request is still active,
            // not terminal, and resumable. Under Review covers two flavors
            // (see RequestsService.flagAdditionalDocuments/
            // flagManualVerification): one or more specific flagged
            // requirements each get their own re-upload control; no flagged
            // requirement at all means "needs manual verification" —
            // nothing for the citizen to do, so no upload control, just the
            // explanation.
            if (request.status == RequestMilestones.underReview) ...[
              const SizedBox(height: AppSpacing.xl),
              if (request.flaggedRequirements.isNotEmpty)
                _CorrectionsSection(
                  request: request,
                  accent: accent,
                  busy: _demoBusy,
                  keyFor: _keyFor,
                  onReplace: (flaggedId, a) => _replaceFlagged(service, flaggedId, a),
                  onResubmit: () => _resubmitApplication(service),
                  onFlagAnother: _flaggableRequirementFor(request) != null
                      ? () => _flagAdditionalDocuments(service, request)
                      : null,
                )
              else
                _ManualVerificationCard(
                  reason: request.adminRemarks ?? 'The request requires additional verification.',
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              usesMilestones ? 'Request Timeline' : 'Status Timeline',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SoftColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: usesMilestones
                  ? RequestMilestoneTimeline(request: request, accent: accent)
                  : Column(
                      children: [
                        for (int i = 0; i < request.statusHistory.length; i++)
                          _TimelineRow(
                            entry: request.statusHistory[request.statusHistory.length - 1 - i],
                            isLast: i == request.statusHistory.length - 1,
                            accent: accent,
                          ),
                      ],
                    ),
            ),
            if (usesMilestones && service.canAdvance(widget.requestId)) ...[
              const SizedBox(height: AppSpacing.xl),
              _DemoControlsCard(
                nextMilestone: service.nextMilestone(widget.requestId),
                busy: _demoBusy,
                onAdvance: () => _advance(service),
                onReject: () => _reject(service, request),
                onFlagDocs: _flaggableRequirementFor(request) != null
                    ? () => _flagAdditionalDocuments(service, request)
                    : null,
              ),
            ],
            // Under Review's own demo resolve action for the "needs manual
            // verification" flavor — the flagged-requirement flavor
            // resolves via the re-upload control in its own card above
            // instead, not this button.
            if (usesMilestones && request.status == RequestMilestones.underReview && request.flaggedRequirements.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Continue Verification (Demo)',
                icon: Icons.skip_next_rounded,
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                loading: _demoBusy,
                onPressed: _demoBusy ? null : () => _resumeVerification(service),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Attachments (${request.attachments.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SoftColors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: request.attachments
                    .map(
                      (a) => ListTile(
                        dense: true,
                        leading: Icon(_iconFor(a.category), color: accent, size: 18),
                        title: Text(a.fileName, style: AppTypography.bodySmallMedium),
                        subtitle: Text(
                          '${a.category.shortLabel} · ${a.readableSize}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (!status.isDone) ...[
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Cancel Request',
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  final ok = await AppDialogs.confirm(
                    context,
                    title: 'Cancel this request?',
                    message: 'This cannot be undone. You will need to submit a new request if you change your mind.',
                    confirmLabel: 'Cancel Request',
                    danger: true,
                  );
                  if (ok && context.mounted) {
                    await context.read<RequestsService>().cancel(widget.requestId);
                    if (context.mounted) AppDialogs.toast(context, 'Request cancelled.', success: false);
                  }
                },
                fullWidth: true,
              ),
            ],
          ],
        ),
    );
  }

  /// Approved, released, and cancelled are terminal-looking outcomes.
  /// Rejected, needs-correction, and manual verification keep their own
  /// panels below.
  Widget? _closedNotice(ServiceRequest request) {
    final (String title, String body, IconData icon) = switch (request.status) {
      'Approved' => (
          'Request approved',
          'The office in Teresa, Rizal accepted this request. It moves to release when the document or assistance is ready.',
          Icons.verified_outlined,
        ),
      'Mark to Release' => (
          'Marked for release',
          'This request is ready to release. Claim it from the issuing office in Teresa, Rizal when you are notified.',
          Icons.inventory_2_outlined,
        ),
      'Released' => (
          'Approved and released',
          'This request has been released. Claim it from the issuing office in Teresa, Rizal.',
          Icons.task_alt_rounded,
        ),
      'Cancelled' => (
          'Request cancelled',
          'You cancelled this request. It stays in Done for your records. Start a new one from Dokyu or Tulong if you still need the service.',
          Icons.block_outlined,
        ),
      _ => ('', '', Icons.circle),
    };
    if (title.isEmpty) return null;
    final cancelled = request.status == 'Cancelled';
    return _SoftNotice(
      icon: icon,
      title: title,
      body: body,
      background: cancelled ? SoftColors.blueWash : SoftColors.blueSoft,
      foreground: cancelled ? SoftColors.muted : SoftColors.blue,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: SoftColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmallMedium.copyWith(color: SoftColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(DateTime d) =>
      '${d.month}/${d.day}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  IconData _iconFor(AttachmentCategory c) => switch (c) {
    AttachmentCategory.image => Icons.image_outlined,
    AttachmentCategory.pdf => Icons.picture_as_pdf_outlined,
    AttachmentCategory.docx => Icons.description_outlined,
    AttachmentCategory.video => Icons.videocam_outlined,
    AttachmentCategory.other => Icons.insert_drive_file_outlined,
  };
}

/// The rejected-request explanation panel — reason, a suggested next step,
/// and Apply Again. FRONTEND SIMULATION ONLY: the reason/guidance text is
/// plain seeded/admin-entered data (see RequestsService's demo seed and
/// RequestDetailScreen._reject), never generated or inferred here.
class _RejectedApplicationCard extends StatelessWidget {
  final String reason;
  final String guidance;
  final VoidCallback onApplyAgain;

  const _RejectedApplicationCard({required this.reason, required this.guidance, required this.onApplyAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: AppColors.rose500.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, size: 18, color: AppColors.rose700),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Application Rejected',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.rose700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: SoftColors.ink, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'What you can do:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SoftColors.ink),
          ),
          const SizedBox(height: 3),
          Text(guidance, style: AppTypography.bodySmallRegular.copyWith(color: SoftColors.muted, height: 1.4)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Apply Again', fullWidth: true, onPressed: onApplyAgain),
        ],
      ),
    );
  }
}

/// Distinct from [_RejectedApplicationCard] — the request is still active,
/// not terminal. Wraps one [_FlaggedRequirementCard] per still-unresolved
/// [FlaggedRequirement] (supports more than one at once — see
/// RequestsService.flagAdditionalDocuments's own doc comment), a header
/// showing how many still need correction, and the explicit "Resubmit
/// Application" action — disabled until every one of them is replaced.
/// Replacing a document never resubmits by itself (see
/// RequestsService.replaceFlaggedRequirement); only this button does.
class _CorrectionsSection extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;
  final bool busy;
  final GlobalKey Function(String flaggedId) keyFor;
  final void Function(String flaggedId, Attachment newAttachment) onReplace;
  final VoidCallback onResubmit;

  /// Demo-only — flags one more (still-unflagged) requirement without
  /// leaving this screen, so a presenter can build up the "multiple flagged
  /// documents" scenario. Null once every uploadable requirement is already
  /// flagged.
  final VoidCallback? onFlagAnother;

  const _CorrectionsSection({
    required this.request,
    required this.accent,
    required this.busy,
    required this.keyFor,
    required this.onReplace,
    required this.onResubmit,
    required this.onFlagAnother,
  });

  @override
  Widget build(BuildContext context) {
    final unresolved = request.flaggedRequirements.where((f) => !f.isResolved).toList();
    final allResolved = unresolved.isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.orange700),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Application Needs Correction',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unresolved.length > 1
                ? '${unresolved.length} documents require correction.'
                : allResolved
                    ? 'All flagged documents have been replaced — you may now resubmit.'
                    : '1 document requires correction.',
            style: AppTypography.captionSmallRegular.copyWith(color: SoftColors.muted, height: 1.4),
          ),
          for (final flagged in request.flaggedRequirements.where((f) => !f.isResolved).toList())
            Padding(
              key: keyFor(flagged.id),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _FlaggedRequirementCard(
                flagged: flagged,
                currentAttachment: _attachmentFor(request, flagged.requirementLabel),
                accent: accent,
                busy: busy,
                serviceName: request.typeName,
                category: request.category,
                onReplace: (a) => onReplace(flagged.id, a),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Resubmit Application',
            icon: Icons.send_rounded,
            fullWidth: true,
            loading: busy,
            onPressed: allResolved && !busy ? onResubmit : null,
          ),
          if (onFlagAnother != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy ? null : onFlagAnother,
              style: TextButton.styleFrom(foregroundColor: AppColors.orange700),
              child: const Text(
                'Flag Another Document (Demo)',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Attachment? _attachmentFor(ServiceRequest request, String requirementLabel) {
  for (final a in request.attachments) {
    if (a.documentTypeLabel == requirementLabel) return a;
  }
  return null;
}

/// One flagged requirement's own reason + [RequirementUploader] — the
/// resident replaces exactly this document (never the whole application,
/// and never any other requirement on the same request). Wired to
/// [MasterFileService] the same way the original submission-time requirement
/// uploaders are, so "Use Existing Document" works here too.
class _FlaggedRequirementCard extends StatelessWidget {
  final FlaggedRequirement flagged;
  final Attachment? currentAttachment;
  final Color accent;
  final bool busy;
  final String serviceName;
  final ServiceCategory category;
  final ValueChanged<Attachment> onReplace;

  const _FlaggedRequirementCard({
    required this.flagged,
    required this.currentAttachment,
    required this.accent,
    required this.busy,
    required this.serviceName,
    required this.category,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = RequirementInfo(
      label: flagged.requirementLabel,
      documentType: documentTypeFor(flagged.requirementLabel),
      isRequired: true,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flagged.requirementLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SoftColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${flagged.reason}',
            style: const TextStyle(fontSize: 12, color: SoftColors.muted, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Opacity(
            opacity: busy ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: busy,
              child: Consumer<MasterFileService>(
                builder: (context, masterFile, _) {
                  final accountId = context.read<CitizenSessionService>().account?.id;
                  final existing = accountId != null ? masterFile.findByType(accountId, requirement.documentType) : null;
                  return RequirementUploader(
                    requirement: requirement,
                    attachment: currentAttachment,
                    accent: accent,
                    existingMasterDoc: existing,
                    onAttachNew: (a) {
                      onReplace(a);
                      if (accountId != null) {
                        masterFile.saveOrUpdate(
                          accountId: accountId,
                          documentType: requirement.documentType,
                          label: requirement.label,
                          attachment: a,
                          origin: category == ServiceCategory.dokyu ? 'Dokyu' : 'Tulong',
                          serviceName: serviceName,
                        );
                      }
                    },
                    onUseExisting: () {
                      if (existing != null) {
                        onReplace(attachmentForReuse(existing.attachment, requirementLabel: requirement.label));
                      }
                    },
                    onRemove: () {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The other flavor of Under Review — "Needs Manual Verification" (see
/// RequestsService.flagManualVerification). No specific requirement is
/// flagged and there's nothing for the citizen to upload or correct, so
/// unlike [_AdditionalDocumentsCard] this never embeds a
/// [RequirementUploader] — just the plain-language explanation. Never
/// styled or worded like a rejection.
class _ManualVerificationCard extends StatelessWidget {
  final String reason;
  const _ManualVerificationCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 18, color: AppColors.orange700),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Under Review',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: SoftColors.ink, height: 1.45)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The request requires additional verification. This is still an active request, not a rejection — no '
            'action is needed from you at this time.',
            style: AppTypography.captionSmallRegular.copyWith(color: SoftColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Clearly demonstration-only controls for manually driving the frontend
/// milestone simulation — deliberately styled to read as "not a normal
/// resident action" (dashed amber border, a "DEMO" tag) so a citizen using
/// the real app would never mistake this for something they control. See
/// Phase 5 docs: a real deployment's status changes come from the Web
/// Admin/backend, never a button in the citizen's own app.
class _DemoControlsCard extends StatelessWidget {
  final String? nextMilestone;
  final bool busy;
  final VoidCallback onAdvance;
  final VoidCallback onReject;

  /// Null when this request's catalog item has no genuinely-uploadable
  /// requirement to flag (none currently lack one) — omits the button
  /// entirely rather than showing it disabled.
  final VoidCallback? onFlagDocs;

  const _DemoControlsCard({
    required this.nextMilestone,
    required this.busy,
    required this.onAdvance,
    required this.onReject,
    required this.onFlagDocs,
  });

  @override
  Widget build(BuildContext context) {
    final next = nextMilestone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber500.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: AppColors.amber700),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'DEMONSTRATION CONTROLS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber700, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            next == null
                ? 'For client demonstrations only — not a real resident control.'
                : 'For client demonstrations only — not a real resident control. Next: $next',
            style: AppTypography.captionSmallRegular.copyWith(color: SoftColors.muted, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Next Demo Step',
            icon: Icons.skip_next_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            loading: busy,
            onPressed: busy ? null : onAdvance,
          ),
          if (onFlagDocs != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy ? null : onFlagDocs,
              style: TextButton.styleFrom(foregroundColor: AppColors.orange700),
              child: const Text(
                'Request Additional Documents (Demo)',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: busy ? null : onReject,
            style: TextButton.styleFrom(foregroundColor: AppColors.rose600),
            child: const Text('Reject Request (Demo)', style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final dynamic entry;
  final bool isLast;
  final Color accent;
  const _TimelineRow({required this.entry, required this.isLast, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.slate100)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.status as String, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.actor} · ${_fmt(entry.at as DateTime)}',
                      style: const TextStyle(fontSize: 11, color: SoftColors.muted),
                    ),
                    if (entry.remarks != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.remarks as String,
                        style: const TextStyle(fontSize: 12, color: SoftColors.muted, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _SoftNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color background;
  final Color foreground;

  const _SoftNotice({
    required this.icon,
    required this.title,
    required this.body,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: SoftType.name.copyWith(color: foreground))),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: SoftType.body.copyWith(color: SoftColors.ink, height: 1.4)),
        ],
      ),
    );
  }
}
