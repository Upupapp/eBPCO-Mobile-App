import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../applications/application_detail_screen.dart';
import '../business/register_business_screen.dart';

/// The one generic, catalog-driven wizard for every permit type — mirrors
/// `application-wizard.page.ts`: 4 steps (Business & Type → Details →
/// Documents → Review & Submit), a real Draft created after Step 1 and
/// kept current with `PATCH /applications/{id}` as the citizen moves
/// forward, finished with `POST /applications/{id}/submit`.
class ApplicationWizardScreen extends StatefulWidget {
  /// Set when starting fresh from the catalog.
  final String? permitType;
  /// Set when resuming a Draft from Application Detail's "Continue".
  final String? draftId;

  const ApplicationWizardScreen({super.key, this.permitType, this.draftId})
      : assert(permitType != null || draftId != null, 'Provide either permitType (new) or draftId (resume).');

  @override
  State<ApplicationWizardScreen> createState() => _ApplicationWizardScreenState();
}

class _ApplicationWizardScreenState extends State<ApplicationWizardScreen> {
  final _api = CitizenApi.instance;

  int _step = 1;
  bool _busy = false;
  String? _error;

  String? _draftId;
  late String _permitType;
  String _applicationAction = 'New';
  String? _businessId;
  final _priorPermitClaim = TextEditingController();

  final _projectAddress = TextEditingController();
  final _scopeOfWork = TextEditingController();
  final _professionalName = TextEditingController();
  final _prcNumber = TextEditingController();

  List<RequirementDoc> _requirements = [];
  final Map<String, String> _attachedDocIds = {}; // requirementCode -> documentId
  final Map<String, String> _attachedFileNames = {};
  String? _uploadingCode;

  bool get _isResuming => widget.draftId != null;

  @override
  void initState() {
    super.initState();
    _permitType = widget.permitType ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BusinessesService>().refresh());
    if (_isResuming) {
      _draftId = widget.draftId;
      _loadDraft();
    }
  }

  @override
  void dispose() {
    for (final c in [_priorPermitClaim, _projectAddress, _scopeOfWork, _professionalName, _prcNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDraft() async {
    setState(() => _busy = true);
    try {
      final app = await _api.getApplication(_draftId!);
      _permitType = app.permitType;
      _applicationAction = app.applicationAction;
      _businessId = app.businessId;
      _priorPermitClaim.text = app.priorPermitClaim ?? '';
      _projectAddress.text = app.location ?? '';
      _scopeOfWork.text = app.form['scopeOfWork'] as String? ?? '';
      _professionalName.text = app.form['professionalName'] as String? ?? '';
      _prcNumber.text = app.form['prcNumber'] as String? ?? '';
      await _loadRequirements();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadRequirements() async {
    if (_draftId != null) {
      final reqs = await _api.applicationRequirements(_draftId!);
      for (final r in reqs) {
        if (r.documentIds.isNotEmpty) _attachedDocIds[r.code] = r.documentIds.first;
      }
      if (!mounted) return;
      setState(() => _requirements = reqs);
    } else {
      final reqs = await _api.requirementsForPermitType(_permitType);
      if (!mounted) return;
      setState(() => _requirements = reqs);
    }
  }

  bool get _needsPriorPermitClaim => _applicationAction != 'New';

  Future<void> _toStep2() async {
    if (_needsPriorPermitClaim && _priorPermitClaim.text.trim().isEmpty) {
      setState(() => _error = 'Enter the permit number this application renews/amends.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_draftId == null) {
        final created = await _api.submit(
          permitType: _permitType,
          applicationAction: _applicationAction,
          businessId: _businessId,
          priorPermitClaim: _needsPriorPermitClaim ? _priorPermitClaim.text.trim() : null,
          saveAsDraft: true,
        );
        _draftId = created.id;
      } else {
        await _api.updateDraft(_draftId!, {
          'applicationAction': _applicationAction,
          'businessId': _businessId,
          'priorPermitClaim': _needsPriorPermitClaim ? _priorPermitClaim.text.trim() : null,
        });
      }
      await _loadRequirements();
      if (!mounted) return;
      setState(() => _step = 2);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toStep3() async {
    if (_projectAddress.text.trim().isEmpty || _scopeOfWork.text.trim().isEmpty) {
      setState(() => _error = 'Enter the project address and scope of work.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.updateDraft(_draftId!, {
        'location': _projectAddress.text.trim(),
        'form': {
          'scopeOfWork': _scopeOfWork.text.trim(),
          'professionalName': _professionalName.text.trim().isEmpty ? null : _professionalName.text.trim(),
          'prcNumber': _prcNumber.text.trim().isEmpty ? null : _prcNumber.text.trim(),
        },
      });
      if (!mounted) return;
      setState(() => _step = 3);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUpload(RequirementDoc doc) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final picked = result?.files.single;
    if (picked == null) return;

    setState(() => _uploadingCode = doc.code);
    try {
      final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) throw const ApiError(0, null, true);
      final documentId = await _api.uploadDocument(
        fileName: picked.name,
        label: doc.label,
        contentBase64: base64Encode(bytes),
        applicationId: _draftId,
        requirementCode: doc.code,
      );
      if (!mounted) return;
      setState(() {
        _attachedDocIds[doc.code] = documentId;
        _attachedFileNames[doc.code] = picked.name;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _uploadingCode = null);
    }
  }

  bool get _requiredDocumentsComplete =>
      _requirements.where((r) => r.required).every((r) => _attachedDocIds.containsKey(r.code));

  Future<void> _toStep4() async {
    if (!_requiredDocumentsComplete) {
      setState(() => _error = 'Attach every required document before continuing.');
      return;
    }
    // Documents already carry applicationId/requirementCode from the upload
    // in Step 3 — no separate "attach" patch is needed for them, so this
    // step is just a client-side move, nothing to await.
    setState(() {
      _error = null;
      _step = 4;
    });
  }

  Future<void> _saveAndExit() async {
    if (!mounted) return;
    context.read<ApplicationsService>().refresh();
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.submitDraft(_draftId!);
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: _draftId!)));
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_permitType.isEmpty ? 'New Application' : _permitType),
        actions: [
          if (_draftId != null && _step < 4)
            TextButton(
              onPressed: _busy ? null : _saveAndExit,
              child: const Text('Save & Exit'),
            ),
        ],
      ),
      body: SafeArea(
        child: _busy && _requirements.isEmpty && _step == 1 && _isResuming
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _StepIndicator(step: _step),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step == 1) _step1(),
                          if (_step == 2) _step2(),
                          if (_step == 3) _step3(),
                          if (_step == 4) _step4(),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(_error!, style: AppTypography.error),
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

  Widget _step1() {
    final businesses = context.watch<BusinessesService>();
    final active = businesses.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Permit Type', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        SoftCard(padding: const EdgeInsets.all(AppSpacing.md), child: Text(_permitType, style: AppTypography.bodyMedium)),
        const SizedBox(height: AppSpacing.lg),
        Text('Business', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        if (active.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businesses.loading ? 'Loading your businesses…' : 'No active businesses.',
                style: AppTypography.hint,
              ),
              if (!businesses.loading) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()))
                      .then((_) => context.read<BusinessesService>().refresh()),
                  child: const Text('Register one first'),
                ),
              ],
            ],
          )
        else
          DropdownButtonFormField<String>(
            initialValue: active.any((b) => b.id == _businessId) ? _businessId : null,
            hint: const Text('Select a business'),
            isExpanded: true,
            items: active.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
            onChanged: (v) => setState(() => _businessId = v),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Application Type', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _applicationAction,
          items: const ['New', 'Renewal', 'Amendment'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _applicationAction = v ?? _applicationAction),
        ),
        if (_needsPriorPermitClaim) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Existing Permit Number', style: AppTypography.fieldLabel),
          const SizedBox(height: 6),
          TextField(controller: _priorPermitClaim, decoration: const InputDecoration(hintText: 'e.g. BP-2020-000042, as printed on the permit')),
          const SizedBox(height: 6),
          Text('The office confirms this from the permit itself — self-reported here.', style: AppTypography.hint),
        ],
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _busy ? null : _toStep2,
          child: _busy ? const _Spinner() : const Text('Continue'),
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Project / Business Address', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        TextField(controller: _projectAddress, decoration: const InputDecoration(hintText: 'Street, Barangay, City')),
        const SizedBox(height: AppSpacing.lg),
        Text('Scope of Work / Purpose', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        TextField(controller: _scopeOfWork, maxLines: 3, decoration: const InputDecoration(hintText: 'Briefly describe the work or purpose')),
        const SizedBox(height: AppSpacing.lg),
        Text('Professional in Charge (optional)', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        TextField(controller: _professionalName, decoration: const InputDecoration(hintText: 'Engineer / Architect name')),
        const SizedBox(height: AppSpacing.lg),
        Text('PRC License No. (optional)', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        TextField(controller: _prcNumber),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: ElevatedButton(onPressed: _busy ? null : _toStep3, child: _busy ? const _Spinner() : const Text('Continue'))),
          ],
        ),
      ],
    );
  }

  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Accepted formats: PDF, JPG, JPEG, PNG.', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.md),
        ..._requirements.map((doc) {
          final attached = _attachedDocIds[doc.code];
          final uploading = _uploadingCode == doc.code;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: doc.required ? AppColors.danger100 : AppColors.gray100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          doc.required ? 'Required' : 'Optional',
                          style: AppTypography.caption.copyWith(color: doc.required ? AppColors.dangerText : AppColors.gray600, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(doc.label, style: AppTypography.bodyMedium)),
                    ],
                  ),
                  if (doc.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(doc.description, style: AppTypography.caption),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (uploading)
                    const _Spinner()
                  else if (attached != null)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_attachedFileNames[doc.code] ?? 'Attached', style: AppTypography.caption)),
                        TextButton(onPressed: () => _pickAndUpload(doc), child: const Text('Replace')),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => _pickAndUpload(doc),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Attach File'),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 2), child: const Text('Back'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: ElevatedButton(onPressed: _busy ? null : _toStep4, child: _busy ? const _Spinner() : const Text('Continue'))),
          ],
        ),
      ],
    );
  }

  Widget _step4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_permitType, style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(_applicationAction, style: AppTypography.body),
              const Divider(height: AppSpacing.xxl),
              Text('Address', style: AppTypography.caption),
              Text(_projectAddress.text, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Scope of Work', style: AppTypography.caption),
              Text(_scopeOfWork.text, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Documents attached', style: AppTypography.caption),
              Text('${_attachedDocIds.length} of ${_requirements.length}', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Submitting moves this out of Draft and sends it for review. You can also save it as a draft and finish it later.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 3), child: const Text('Back'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: ElevatedButton(onPressed: _busy ? null : _submit, child: _busy ? const _Spinner() : const Text('Submit Application'))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: _busy ? null : _saveAndExit, child: const Text('Save as Draft & Exit')),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Type', 'Details', 'Documents', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
      child: Row(
        children: List.generate(4, (i) {
          final n = i + 1;
          final active = n == step;
          final done = n < step;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0) Expanded(child: Container(height: 2, color: done || active ? AppColors.primary500 : AppColors.gray200)),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: done || active ? AppColors.primary500 : AppColors.gray200,
                      child: done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text('$n', style: AppTypography.caption.copyWith(color: active ? Colors.white : AppColors.gray500, fontSize: 11)),
                    ),
                    if (i < 3) Expanded(child: Container(height: 2, color: done ? AppColors.primary500 : AppColors.gray200)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: AppTypography.caption.copyWith(fontSize: 10)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
