import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../domain/upload_file.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../services/upload_limits.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/document_library_sheet.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../applications/application_detail_screen.dart';
import '../business/register_business_screen.dart';
import '../profile/legal_screen.dart';

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
    : assert(
        permitType != null || draftId != null,
        'Provide either permitType (new) or draftId (resume).',
      );

  @override
  State<ApplicationWizardScreen> createState() =>
      _ApplicationWizardScreenState();
}

class _ApplicationWizardScreenState extends State<ApplicationWizardScreen> {
  final _api = CitizenApi.instance;

  int _step = 1;
  final _scroll = ScrollController();

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }
  bool _busy = false;
  String? _error;

  String? _draftId;
  late String _permitType;
  String _applicationAction = 'New';
  String? _businessId;

  /// The permit a Renewal/Amendment is about. Checked against eBPCO's own
  /// issued permits (`renewsPermitNumber`) unless [_paperPermit] — then sent
  /// as the unverified `priorPermitClaim`, which the office judges from the
  /// copy the citizen uploads in the Documents step.
  final _permitNumber = TextEditingController();
  bool _paperPermit = false;

  /// Shown under the permit number field: the server's own reason a number
  /// was refused, or a missing-number prompt.
  String? _permitNumberError;

  /// The permit the last successful check matched — shown back as a
  /// confirmation, and reused so Save & Exit never saves an unchecked number.
  RenewalCheck? _verifiedPermit;

  static const _paperProofCode = 'prior-permit-proof';

  final _projectAddress = TextEditingController();
  final _scopeOfWork = TextEditingController();
  final _professionalName = TextEditingController();
  final _prcNumber = TextEditingController();

  List<RequirementDoc> _requirements = [];
  final Map<String, String> _attachedDocIds =
      {}; // requirementCode -> documentId
  final Map<String, String> _attachedFileNames = {};

  /// Document ids already linked to the draft on the server. Uploads go up
  /// unattached and are linked on the next save — like the portal — so a
  /// file replaced before saving is simply never attached, instead of
  /// sitting on the application beside its replacement.
  final Set<String> _attachedToServer = {};
  String? _uploadingCode;

  /// Files already on record that can be reused (the portal's "or reuse").
  /// Empty until loaded, or if loading fails — the control just stays hidden.
  List<DocumentEntry> _library = [];

  bool get _isResuming => widget.draftId != null;

  late final ApplicationsService _applications;

  @override
  void initState() {
    super.initState();
    _applications = context.read<ApplicationsService>();
    _permitType = widget.permitType ?? '';
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BusinessesService>().refresh(),
    );
    _loadLibrary();
    if (_isResuming) {
      _draftId = widget.draftId;
      _loadDraft();
    }
  }

  @override
  void dispose() {
    // Step 1 already created the Draft on the server; leaving with Back must
    // not leave My Applications without it until the next pull-to-refresh.
    // After this frame, not during teardown, since refresh notifies at once.
    if (_draftId != null) Future.microtask(_applications.refresh);
    _scroll.dispose();
    for (final c in [
      _permitNumber,
      _projectAddress,
      _scopeOfWork,
      _professionalName,
      _prcNumber,
    ]) {
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
      _paperPermit = app.renewsPermitNumber == null && app.priorPermitClaim != null;
      _permitNumber.text = app.renewsPermitNumber ?? app.priorPermitClaim ?? '';
      if (app.renewsPermitNumber != null) {
        // Already accepted by the server when the draft was saved.
        _verifiedPermit = RenewalCheck(valid: true, permitNumber: app.renewsPermitNumber);
      }
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
        if (r.documentIds.isNotEmpty) {
          _attachedDocIds[r.code] = r.documentIds.last;
          _attachedToServer.addAll(r.documentIds);
        }
      }
      try {
        for (final d in await _api.listApplicationDocuments(_draftId!)) {
          if (d.requirementCode != null && _attachedDocIds[d.requirementCode] == d.id) {
            _attachedFileNames[d.requirementCode!] = d.fileName;
          }
        }
      } on ApiError {
        // Names are a nicety; "Attached" still shows without them.
      }
      if (!mounted) return;
      setState(() => _requirements = reqs);
    } else {
      final reqs = await _api.requirementsForPermitType(_permitType);
      if (!mounted) return;
      setState(() => _requirements = reqs);
    }
  }

  bool get _needsPermitReference => _applicationAction != 'New';

  String get _typedPermitNumber => _permitNumber.text.trim().toUpperCase();

  /// Which of the two reference fields to send, and with what. On a draft
  /// save an unchecked number is left out rather than saved, since the
  /// server refuses one that doesn't match — the draft may name none yet.
  Map<String, String?> _referenceFields() {
    if (!_needsPermitReference) return {'renewsPermitNumber': null, 'priorPermitClaim': null};
    final typed = _permitNumber.text.trim();
    if (_paperPermit) {
      return {'renewsPermitNumber': null, 'priorPermitClaim': typed.isEmpty ? null : typed};
    }
    final checked = _verifiedPermit?.permitNumber;
    return {
      'renewsPermitNumber': checked != null && checked == _typedPermitNumber ? checked : null,
      'priorPermitClaim': null,
    };
  }

  /// Anything that changes what the number must match makes the last check stale.
  void _invalidatePermitCheck() {
    _permitNumberError = null;
    _verifiedPermit = null;
  }

  Future<void> _toStep2() async {
    if (_businessId == null) {
      setState(() => _error = 'Please select a business.');
      return;
    }
    final chosen = context.read<BusinessesService>().businesses.where(
      (b) => b.id == _businessId,
    );
    if (chosen.isNotEmpty && !chosen.first.isActive) {
      setState(
        () => _error = 'This business is inactive. Reactivate it before applying for a permit.',
      );
      return;
    }
    if (_needsPermitReference && _permitNumber.text.trim().isEmpty) {
      setState(
        () => _permitNumberError =
            'Please enter the permit number being ${_applicationAction == 'Renewal' ? 'renewed' : 'amended'}.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _permitNumberError = null;
    });
    try {
      if (_needsPermitReference && !_paperPermit) {
        final check = await _api.renewalCheck(
          permitNumber: _typedPermitNumber,
          permitType: _permitType,
          businessId: _businessId,
        );
        if (!mounted) return;
        if (!check.valid) {
          setState(() {
            _verifiedPermit = null;
            _permitNumberError = check.message ?? 'That permit number could not be matched.';
          });
          return;
        }
        setState(() => _verifiedPermit = check);
      }
      final refs = _referenceFields();
      if (_draftId == null) {
        final created = await _api.submit(
          permitType: _permitType,
          applicationAction: _applicationAction,
          businessId: _businessId,
          renewsPermitNumber: refs['renewsPermitNumber'],
          priorPermitClaim: refs['priorPermitClaim'],
          saveAsDraft: true,
        );
        _draftId = created.id;
      } else {
        await _api.updateDraft(_draftId!, {
          'applicationAction': _applicationAction,
          'businessId': _businessId,
          ...refs,
        });
      }
      await _loadRequirements();
      if (!mounted) return;
      _goTo(2);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toStep3() async {
    if (_projectAddress.text.trim().isEmpty ||
        _scopeOfWork.text.trim().isEmpty) {
      setState(
        () => _error = 'Please complete the project address and scope of work.',
      );
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
          'professionalName': _professionalName.text.trim().isEmpty
              ? null
              : _professionalName.text.trim(),
          'prcNumber': _prcNumber.text.trim().isEmpty
              ? null
              : _prcNumber.text.trim(),
        },
      });
      if (!mounted) return;
      _goTo(3);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadLibrary() async {
    try {
      final docs = await _api.getMyDocuments();
      if (mounted) setState(() => _library = reusableDocuments(docs));
    } catch (_) {
      // Same as the portal: without the list, reuse is simply not offered.
    }
  }

  Future<void> _pickAndUpload(RequirementDoc doc) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null) return;
    await _upload(doc, picked.name, () async {
      final bytes =
          picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);
      if (bytes == null) throw const UploadRefused(unreadableFile);
      return readyForUpload(picked.name, bytes);
    });
  }

  /// The portal's `reuseExisting`. There is no attach-by-reference route —
  /// `POST /documents` always stores fresh bytes — so the chosen file's
  /// content is fetched through its signed link and uploaded again against
  /// this requirement, exactly like a new pick.
  Future<void> _reuseFromLibrary(RequirementDoc doc) async {
    final chosen = await showDocumentLibrarySheet(
      context,
      documents: _library,
      forLabel: doc.label,
      requirementCode: doc.code,
    );
    if (chosen == null || !mounted) return;
    await _upload(
      doc,
      chosen.fileName,
      () async {
        final url = await _api.getDocumentContent(chosen.id);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
        // Already accepted by the server once, exactly as it is.
        return (bytes: response.bodyBytes, fileName: chosen.fileName);
      },
      failure: 'Could not reuse "${chosen.fileName}". Try again, or upload a new file.',
      reuseOf: chosen.id,
    );
  }

  Future<void> _replace(RequirementDoc doc) async {
    if (_library.isEmpty) return _pickAndUpload(doc);
    final source = await showAttachSourceSheet(context, forLabel: doc.label);
    if (!mounted) return;
    switch (source) {
      case AttachSource.device:
        await _pickAndUpload(doc);
      case AttachSource.library:
        await _reuseFromLibrary(doc);
      case null:
        break;
    }
  }

  Future<void> _upload(
    RequirementDoc doc,
    String fileName,
    Future<ReadyUpload> Function() ready, {
    String failure = 'Could not upload that file. Please try again.',
    String? reuseOf,
  }) async {
    setState(() => _uploadingCode = doc.code);
    try {
      final file = await ready();
      final upload = await _api.uploadOrReuse(
        fileName: file.fileName,
        label: doc.label,
        contentBase64: base64Encode(file.bytes),
        requirementCode: doc.code,
        reuseOf: reuseOf,
      );
      final documentId = upload.documentId;
      if (upload.reused != null) {
        _say('You already had "${upload.reused!.fileName}" in My Documents, so that copy was used. '
            'Next time, choose it from your documents instead of the device.');
      }
      if (!mounted) return;
      setState(() {
        _attachedDocIds[doc.code] = documentId;
        _attachedFileNames[doc.code] = file.fileName;
        // A "(N missing)" count from before this upload is now wrong.
        _error = null;
      });
      // What was just uploaded can be reused for the next requirement.
      unawaited(_loadLibrary());
    } on UploadRefused catch (e) {
      _say(e.message);
    } on ApiError catch (e) {
      _say(e.citizenMessage);
    } catch (_) {
      _say(failure);
    } finally {
      if (mounted) setState(() => _uploadingCode = null);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  /// The paper-permit proof only applies on the paper path, where it is
  /// required (the server refuses to file the claim without it); on the
  /// checked-number path there is nothing for it to prove, so it is hidden.
  List<RequirementDoc> get _visibleRequirements => _requirements
      .where((r) => r.code != _paperProofCode || (_needsPermitReference && _paperPermit))
      .toList();

  bool _isRequired(RequirementDoc doc) => doc.required || doc.code == _paperProofCode;

  bool get _requiredDocumentsComplete => _visibleRequirements
      .where(_isRequired)
      .every((r) => _attachedDocIds.containsKey(r.code));

  /// Links this wizard's new uploads to the draft (`PATCH` with
  /// `documentIds`), skipping any already linked.
  Future<void> _attachPending() async {
    if (_draftId == null) return;
    final pending = _attachedDocIds.values.where((id) => !_attachedToServer.contains(id)).toList();
    if (pending.isEmpty) return;
    await _api.updateDraft(_draftId!, {'documentIds': pending});
    _attachedToServer.addAll(pending);
  }

  Future<void> _toStep4() async {
    if (!_requiredDocumentsComplete) {
      final missing = _visibleRequirements
          .where((r) => _isRequired(r) && !_attachedDocIds.containsKey(r.code))
          .length;
      setState(
        () =>
            _error = 'Please attach all required documents ($missing missing).',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _attachPending();
      if (!mounted) return;
      _goTo(4);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Like the portal's Save & Exit: saves what is on screen now, not only
  /// what was saved the last time Continue was pressed.
  Future<void> _saveAndExit() async {
    if (_draftId != null) {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        if (_step == 1) {
          await _api.updateDraft(_draftId!, {
            'applicationAction': _applicationAction,
            'businessId': _businessId,
            ..._referenceFields(),
          });
        } else if (_step == 2) {
          await _api.updateDraft(_draftId!, {
            if (_projectAddress.text.trim().isNotEmpty)
              'location': _projectAddress.text.trim(),
            'form': {
              'scopeOfWork': _scopeOfWork.text.trim().isEmpty
                  ? null
                  : _scopeOfWork.text.trim(),
              'professionalName': _professionalName.text.trim().isEmpty
                  ? null
                  : _professionalName.text.trim(),
              'prcNumber': _prcNumber.text.trim().isEmpty
                  ? null
                  : _prcNumber.text.trim(),
            },
          });
        } else {
          await _attachPending();
        }
      } on ApiError catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.citizenMessage;
          _busy = false;
        });
        return;
      }
    }
    if (!mounted) return;
    context.read<ApplicationsService>().refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Draft saved. Continue it any time from My Applications.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  bool _understandRequirements = false;
  bool _agreeTerms = false;

  Future<void> _submit() async {
    if (!_understandRequirements || !_agreeTerms) {
      setState(() => _error = 'Please check both declarations to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _attachPending();
      await _api.submitDraft(_draftId!);
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted to the Municipality.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(applicationId: _draftId!),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: _permitType.isEmpty ? 'New Application' : _permitType,
      actions: [
        if (_draftId != null && _step < 4)
          TextButton(
            onPressed: _busy ? null : _saveAndExit,
            child: Text(
              'Save & Exit',
              style: SoftType.sectionLink.copyWith(fontSize: 14),
            ),
          ),
      ],
      body: _busy && _requirements.isEmpty && _step == 1 && _isResuming
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(step: _step),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_step == 1) _step1(),
                        if (_step == 2) _step2(),
                        if (_step == 3) _step3(),
                        if (_step == 4) _step4(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: SoftType.fieldLabel.copyWith(fontSize: 14)),
  );

  /// Errors sit right above the buttons that raised them, not below.
  Widget _errorLine() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: AppTypography.error),
        );

  Widget _navRow({
    required VoidCallback onBack,
    required String nextLabel,
    required VoidCallback onNext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _errorLine(),
        Row(
          children: [
            Expanded(
              child: SoftPillButton(
                label: 'Back',
                kind: SoftPillKind.outline,
                onPressed: _busy ? null : onBack,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SoftPillButton(
                label: nextLabel,
                busy: _busy,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _step1() {
    final businesses = context.watch<BusinessesService>();
    final active = businesses.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Business & type', style: SoftType.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 18),
        _label('Permit Type'),
        SoftCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SoftIconTile(icon: Icons.description_outlined, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _permitType,
                  style: SoftType.tileTitle.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label('Business'),
        if (active.isEmpty && businesses.error != null && !businesses.loading)
          SoftCard(
            color: SoftColors.pendingCream,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businesses.error!,
                  style: SoftType.body.copyWith(color: SoftColors.pendingInk),
                ),
                const SizedBox(height: 10),
                SoftPillButton(
                  label: 'Try again',
                  kind: SoftPillKind.outline,
                  icon: Icons.refresh_rounded,
                  onPressed: () => context.read<BusinessesService>().refresh(),
                ),
              ],
            ),
          )
        else if (active.isEmpty)
          SoftCard(
            color: SoftColors.primaryWash,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businesses.loading
                      ? 'Loading your businesses…'
                      : 'No active businesses.',
                  style: SoftType.body.copyWith(color: SoftColors.ink),
                ),
                if (!businesses.loading) ...[
                  const SizedBox(height: 10),
                  SoftPillButton(
                    label: 'Register one first',
                    kind: SoftPillKind.outline,
                    icon: Icons.add_rounded,
                    onPressed: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterBusinessScreen(),
                          ),
                        )
                        .then((_) {
                          if (mounted) {
                            context.read<BusinessesService>().refresh();
                          }
                        }),
                  ),
                ],
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: active.any((b) => b.id == _businessId)
                ? _businessId
                : null,
            hint: const Text('Select a business'),
            isExpanded: true,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            items: active
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _businessId = v;
              _error = null;
              _invalidatePermitCheck();
            }),
          ),
        const SizedBox(height: 18),
        _label('Application Type'),
        Row(
          children: [
            for (final (i, v) in const [
              'New',
              'Renewal',
              'Amendment',
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: SoftFilterChip(
                    label: v,
                    selected: _applicationAction == v,
                    onTap: () => setState(() {
                      _applicationAction = v;
                      _invalidatePermitCheck();
                    }),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_needsPermitReference) ...[
          const SizedBox(height: 18),
          _label(_paperPermit ? 'Paper Permit Number' : 'Existing Permit Number'),
          TextField(
            controller: _permitNumber,
            style: SoftType.field,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_permitNumberError != null || _verifiedPermit != null) {
                setState(_invalidatePermitCheck);
              }
            },
            decoration: InputDecoration(
              hintText: 'e.g. BP-2025-000042, as printed on the permit',
              errorText: _permitNumberError,
              errorMaxLines: 5,
            ),
          ),
          const SizedBox(height: 6),
          if (_verifiedPermit != null && _permitNumberError == null && !_paperPermit)
            _verifiedPermitLine(_verifiedPermit!)
          else
            Text(
              _paperPermit
                  ? 'The office checks this against the copy of the permit you upload in the Documents step.'
                  : 'Checked against permits eBPCO issued to the selected business before you can continue.',
              style: SoftType.cellLabel,
            ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _paperPermit,
            onChanged: (v) => setState(() {
              _paperPermit = v ?? false;
              _invalidatePermitCheck();
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: SoftColors.primary,
            title: Text(
              'My permit was issued on paper before eBPCO',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
            subtitle: Text(
              'It will not be found in the system. You will need to upload a copy of it.',
              style: SoftType.cellLabel,
            ),
          ),
        ],
        const SizedBox(height: 26),
        _errorLine(),
        SoftPillButton(label: 'Continue', busy: _busy, onPressed: _toStep2),
      ],
    );
  }

  Widget _verifiedPermitLine(RenewalCheck permit) {
    final issued = permit.issuedDate == null ? null : DateTime.tryParse(permit.issuedDate!);
    final parts = [
      permit.permitType,
      permit.businessName,
      if (issued != null) 'issued ${DateFormat('MMM d, y').format(issued.toLocal())}',
    ].whereType<String>().join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_rounded, size: 18, color: SoftColors.verifiedInk),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.isEmpty ? 'Permit found.' : 'Permit found: $parts',
            style: SoftType.cellLabel.copyWith(color: SoftColors.verifiedInk),
          ),
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Project details', style: SoftType.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 18),
        _label('Project / Business Address'),
        TextField(
          controller: _projectAddress,
          style: SoftType.field,
          decoration: const InputDecoration(hintText: 'Street, Barangay, City'),
        ),
        const SizedBox(height: 16),
        _label('Scope of Work / Purpose'),
        TextField(
          controller: _scopeOfWork,
          maxLines: 3,
          style: SoftType.field,
          decoration: InputDecoration(
            hintText: 'Briefly describe the work or purpose',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SoftRadius.md),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SoftRadius.md),
              borderSide: const BorderSide(color: SoftColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SoftRadius.md),
              borderSide: const BorderSide(
                color: SoftColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label('Professional in Charge (optional)'),
        TextField(
          controller: _professionalName,
          style: SoftType.field,
          decoration: const InputDecoration(
            hintText: 'Engineer / Architect name',
          ),
        ),
        const SizedBox(height: 16),
        _label('PRC License No. (optional)'),
        TextField(controller: _prcNumber, style: SoftType.field),
        const SizedBox(height: 26),
        _navRow(
          onBack: () => _goTo(1),
          nextLabel: 'Continue',
          onNext: _toStep3,
        ),
      ],
    );
  }

  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Documents', style: SoftType.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Text('Accepted formats: PDF, JPG, JPEG, PNG.', style: SoftType.body),
        const SizedBox(height: 16),
        ..._visibleRequirements.map((doc) {
          final attached = _attachedDocIds[doc.code];
          final uploading = _uploadingCode == doc.code;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoftIconTile(
                        icon: attached != null
                            ? Icons.check_rounded
                            : Icons.upload_file_rounded,
                        background: attached != null
                            ? SoftColors.verifiedSoft
                            : SoftColors.primarySoft,
                        foreground: attached != null
                            ? SoftColors.verifiedInk
                            : SoftColors.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.label, style: SoftType.tileTitle),
                            const SizedBox(height: 6),
                            SoftStatusPill(
                              label: _isRequired(doc) ? 'Required' : 'Optional',
                              tone: _isRequired(doc)
                                  ? SoftStatusTone.danger
                                  : SoftStatusTone.neutral,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (doc.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(doc.description, style: SoftType.body),
                  ],
                  const SizedBox(height: 12),
                  if (uploading)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading… a large file can take a minute on mobile data.',
                            textAlign: TextAlign.center,
                            style: SoftType.cellLabel,
                          ),
                        ],
                      ),
                    )
                  else if (attached != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _attachedFileNames[doc.code] ?? 'Attached',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SoftType.cellValue.copyWith(
                              color: SoftColors.verifiedInk,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _replace(doc),
                          child: Text(
                            'Replace',
                            style: SoftType.sectionLink.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    SoftPillButton(
                      label: 'Attach File',
                      kind: SoftPillKind.outline,
                      icon: Icons.attach_file_rounded,
                      onPressed: () => _pickAndUpload(doc),
                    ),
                    if (_library.isNotEmpty)
                      SoftPillButton(
                        label: 'Choose from My Documents',
                        kind: SoftPillKind.text,
                        icon: Icons.folder_outlined,
                        onPressed: () => _reuseFromLibrary(doc),
                      ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _navRow(
          onBack: () => _goTo(2),
          nextLabel: 'Continue',
          onNext: _toStep4,
        ),
      ],
    );
  }

  Widget _step4() {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(value, style: SoftType.cellValue),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review & submit', style: SoftType.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 18),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('Permit', _permitType),
              const Divider(height: 1, color: SoftColors.line),
              row('Application type', _applicationAction),
              const Divider(height: 1, color: SoftColors.line),
              row('Address', _projectAddress.text),
              const Divider(height: 1, color: SoftColors.line),
              row('Scope of Work', _scopeOfWork.text),
              const Divider(height: 1, color: SoftColors.line),
              row(
                'Documents attached',
                '${_visibleRequirements.where((r) => _attachedDocIds.containsKey(r.code)).length} of ${_visibleRequirements.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Submitting moves this out of Draft and sends it for review. You can also save it as a draft and finish it later.',
          style: SoftType.body,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _understandRequirements,
              onChanged: (v) =>
                  setState(() => _understandRequirements = v ?? false),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(
                  () => _understandRequirements = !_understandRequirements,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'I understand the application requirements and certify the information provided is true and correct.',
                    style: SoftType.body.copyWith(color: SoftColors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            ),
            GestureDetector(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              child: Text(
                'I agree to the ',
                style: SoftType.body.copyWith(color: SoftColors.ink),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LegalScreen())),
              child: Text(
                'Terms & Conditions',
                style: SoftType.sectionLink.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _navRow(
          onBack: () => _goTo(3),
          nextLabel: 'Submit Application',
          onNext: _submit,
        ),
        const SizedBox(height: 8),
        SoftPillButton(
          label: 'Save as Draft & Exit',
          kind: SoftPillKind.text,
          onPressed: _busy ? null : _saveAndExit,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Type', 'Details', 'Documents', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of 4 · ${labels[step - 1]}',
            style: SoftType.eyebrow,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < step ? SoftColors.primary : SoftColors.line,
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
