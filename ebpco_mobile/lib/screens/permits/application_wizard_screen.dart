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
import '../../domain/account_verification.dart';
import '../../domain/applying_as.dart';
import '../../domain/models.dart';
import '../../domain/draft_resume.dart';
import '../../domain/occupancy.dart';
import '../../domain/permit_delivery.dart';
import '../../domain/permit_forms.dart';
import '../../domain/upload_file.dart';
import '../../domain/who_may_apply.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../services/earlier_records_service.dart';
import '../../services/session_service.dart';
import '../../services/upload_limits.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/delivery_choice_form.dart';
import '../../widgets/document_library_sheet.dart';
import '../../widgets/requirement_heading.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../applications/application_detail_screen.dart';
import '../business/register_business_screen.dart';
import '../profile/account_verification_screen.dart';
import '../profile/legal_screen.dart';
import '../../widgets/blank_form_link.dart';
import '../../widgets/message_bar.dart';

/// The one generic, catalog-driven wizard for every permit type — mirrors
/// `application-wizard.page.ts`: 4 steps (Applying as & Type → Details →
/// Documents → Review & Submit), a real Draft created after Step 1 and
/// kept current with `PATCH /applications/{id}` as the citizen moves
/// forward, finished with `POST /applications/{id}/submit`.
///
/// Every application asks "Applying as" (ebpco-api 067): Residential /
/// Private Individual needs no business, only who owns the property;
/// Business picks one of the citizen's businesses. Submitting needs a
/// verified account; until then the draft is saved and the citizen is told
/// why it cannot be submitted yet. A permit type the Municipality takes from
/// one kind of applicant only (ebpco-api 068) offers only that kind.
/// Review & Submit asks how the permit is to be received (ebpco-api 070):
/// picked up at the office, or delivered by courier to an address.
class ApplicationWizardScreen extends StatefulWidget {
  /// Set when starting fresh from the catalog.
  final String? permitType;

  /// Set when resuming a Draft from Application Detail's "Continue".
  final String? draftId;

  /// A fresh start as a 'Renewal' or 'Amendment' of [permitNumber], for
  /// [businessId] when it is one of the citizen's businesses: "Renew" on a
  /// permit issued before eBPCO (ebpco-api 069). Continue still has the
  /// server check the number, exactly like a typed one. A resumed draft
  /// keeps its own.
  final String? applicationAction;
  final String? permitNumber;
  final String? businessId;

  const ApplicationWizardScreen({
    super.key,
    this.permitType,
    this.draftId,
    this.applicationAction,
    this.permitNumber,
    this.businessId,
  }) : assert(
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

  /// 'residential' or 'business'; null until chosen. Starts on what the
  /// citizen chose at sign-up, if that was one of the two.
  String? _applyingAs;

  /// Who may apply for every permit type (`GET /permit-types`); never fails,
  /// an older server reads as both.
  late final Future<Map<String, List<String>>> _kindsByType;

  /// Who may apply for this permit type: both until the server says otherwise.
  List<String> _applicantKinds = bothApplicantKinds;

  /// The draft's form as loaded. PATCH replaces the whole form, so keys this
  /// screen does not edit are sent back as they were.
  Map<String, dynamic> _savedForm = const {};

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

  /// The use or character of occupancy (ebpco-api 071): one of the National
  /// Building Code's groups, or 'other' with [_occupancyOther] typed in.
  /// Asked of a Building Permit and a Certificate of Occupancy only.
  String? _occupancyGroup;
  final _occupancyOther = TextEditingController();

  /// How many times a draft's answer was read in: the field starts again on it.
  int _occupancyLoads = 0;

  bool get _asksOccupancy => asksOccupancy(_permitType);

  /// What the use or character of occupancy still lacks, or null; always null
  /// for a type that does not ask it.
  String? get _occupancyProblem =>
      _asksOccupancy ? occupancyProblem(_occupancyGroup, _occupancyOther.text) : null;

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

  /// How the citizen will receive the permit (ebpco-api 070): Pick up by
  /// default; Delivery prefilled from their profile. Saved on the draft just
  /// before it is filed, and read back when a draft is resumed.
  late final DeliveryChoiceController _delivery;

  /// The server's wording once read; the app's own copy of it until then.
  String _feeNote = deliveryFeeNote;
  String? _deliveryProblem;

  /// What the server holds for this draft, so a pick-up never sent anywhere
  /// is not sent now.
  String _deliveryOnServer = receiveByPickup;

  late final ApplicationsService _applications;

  @override
  void initState() {
    super.initState();
    _applications = context.read<ApplicationsService>();
    _permitType = widget.permitType ?? '';
    final session = context.read<SessionService>();
    _delivery = DeliveryChoiceController(address: addressFromProfile(session.profile));
    if (!_isResuming && (widget.applicationAction == 'Renewal' || widget.applicationAction == 'Amendment')) {
      _applicationAction = widget.applicationAction!;
      _permitNumber.text = widget.permitNumber?.trim() ?? '';
      if (widget.businessId case final businessId?) {
        _businessId = businessId;
        _applyingAs = applyingAsBusiness;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businesses = context.read<BusinessesService>();
      // "Applying as" starts from what the citizen has, once their businesses
      // are known; a choice already made (or a draft's) is never overwritten.
      businesses.refresh().then((_) {
        if (!mounted || _isResuming || _applyingAs != null) return;
        final start = startingApplyingAs(listLoaded: businesses.error == null, activeBusinesses: businesses.active.length);
        if (start != null) _chooseApplyingAs(start);
      });
      // The citizen's permits issued before eBPCO, offered as quick picks
      // for a Renewal or Amendment's permit number.
      context.read<EarlierRecordsService>().refresh();
      // Whether the account may submit yet: it may have been verified since sign-in.
      session.refreshProfile().catchError((_) {});
    });
    _loadLibrary();
    _kindsByType = _api.permitTypeApplicantKinds();
    if (_isResuming) {
      _draftId = widget.draftId;
      _loadDraft();
    } else {
      _loadApplicantKinds();
    }
  }

  Future<void> _loadApplicantKinds() async {
    final kinds = applicantKindsFor(await _kindsByType, _permitType);
    if (!mounted) return;
    setState(() {
      _applicantKinds = kinds;
      if (_step == 1) _honourApplicantKinds();
    });
  }

  /// A type open to one kind only starts on that kind, whatever was chosen at
  /// sign-up or saved on the draft. True when it changed the choice.
  bool _honourApplicantKinds() {
    final only = onlyApplicantKind(_applicantKinds);
    if (only == null || _applyingAs == only) return false;
    _applyingAs = only;
    _invalidatePermitCheck();
    return true;
  }

  /// Why the chosen "Applying as" is not open for this permit type, or null.
  String? get _applicantKindClosed => _applyingAs == null
      ? null
      : applicantKindClosedMessage(permitType: _permitType, kind: _applyingAs!, kinds: _applicantKinds);

  @override
  void dispose() {
    // Step 1 already created the Draft on the server; leaving with Back must
    // not leave My Applications without it until the next pull-to-refresh.
    // After this frame, not during teardown, since refresh notifies at once.
    if (_draftId != null) Future.microtask(_applications.refresh);
    _scroll.dispose();
    _delivery.dispose();
    for (final c in [
      _permitNumber,
      _projectAddress,
      _scopeOfWork,
      _professionalName,
      _prcNumber,
      _occupancyOther,
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
      _savedForm = app.form;
      _applyingAs = savedApplyingAs(app.form, app.businessId) ?? _applyingAs;
      // A draft saved before the 2026-10-28 ruling may name another owner;
      // it just resumes, and the next save leaves that answer out.
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
      // As saved; a draft saved before it was asked (ebpco-api 071) reopens
      // with nothing chosen, on step 1.
      final occupancy = occupancyFromForm(app.form);
      _occupancyGroup = occupancy.group;
      _occupancyOther.text = occupancy.other;
      _occupancyLoads++;
      _applicantKinds = applicantKindsFor(await _kindsByType, _permitType);
      // A draft saved as a kind the type no longer takes reopens on step 1.
      final kindChanged = _honourApplicantKinds();
      await _loadRequirements();
      if (!mounted) return;
      // Reopen where the citizen stopped, by the same tests Continue applies
      // on the way forward. A business not loaded yet does not hold them back.
      final business = context.read<BusinessesService>().businesses.where((b) => b.id == _businessId);
      _goTo(resumeStep(
        applicantDone: !kindChanged &&
            _applyingAsProblem == null &&
            _occupancyProblem == null &&
            (_isResidential || business.isEmpty || business.first.isActive) &&
            (!_needsPermitReference || app.renewsPermitNumber != null || app.priorPermitClaim != null),
        detailsDone: _projectAddress.text.trim().isNotEmpty && _scopeOfWork.text.trim().isNotEmpty,
        documentsDone: _requiredDocumentsComplete,
      ));
      unawaited(_loadDelivery());
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A resumed draft's own choice of how to receive the permit, read back
  /// (`GET /applications/{id}/delivery`). Nothing is lost if it cannot be
  /// read: the choice stays Pick up, as every application was before.
  Future<void> _loadDelivery() async {
    final id = _draftId;
    if (id == null) return;
    try {
      final state = await _api.getDelivery(id);
      if (!mounted) return;
      setState(() {
        _feeNote = state.feeNote;
        _deliveryOnServer = state.receiveBy;
        if (state.deliveryChosen case final d?) _delivery.load(receiveByDelivery, addressFromDelivery(d));
      });
    } catch (_) {
      // The page stands without it.
    }
  }

  /// Saves the choice on the draft (`PUT /applications/{id}/delivery`):
  /// null when saved, or the server's reason it was not. Nothing is sent for
  /// a pick-up the server already holds — every application starts as one.
  Future<String?> _saveDeliveryChoice() async {
    final id = _draftId;
    if (id == null || (!_delivery.isDelivery && _deliveryOnServer == receiveByPickup)) return null;
    try {
      final state = await _api.setDelivery(id, _delivery.requestBody);
      _deliveryOnServer = state.receiveBy;
      _feeNote = state.feeNote;
      return null;
    } on ApiError catch (e) {
      return e.citizenMessage;
    }
  }

  /// Why the delivery address cannot be used, shown under it; null for a
  /// pick-up or a usable address.
  String? _checkDeliveryAddress() {
    final problem = _delivery.problem;
    setState(() => _deliveryProblem = problem);
    return problem;
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
      // A file picked for a row this checklist no longer has (Applying as
      // changed, so no signatory's authority) is not linked to the draft.
      _attachedDocIds.removeWhere((code, id) => !_attachedToServer.contains(id) && reqs.every((r) => r.code != code));
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
      // With Applying as: a business is also asked for the signatory's authority.
      final reqs = await _api.requirementsForPermitType(_permitType, applyingAs: _applyingAs);
      if (!mounted) return;
      setState(() => _requirements = reqs);
    }
  }

  bool get _needsPermitReference => _applicationAction != 'New';

  bool get _isResidential => _applyingAs == applyingAsResidential;

  /// The business this application is for: none on a residential one.
  String? get _effectiveBusinessId => _isResidential ? null : _businessId;

  /// What "Applying as" still lacks, or null.
  String? get _applyingAsProblem => applyingAsProblem(applyingAs: _applyingAs, businessId: _businessId);

  /// The whole form, as PATCH replaces it.
  Map<String, dynamic> _form() => applicationForm(
        previous: _savedForm,
        applyingAs: _applyingAs,
        scopeOfWork: _scopeOfWork.text,
        professionalName: _professionalName.text,
        prcNumber: _prcNumber.text,
        occupancy: _asksOccupancy ? occupancyForm(_occupancyGroup, _occupancyOther.text) : null,
      );

  void _chooseApplyingAs(String value) => setState(() {
        _applyingAs = value;
        _error = null;
        _invalidatePermitCheck();
      });

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
      // The server's own spelling of the number, which for a permit from the
      // register (ebpco-api 069) need not be upper case.
      'renewsPermitNumber': checked != null && checked.toUpperCase() == _typedPermitNumber ? checked : null,
      'priorPermitClaim': null,
    };
  }

  /// Anything that changes what the number must match makes the last check stale.
  void _invalidatePermitCheck() {
    _permitNumberError = null;
    _verifiedPermit = null;
  }

  Future<void> _toStep2() async {
    // In the order step 1 asks them, like the portal: Applying as, the use or
    // character of occupancy (the server refuses to file a Building Permit or
    // Certificate of Occupancy without it, in these same words), the business.
    if (_applicantKindClosed ??
            (_applyingAs == null ? _applyingAsProblem : null) ??
            _occupancyProblem ??
            _applyingAsProblem
        case final problem?) {
      setState(() => _error = problem);
      return;
    }
    final chosen = context.read<BusinessesService>().businesses.where(
      (b) => b.id == _businessId,
    );
    if (!_isResidential && chosen.isNotEmpty && !chosen.first.isActive) {
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
          businessId: _effectiveBusinessId,
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
          businessId: _effectiveBusinessId,
          renewsPermitNumber: refs['renewsPermitNumber'],
          priorPermitClaim: refs['priorPermitClaim'],
          form: _form(),
          saveAsDraft: true,
        );
        _draftId = created.id;
      } else {
        await _api.updateDraft(_draftId!, {
          'applicationAction': _applicationAction,
          'businessId': _effectiveBusinessId,
          'form': _form(),
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
        () => _error = 'Please complete the project / property address and scope of work.',
      );
      return;
    }
    // A PRC licence number is seven digits (QA TC-32, 2026-10-03: "abc" was
    // accepted and shown to staff). Optional, so only checked when given.
    if (prcNumberProblem(_prcNumber.text) case final problem?) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.updateDraft(_draftId!, {
        'location': _projectAddress.text.trim(),
        'form': _form(),
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
      // One file stands as one document (QA TC-21, 2026-10-03: the land title
      // uploaded again as the Survey Plan was accepted and counted). The
      // server answers a file the citizen already has with that copy, so the
      // same file twice arrives here as the same document.
      final holder = _attachedDocIds.entries
          .where((e) => e.key != doc.code && e.value == documentId)
          .map((e) => _requirements.where((r) => r.code == e.key).firstOrNull?.label ?? 'another requirement')
          .firstOrNull;
      if (holder != null) {
        _say(sameFileMessage(file.fileName, holder, doc.label));
        return;
      }
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
      messageBar(message),
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
            'businessId': _effectiveBusinessId,
            'form': _form(),
            ..._referenceFields(),
          });
        } else if (_step == 2) {
          await _api.updateDraft(_draftId!, {
            if (_projectAddress.text.trim().isNotEmpty)
              'location': _projectAddress.text.trim(),
            'form': _form(),
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
    var saved = 'Draft saved. Continue it any time from My Applications.';
    // Save on Review (an account not verified yet, too) keeps the delivery
    // choice, so Continue brings it back. An address the courier could not
    // use is not saved, and the citizen is told so.
    if (_step == 4 && _draftId != null) {
      final problem = _checkDeliveryAddress();
      final notSaved = problem == null ? await _saveDeliveryChoice() : null;
      if (problem != null) {
        saved = 'Draft saved. Your delivery address was not saved: $problem';
      } else if (notSaved != null) {
        saved = 'Draft saved. How you receive the permit was not saved: $notSaved';
      }
    }
    if (!mounted) return;
    context.read<ApplicationsService>().refresh();
    ScaffoldMessenger.of(context).showSnackBar(messageBar(saved));
    Navigator.of(context).pop();
  }

  bool _understandRequirements = false;
  bool _agreeTerms = false;

  Future<void> _submit() async {
    if (!_understandRequirements || !_agreeTerms) {
      setState(() => _error = 'Please check both declarations to continue.');
      return;
    }
    // The server's own address rules, checked before anything is sent.
    final deliveryProblem = _checkDeliveryAddress();
    if (deliveryProblem != null) {
      setState(() => _error = 'Delivery address: $deliveryProblem');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _attachPending();
      // How the permit is received, on the draft before it is filed: a
      // refused address stops here, with nothing filed yet.
      final notSaved = await _saveDeliveryChoice();
      if (notSaved != null) {
        if (!mounted) return;
        setState(() {
          if (_delivery.isDelivery) _deliveryProblem = notSaved;
          _error = 'How you receive the permit was not saved: $notSaved';
        });
        return;
      }
      await _api.submitDraft(_draftId!);
      if (!mounted) return;
      context.read<ApplicationsService>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        messageBar('Application submitted to the Municipality.'),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(applicationId: _draftId!),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      // 422: the account is not verified yet, "Applying as" is incomplete, or
      // the use or character of occupancy is missing (ebpco-api 071). The
      // detail is a whole sentence for the citizen; the draft stays saved. One
      // that points at the use of occupancy is shown on step 1, where it is asked.
      if (e.problem?.fieldErrors.any((f) => f.pointer.startsWith('/form/occupancy')) ?? false) _goTo(1);
      setState(() => _error = e.citizenMessage);
      if (e.status == 422) {
        context.read<SessionService>().refreshProfile().catchError((_) {});
      }
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
    String? closed(String kind) =>
        applicantKindClosedMessage(permitType: _permitType, kind: kind, kinds: _applicantKinds);
    final residentialClosed = closed(applyingAsResidential);
    final businessClosed = closed(applyingAsBusiness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Applicant & type', style: SoftType.h1.copyWith(fontSize: 24)),
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
        _label('Applying as'),
        SoftChoiceCard(
          icon: Icons.home_outlined,
          title: applyingAsLabel(applyingAsResidential),
          subtitle: residentialClosed ?? 'For your own home or private property. No business needed.',
          selected: _isResidential,
          onTap: residentialClosed == null ? () => _chooseApplyingAs(applyingAsResidential) : null,
        ),
        const SizedBox(height: 10),
        SoftChoiceCard(
          icon: Icons.storefront_outlined,
          title: applyingAsLabel(applyingAsBusiness),
          subtitle: businessClosed ?? 'A business or commercial establishment',
          selected: _applyingAs == applyingAsBusiness,
          onTap: businessClosed == null ? () => _chooseApplyingAs(applyingAsBusiness) : null,
        ),
        // Who usually applies: guidance, never a rule.
        if (usualUseNote(_permitType, _applicantKinds) case final note?) ...[
          const SizedBox(height: 10),
          _note(note),
        ],
        // The use or character of occupancy (LGU, 4 Nov 2026: "no option for
        // residential, institutional"): the National Building Code's Groups A
        // to J, asked of a Building Permit and a Certificate of Occupancy only,
        // and required to file one (ebpco-api 071).
        if (_asksOccupancy) ...[
          const SizedBox(height: 18),
          _occupancyField(),
        ],
        if (_applyingAs == applyingAsBusiness) ...[
          const SizedBox(height: 18),
          _label('Business'),
          _businessPicker(businesses, active),
        ],
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
          if (!_paperPermit) _earlierPicks(),
          const SizedBox(height: 6),
          if (_verifiedPermit != null && _permitNumberError == null && !_paperPermit)
            _verifiedPermitLine(_verifiedPermit!)
          else
            Text(
              _paperPermit
                  ? 'The office checks this against the copy of the permit you upload in the Documents step.'
                  : _isResidential
                      ? 'Checked against permits eBPCO issued to you before you can continue.'
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
              'Only when it is not on your account. You will need to upload a copy of it.',
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

  /// "Use or character of occupancy": the groups, and the use typed in for
  /// "Others (specify)".
  Widget _occupancyField() {
    void clearError() {
      if (_error != null) setState(() => _error = null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(occupancyFieldLabel),
        DropdownButtonFormField<String>(
          // A draft read back after this field was built shows its answer.
          key: ValueKey('wizard-occupancy-group-$_occupancyLoads'),
          initialValue: _occupancyGroup,
          hint: const Text("Select the building's use"),
          isExpanded: true,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          menuMaxHeight: 420,
          decoration: const InputDecoration(helperText: occupancyHint, helperMaxLines: 3),
          items: [
            for (final g in occupancyGroups)
              DropdownMenuItem(value: g.value, child: Text(g.label, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) => setState(() {
            _occupancyGroup = value;
            _error = null;
          }),
        ),
        if (_occupancyGroup == occupancyOtherValue) ...[
          const SizedBox(height: 16),
          _label(occupancyOtherLabel),
          TextField(
            key: const ValueKey('wizard-occupancy-other'),
            controller: _occupancyOther,
            style: SoftType.field,
            maxLength: occupancyOtherMax,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => clearError(),
            decoration: const InputDecoration(
              hintText: 'e.g. Chapel, water refilling station',
              counterText: '',
            ),
          ),
        ],
      ],
    );
  }

  /// A quiet line of guidance with an info mark: never blocks anything.
  Widget _note(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: SoftColors.pendingInk),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: SoftType.cellLabel.copyWith(color: SoftColors.pendingInk)),
          ),
        ],
      );

  /// Business: one of the citizen's active businesses, or the way to register one.
  Widget _businessPicker(BusinessesService businesses, List<Business> active) {
    if (active.isEmpty && businesses.error != null && !businesses.loading) {
      return SoftCard(
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
      );
    }
    if (active.isEmpty) {
      return SoftCard(
        color: SoftColors.primaryWash,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businesses.loading
                  ? 'Loading your businesses…'
                  : 'You have no active business yet. Register it here, or choose Residential / '
                      'Private Individual if this is for your home or other private property.',
              style: SoftType.body.copyWith(color: SoftColors.ink),
            ),
            if (!businesses.loading) ...[
              const SizedBox(height: 10),
              SoftPillButton(
                label: 'Register a Business',
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
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: active.any((b) => b.id == _businessId) ? _businessId : null,
      hint: const Text('Select a business'),
      isExpanded: true,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      items: active.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
      onChanged: (v) => setState(() {
        _businessId = v;
        _error = null;
        _invalidatePermitCheck();
      }),
    );
  }

  /// The citizen's permits issued before eBPCO of this type (ebpco-api 069),
  /// matched to the account by an officer: a tap fills the number exactly as
  /// the register writes it. Continue checks it like a typed one.
  Widget _earlierPicks() {
    final earlier = context.watch<EarlierRecordsService>().permitsOfType(_permitType);
    if (earlier.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your permits issued before eBPCO:', style: SoftType.cellLabel),
          const SizedBox(height: 6),
          // Follows the field as it is typed in, so the pick that matches shows chosen.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _permitNumber,
            builder: (context, typed, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final permit in earlier)
                  SizedBox(
                    height: 36,
                    // As wide as its number, not the whole row.
                    child: IntrinsicWidth(
                      child: SoftFilterChip(
                        label: permit.permitNumber,
                        selected: permit.permitNumber.toUpperCase() == typed.text.trim().toUpperCase(),
                        onTap: () => setState(() {
                          _permitNumber.text = permit.permitNumber;
                          _invalidatePermitCheck();
                        }),
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
        _label('Project / Property Address'),
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
        TextField(
          controller: _prcNumber,
          style: SoftType.field,
          keyboardType: TextInputType.number,
          maxLength: 7,
          decoration: const InputDecoration(
            hintText: '7 digits, e.g. 0012345',
            helperText: "The 7-digit number on the professional's PRC ID.",
            counterText: '',
          ),
        ),
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
        if (_visibleRequirements.any((r) => !_isRequired(r))) ...[
          const SizedBox(height: 4),
          Text('If applicable: attach only if your project includes this work.', style: SoftType.body),
        ],
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
                  // "If applicable", not "Optional" (LGU, 4 Nov 2026), and
                  // whether paper copies are needed too (ebpco-api 071).
                  RequirementHeading(doc: doc, required: _isRequired(doc), attached: attached != null),
                  // A document that IS a form to sign on paper (the Unified
                  // Building Permit Form, an ancillary form): the blank one,
                  // to print, sign and upload here.
                  if (blankFormFor(doc.code) case final form?) ...[
                    const SizedBox(height: 14),
                    BlankFormLink(form: form),
                  ],
                  const SizedBox(height: 14),
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

    final verification = context.watch<SessionService>().verification;
    final blocked = filingBlockedMessage(verification);
    final businessName = context
        .watch<BusinessesService>()
        .businesses
        .where((b) => b.id == _businessId)
        .map((b) => b.name)
        .firstOrNull;

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
              row('Applying as', applyingAsLabel(_applyingAs)),
              // Residential names no business, and no owner: the citizen applies for their own property.
              if (!_isResidential) ...[
                const Divider(height: 1, color: SoftColors.line),
                row('Business', businessName ?? 'Not chosen'),
              ],
              if (_asksOccupancy && _occupancyGroup != null) ...[
                const Divider(height: 1, color: SoftColors.line),
                row(occupancyFieldLabel, occupancyLabel(_occupancyGroup!, _occupancyOther.text)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _goTo(1), child: const Text('Edit')),
              ),
              const Divider(height: 1, color: SoftColors.line),
              row('Project / Property Address', _projectAddress.text),
              const Divider(height: 1, color: SoftColors.line),
              row('Scope of Work', _scopeOfWork.text),
              const Divider(height: 1, color: SoftColors.line),
              // Everything typed in the Details step, as it will be filed (QA TC-22).
              row('Professional in Charge', _professionalName.text.trim().isEmpty ? 'None given' : _professionalName.text.trim()),
              const Divider(height: 1, color: SoftColors.line),
              row('PRC License No.', _prcNumber.text.trim().isEmpty ? 'None given' : _prcNumber.text.trim()),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _goTo(2), child: const Text('Edit details')),
              ),
              const Divider(height: 1, color: SoftColors.line),
              row(
                'Documents attached',
                '${_visibleRequirements.where((r) => _attachedDocIds.containsKey(r.code)).length} of ${_visibleRequirements.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // Pick up at the office, or delivery by courier (ebpco-api 070, owner
        // request 2026-11-03). Saved on the draft just before it is filed;
        // changeable on the application page until the permit is handed to
        // the courier.
        DeliveryChoiceForm(
          key: const ValueKey('wizard-receive-by'),
          controller: _delivery,
          feeNote: _feeNote,
          problem: _deliveryProblem,
          onEdited: () {
            if (_deliveryProblem == null) return;
            setState(() {
              _deliveryProblem = null;
              if (_error?.startsWith('Delivery address:') ?? false) _error = null;
            });
          },
          prefill: () => addressFromProfile(context.read<SessionService>().profile),
        ),
        const SizedBox(height: 18),
        if (blocked != null)
          ..._notVerifiedYet(blocked, verification)
        else ...[
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
      ],
    );
  }

  /// Not verified yet (ebpco-api 067): the draft is kept and the citizen is
  /// told why it cannot be submitted, with the way to send an ID.
  List<Widget> _notVerifiedYet(String message, AccountVerification? verification) {
    final rejected = verification?.isRejected ?? false;
    return [
      SoftCard(
        color: rejected ? SoftColors.dangerSoft : SoftColors.pendingCream,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: SoftType.body.copyWith(color: SoftColors.ink)),
            if (!(verification?.isPending ?? true)) ...[
              const SizedBox(height: 12),
              SoftPillButton(
                label: rejected ? 'Upload again' : 'Verify my account',
                kind: SoftPillKind.outline,
                icon: Icons.badge_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountVerificationScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _navRow(
        onBack: () => _goTo(3),
        nextLabel: 'Save Draft & Exit',
        onNext: _saveAndExit,
      ),
    ];
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

/// Null when [value] is empty or a PRC licence number: the seven digits on the
/// professional's PRC ID, the citizen portal's check (QA TC-32).
String? prcNumberProblem(String value) {
  final number = value.trim();
  if (number.isEmpty || RegExp(r'^\d{7}$').hasMatch(number)) return null;
  return "A PRC license number is the 7 digits on the professional's PRC ID, for example 0012345.";
}

/// The citizen portal's words for the same file attached twice (QA TC-21).
String sameFileMessage(String fileName, String heldBy, String wantedFor) =>
    '"$fileName" is already attached as "$heldBy". Attach the right file for "$wantedFor".';
