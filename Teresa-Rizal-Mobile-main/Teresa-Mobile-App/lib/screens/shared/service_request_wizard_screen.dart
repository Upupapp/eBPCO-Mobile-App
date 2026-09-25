import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/resident_profile.dart';
import '../../models/service_form_spec.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_flow_scaffold.dart';
import '../../utils/age_calculator.dart';
import '../../utils/requirement_document_type.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section.dart';
import '../../widgets/onboarding_step_indicator.dart';
import '../../widgets/payment_method_tile.dart';
import '../../widgets/requirement_uploader.dart';
import '../profile/g6/g6_filing.dart';
import '../profile/resident_profile/personal_information_screen.dart';
import 'receipt_screen.dart';
import 'request_detail_screen.dart';
import 'request_submitted_screen.dart';

/// "Sir Paul's Required Form Experience" — a data-driven, multi-step
/// service-request wizard mirroring `RegisterScreen`'s step pattern
/// (indicator, per-step validation, Back/Continue, a Review step with
/// per-field Edit links) instead of the older single-screen Purpose +
/// Attachments form. Step count/labels come from the service's
/// [ServiceFormSpec] (see docs/DOKYU_TULONG_FORM_AUDIT.md for sourcing),
/// so a richly-sourced service like the Solo Parent application gets many
/// steps while a lightly-sourced one gets few — nothing here forces a
/// fixed step count.
///
/// Fixed steps around the data-driven middle:
///   0. Applicant Information (auto-filled from the signed-in account)
///   1..N. one step per `formSpec.steps` entry
///   N+1. Requirements & Attachments (from `item.requirements`)
///   N+2. Review & Submit
class ServiceRequestWizardScreen extends StatefulWidget {
  final ServiceCategory category;
  final CatalogItem item;
  final Color accent;

  /// Opens a later step directly. The live flow always starts at 0.
  /// Screenshot and review harnesses use this to land on Review or Payment
  /// without walking every attachment gate.
  final int initialStep;

  const ServiceRequestWizardScreen({
    super.key,
    required this.category,
    required this.item,
    required this.accent,
    this.initialStep = 0,
  });

  @override
  State<ServiceRequestWizardScreen> createState() => _ServiceRequestWizardScreenState();
}

class _ServiceRequestWizardScreenState extends State<ServiceRequestWizardScreen> {
  /// The primary demo resident — same id ResidentProfileService and
  /// RequestsService already use for their own Perlita-specific logic. Only
  /// her forms get [CatalogItem.demoDefaults]/[CatalogItem.demoPurpose]
  /// applied; a different verified resident's form stays exactly as
  /// blank/Master-Profile-only as before.
  static const _verifiedDemoAccountId = 'ESP-RES-2024-9002';

  List<ServiceFormStep> get _serviceSteps => widget.item.formSpec!.steps;
  int get _requirementsStep => _serviceSteps.length + 1;
  int get _reviewStep => _serviceSteps.length + 2;

  /// Every Dokyu service with a real configured fee gets its own Payment
  /// Method step, after Review — Tulong never does (assistance
  /// applications have no payment concept), and a Free Dokyu service
  /// skips straight from Review to submission. See the Mobile-only final
  /// request-flow correction pass: payment now happens during the
  /// application/submission flow itself, before a request exists at all,
  /// never as a later tracking milestone.
  bool get _isPaidDokyu => widget.category == ServiceCategory.dokyu && widget.item.fee != 'Free';
  int get _paymentStep => _reviewStep + 1;
  int get _lastStep => _isPaidDokyu ? _paymentStep : _reviewStep;

  late final List<String> _stepLabels = [
    'Applicant Info',
    for (final s in _serviceSteps) s.label,
    'Requirements',
    'Review',
    if (_isPaidDokyu) 'Payment',
  ];

  int _step = 0;
  String? _error;
  bool _submitting = false;

  /// 'GCash' / 'Maya' / 'Onsite' — chosen on the Payment Method step, only
  /// ever meaningful when [_isPaidDokyu].
  String? _paymentMethod;

  // Applicant info (step 0) — prefilled from the signed-in account, still
  // editable since a request's details can differ from the base profile
  // (e.g. requesting on behalf of a household matter).
  final _fullName = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _purok = TextEditingController();
  String? _barangay;

  // Service-specific field values, keyed by ServiceFormField.key. Text-like
  // fields are read from `_controllers`; everything else lives here.
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  // Master Profile — reusable demographic fields (see
  // docs on the "single source of truth" rule): keys this specific
  // service's formSpec happens to ask for AND the citizen's Resident
  // Profile already has an answer for. These render read-only (with an
  // "Edit Profile" escape hatch) instead of an editable input, so a single
  // request can never silently drift from the citizen's master record —
  // see _MasterSourcedField. Keys the profile *doesn't* have yet stay
  // normally editable and get backfilled into the profile on submit (see
  // _backfillMasterProfile), rather than left as a one-off, request-only
  // answer.
  static const _masterEligibleKeys = {'sex', 'civilStatus', 'occupation', 'educationalAttainment'};
  Individual? _personal;
  final Set<String> _prefilledFromProfile = {};

  // Requirements & Attachments step.
  final _notesController = TextEditingController();

  /// One entry per requirement, keyed by its own label (unique within a
  /// single catalog item) — every Dokyu and Tulong service uses this same
  /// per-requirement architecture (see RequirementUploader and the Dokyu +
  /// Tulong requirement-upload standardization pass); there is no separate
  /// flat/generic attachment list anymore.
  late final List<RequirementInfo> _requirementInfos = resolveRequirements(widget.item.requirements);
  final Map<String, Attachment?> _requirementAttachments = {};

  int get _attachmentCount => _requirementAttachments.values.whereType<Attachment>().length;

  bool get _hasPurposeField => _serviceSteps.any((s) => s.fields.any((f) => f.key == 'purpose'));

  /// Whether [f] should currently be shown/enforced — see
  /// [ServiceFormField.visibleWhenKey]'s own doc comment. Fields with no
  /// gate are always visible, which is every pre-existing formSpec's
  /// entire field list, so this is a no-op for them.
  bool _isFieldVisible(ServiceFormField f) {
    if (f.visibleWhenKey == null) return true;
    return f.visibleWhenValueIn!.contains(_values[f.visibleWhenKey]);
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_revealFocusedField);
    _step = widget.initialStep.clamp(0, _lastStep);
    final account = context.read<CitizenSessionService>().account;
    if (account != null) {
      // Sourced from the Resident Profile (the Master Profile's richer,
      // editable record) rather than the shallower CitizenSessionService
      // account — editing Personal Information never writes back to that
      // account object, so reading it directly here would show stale data
      // once a citizen updates their profile. ResidentProfileService seeds
      // a fresh profile straight from the account on first-ever access, so
      // this is never *less* complete than the old source, only ever more
      // current.
      final personal = context.read<ResidentProfileService>().profileFor(account).personal;
      _personal = personal;

      final filedFor = G6FilingContext.memberName?.trim();
      _fullName.text = (filedFor != null && filedFor.isNotEmpty) ? filedFor : personal.fullName;
      _contact.text = personal.mobile;
      _email.text = personal.email;
      _purok.text = personal.sitioPurok;
      _barangay = personal.barangay.isEmpty ? null : personal.barangay;

      // Prefill Date of Birth from the citizen's existing Resident Profile
      // (already parsed to a real DateTime there) rather than making them
      // re-enter it on every application — see the global birthdate/age
      // rule in docs/DOKYU_TULONG_FORM_AUDIT.md. Only applied to field keys
      // this service actually asks for; 'party1DateOfBirth' covers the
      // Marriage License item, whose first party is assumed to be the
      // applicant.
      final dob = personal.birthdate;
      if (dob != null) {
        for (final key in const ['dateOfBirth', 'party1DateOfBirth']) {
          if (_serviceSteps.any((s) => s.fields.any((f) => f.key == key))) {
            _values[key] = dob;
          }
        }
      }

      // Same "single source of truth" treatment for the other reusable
      // demographic fields already modeled on the Master Profile. Text-
      // and select-typed fields store their current value differently
      // (_controllers vs. _values), so both are populated depending on
      // what this particular field actually is.
      for (final key in _masterEligibleKeys) {
        final masterValue = switch (key) {
          'sex' => personal.sex,
          'civilStatus' => personal.civilStatus,
          'occupation' => personal.occupation,
          'educationalAttainment' => personal.educationalAttainment,
          _ => '',
        };
        if (masterValue.trim().isEmpty) continue;
        final field = _fieldByKey(key);
        if (field == null) continue;
        if (field.type == ServiceFieldType.text) {
          _controllerFor(key).text = masterValue;
        } else if (field.type == ServiceFieldType.select) {
          // A select field's own local option list is sourced per-service
          // from an official form and isn't guaranteed to include every
          // Master Profile value verbatim (e.g. several older forms here
          // predate "Senior High School" as its own tier and only offer
          // "High School"/"College") — DropdownButtonFormField crashes
          // outright if given a value absent from its own items, so this
          // must never force a mismatched value in. Skipping leaves the
          // field a normal, still-required editable select the citizen
          // picks themself, same as before this Master Profile value ever
          // existed.
          if (field.options?.contains(masterValue) ?? false) {
            _values[key] = masterValue;
          } else {
            continue;
          }
        } else {
          _values[key] = masterValue;
        }
        _prefilledFromProfile.add(key);
      }

      // Richer student/family fields (Educational Assistance today — see
      // mock_catalog.dart's tulong_educational formSpec) prefilled the same
      // way Date of Birth is above: a starting value in an otherwise-
      // editable text field, not the stricter _masterEligibleKeys lock,
      // since Personal Information has no dedicated UI for these yet (only
      // Edit Profile's Basic Information covers the fields that lock).
      // Field keys match Individual's own field names exactly (see that
      // class's doc comment), so this is a direct 1:1 lookup.
      final personalPrefills = <String, String>{
        'placeOfBirth': personal.placeOfBirth,
        'schoolName': personal.schoolName,
        'yearOrGradeLevel': personal.yearOrGradeLevel,
        'degreeProgramOrCourse': personal.degreeProgramOrCourse,
        'lastSchoolAverageGrade': personal.lastSchoolAverageGrade,
        'communityInvolvement': personal.communityInvolvement,
        'postGraduationPlans': personal.postGraduationPlans,
      };
      for (final entry in personalPrefills.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (_fieldByKey(entry.key) == null) continue;
        _controllerFor(entry.key).text = entry.value;
      }

      // Father/Mother — sourced from Family Information (relationshipToHead
      // == 'Father'/'Mother'), not from `personal` itself, so this is a
      // separate lookup from the block above.
      final profile = context.read<ResidentProfileService>().profileFor(account);
      Individual? familyMemberWhere(String relationship) {
        for (final m in profile.familyMembers) {
          if (m.relationshipToHead == relationship) return m;
        }
        return null;
      }

      final father = familyMemberWhere('Father');
      if (father != null) {
        if (father.fullName.trim().isNotEmpty && _fieldByKey('fatherName') != null) {
          _controllerFor('fatherName').text = father.fullName;
        }
        if (father.occupation.trim().isNotEmpty && _fieldByKey('fatherOccupation') != null) {
          _controllerFor('fatherOccupation').text = father.occupation;
        }
      }
      final mother = familyMemberWhere('Mother');
      if (mother != null) {
        if (mother.fullName.trim().isNotEmpty && _fieldByKey('motherName') != null) {
          _controllerFor('motherName').text = mother.fullName;
        }
        if (mother.occupation.trim().isNotEmpty && _fieldByKey('motherOccupation') != null) {
          _controllerFor('motherOccupation').text = mother.occupation;
        }
      }

      // Household.monthlyIncome is stored pre-formatted (e.g. "₱9,718") for
      // display elsewhere — this field is ServiceFieldType.number with its
      // own "(₱)" already in the label, so only the plain digits belong in
      // the input itself.
      final income = profile.household.monthlyIncome;
      if (income.trim().isNotEmpty && _fieldByKey('parentsMonthlyIncome') != null) {
        final digitsOnly = income.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.isNotEmpty) _controllerFor('parentsMonthlyIncome').text = digitsOnly;
      }

      // Emergency Contact — sourced from Family Information's own Emergency
      // Contact fields (see ResidentProfile.emergencyContactName/Number and
      // the targeted Family Information Emergency Contact editing pass),
      // reused by any service form that asks for one under these exact
      // shared field-key names (e.g. Pet Registration, Solo Parent Cash
      // Assistance) — same "single source of truth" treatment as
      // Father/Mother above, so this never needs a separate
      // service-specific demoDefault.
      final emergencyContactPrefills = <String, String>{
        'emergencyContactName': profile.emergencyContactName,
        'emergencyContactNumber': profile.emergencyContactNumber,
      };
      for (final entry in emergencyContactPrefills.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (_fieldByKey(entry.key) == null) continue;
        _controllerFor(entry.key).text = entry.value;
      }

      // Service-specific demo answers (see mock_catalog.dart's own
      // CatalogItem.demoDefaults doc comment) — realistic starting values
      // for fields no Master Profile mechanism above already covers (e.g.
      // Purpose selects, business details, confirmation checkboxes), so
      // the primary demo resident's forms open ready for a live
      // presentation instead of blank. Every field this touches remains a
      // normal, editable value — nothing here locks or validates
      // differently. Gated to Perlita specifically (the account these
      // values were written for), not every verified resident.
      if (account.id == _verifiedDemoAccountId) {
        for (final entry in widget.item.demoDefaults.entries) {
          final field = _fieldByKey(entry.key);
          if (field == null) continue;
          switch (field.type) {
            case ServiceFieldType.text:
            case ServiceFieldType.textarea:
            case ServiceFieldType.number:
              if (_controllerFor(entry.key).text.isEmpty) {
                _controllerFor(entry.key).text = entry.value as String;
              }
            case ServiceFieldType.date:
              // demoDefaults stores dates as an ISO string, not a DateTime
              // literal — CatalogItem.demoDefaults must stay a const map
              // (documentTypes/assistanceTypes are const lists) and
              // DateTime has no const constructor.
              _values.putIfAbsent(entry.key, () => DateTime.parse(entry.value as String));
            case ServiceFieldType.select:
              // Guards the same class of crash as the Master-Profile
              // select prefill above — a demoDefault authored for one
              // version of a field's option list must never be trusted
              // blindly if that list changes later, since
              // DropdownButtonFormField crashes outright on an unmatched
              // value.
              if (field.options?.contains(entry.value) ?? false) {
                _values.putIfAbsent(entry.key, () => entry.value);
              }
            case ServiceFieldType.multiselect:
            case ServiceFieldType.checkbox:
              _values.putIfAbsent(entry.key, () => entry.value);
            case ServiceFieldType.derivedAge:
              break; // never independently set — always derived
          }
        }
        if (widget.item.demoPurpose != null && _notesController.text.isEmpty) {
          _notesController.text = widget.item.demoPurpose!;
        }
      }
    }
  }

  ServiceFormField? _fieldByKey(String key) {
    for (final s in _serviceSteps) {
      for (final f in s.fields) {
        if (f.key == key) return f;
      }
    }
    return null;
  }

  void _revealFocusedField() {
    final fieldContext = FocusManager.instance.primaryFocus?.context;
    if (fieldContext == null) return;
    SoftIme.reveal(fieldContext);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_revealFocusedField);
    _fullName.dispose();
    _contact.dispose();
    _email.dispose();
    _purok.dispose();
    _notesController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(key, () => TextEditingController());

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      if (_step < _lastStep) _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
  }

  String? _validateStep(int step) {
    if (step == 0) {
      if (_fullName.text.trim().isEmpty) return 'Please enter your full name.';
      if (_barangay == null) return 'Please select your barangay.';
      return null;
    }
    if (step >= 1 && step <= _serviceSteps.length) {
      final s = _serviceSteps[step - 1];
      for (final f in s.fields) {
        if (!f.required || !_isFieldVisible(f)) continue;
        if (_isFieldEmpty(f)) return 'Please complete "${f.label}".';
      }
      return null;
    }
    if (step == _requirementsStep) {
      if (!_hasPurposeField && _notesController.text.trim().isEmpty) {
        return 'Please describe the purpose of this request.';
      }
      // requiresUpload excludes a requirement that isn't something the
      // resident attaches a file for (a staff/office process, or
      // descriptive text already captured elsewhere) — see RequirementInfo
      // .requiresUpload's own doc comment. Never counted as "missing".
      final missing = _requirementInfos
          .where((r) => r.isRequired && r.requiresUpload && _requirementAttachments[r.label] == null)
          .toList();
      if (missing.isNotEmpty) {
        return missing.length == 1
            ? 'Please attach your ${missing.first.label}.'
            : 'Please attach: ${missing.map((r) => r.label).join(', ')}.';
      }
      return null;
    }
    if (step == _paymentStep) {
      if (_paymentMethod == null) return 'Please choose a payment method.';
      return null;
    }
    return null; // review step
  }

  /// Computes an [ServiceFieldType.derivedAge] field's value from its
  /// paired birthdate field — the only source of truth for age anywhere in
  /// this wizard; nothing lets a citizen type an age independently.
  int? _computeAge(String derivedFromKey) {
    final dob = _values[derivedFromKey] as DateTime?;
    return dob == null ? null : calculateAge(dob);
  }

  bool _isFieldEmpty(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
      case ServiceFieldType.textarea:
      case ServiceFieldType.number:
        return _controllers[f.key]?.text.trim().isEmpty ?? true;
      case ServiceFieldType.date:
        return _values[f.key] == null;
      case ServiceFieldType.select:
        return _values[f.key] == null;
      case ServiceFieldType.multiselect:
        final v = _values[f.key];
        return v == null || (v as Set<String>).isEmpty;
      case ServiceFieldType.checkbox:
        return _values[f.key] != true;
      case ServiceFieldType.derivedAge:
        return _computeAge(f.derivedFromKey!) == null;
    }
  }

  String _displayValue(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
      case ServiceFieldType.textarea:
      case ServiceFieldType.number:
        final t = _controllers[f.key]?.text.trim() ?? '';
        return t.isEmpty ? '—' : t;
      case ServiceFieldType.date:
        final v = _values[f.key] as DateTime?;
        return v == null ? '—' : DateFormat('MMM d, y').format(v);
      case ServiceFieldType.select:
        return (_values[f.key] as String?) ?? '—';
      case ServiceFieldType.multiselect:
        final v = _values[f.key] as Set<String>?;
        return (v == null || v.isEmpty) ? '—' : v.join(', ');
      case ServiceFieldType.checkbox:
        return (_values[f.key] == true) ? 'Yes' : 'No';
      case ServiceFieldType.derivedAge:
        final a = _computeAge(f.derivedFromKey!);
        return a == null ? '—' : '$a years old';
    }
  }

  Map<String, dynamic> _buildFormFields() {
    final out = <String, dynamic>{
      'applicantFullName': _fullName.text.trim(),
      'applicantBarangay': _barangay ?? '',
      'applicantPurok': _purok.text.trim(),
      'applicantContact': _contact.text.trim(),
      'applicantEmail': _email.text.trim(),
    };
    for (final s in _serviceSteps) {
      for (final f in s.fields) {
        final dynamic raw = switch (f.type) {
          ServiceFieldType.text ||
          ServiceFieldType.textarea ||
          ServiceFieldType.number => _controllers[f.key]?.text.trim(),
          ServiceFieldType.date => (_values[f.key] as DateTime?)?.toIso8601String(),
          ServiceFieldType.select => _values[f.key],
          ServiceFieldType.multiselect => (_values[f.key] as Set<String>?)?.toList(),
          ServiceFieldType.checkbox => _values[f.key] == true,
          // Preserved in submission data (some official/backend shapes
          // expect an age value) but always derived, never typed — see the
          // global birthdate/age rule.
          ServiceFieldType.derivedAge => _computeAge(f.derivedFromKey!),
        };
        out[f.key] = raw;
      }
    }
    return out;
  }

  /// Writes any master-eligible field the citizen typed fresh in this
  /// request (i.e. the Master Profile didn't already have it — see
  /// [_prefilledFromProfile]) back into their Resident Profile, so the next
  /// applicable request prefills it too instead of asking again. Fields the
  /// profile already answered are never touched here, and request-specific
  /// fields (purpose, reasons, etc.) are never candidates at all — only the
  /// fixed [_masterEligibleKeys] set.
  Future<void> _backfillMasterProfile(ResidentProfileService profileService, String accountId) async {
    final personal = _personal;
    if (personal == null) return;
    var changed = false;
    for (final key in _masterEligibleKeys) {
      if (_prefilledFromProfile.contains(key)) continue;
      final field = _fieldByKey(key);
      if (field == null) continue;
      final value = field.type == ServiceFieldType.text
          ? _controllers[key]?.text.trim()
          : _values[key] as String?;
      if (value == null || value.isEmpty) continue;
      switch (key) {
        case 'sex':
          personal.sex = value;
        case 'civilStatus':
          personal.civilStatus = value;
        case 'occupation':
          personal.occupation = value;
        case 'educationalAttainment':
          personal.educationalAttainment = value;
      }
      changed = true;
    }
    if (changed) await profileService.backfillPersonalField(accountId, personal);
  }

  String _resolvePurpose() {
    final notes = _notesController.text.trim();
    if (_hasPurposeField) {
      final v = _values['purpose'] as String?;
      if (v != null && v.isNotEmpty) return notes.isEmpty ? v : '$v — $notes';
    }
    return notes.isEmpty ? widget.item.name : notes;
  }

  Future<void> _submit() async {
    final account = context.read<CitizenSessionService>().account!;
    final requestsService = context.read<RequestsService>();

    if (widget.category == ServiceCategory.tulong) {
      final result = tulongEligibilityFor(requestsService, applicantId: account.id, typeName: widget.item.name);
      if (!result.isEligible) {
        final viewRequest = await showTulongBlockedDialog(context, result);
        if (viewRequest && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
          );
        }
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final profileService = context.read<ResidentProfileService>();
    await Future.delayed(const Duration(milliseconds: 900)); // simulated network/processing delay
    await _backfillMasterProfile(profileService, account.id);

    final attachments = _requirementAttachments.values.whereType<Attachment>().toList();

    final request = await requestsService.submit(
      applicantId: account.id,
      applicantName: _fullName.text.trim(),
      typeName: widget.item.name,
      category: widget.category,
      office: widget.item.office,
      purpose: _resolvePurpose(),
      expectedDays: widget.item.days,
      attachments: attachments,
      formFields: _buildFormFields(),
      requiresPayment: widget.item.fee != 'Free',
      fee: widget.item.fee,
      paymentMethod: _isPaidDokyu ? _paymentMethod : null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    // Every Dokyu request (paid or free) gets a receipt at submission time
    // now (see RequestsService.submit) — Tulong never does, so it keeps
    // going straight to the existing Request Submitted screen.
    if (widget.category == ServiceCategory.dokyu) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // routeContext, not this wizard State's own `context` — by the
          // time "Done" is actually tapped, pushReplacement has already
          // unmounted this wizard screen, so capturing `context` here would
          // throw "This widget has been unmounted" the moment onDone runs.
          builder: (routeContext) => ReceiptScreen(
            receipt: request.receipt!,
            onDone: () => Navigator.of(routeContext).pushReplacement(
              MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id)),
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RequestSubmittedScreen(
          referenceNumber: request.referenceNumber,
          typeName: request.typeName,
          accent: widget.accent,
          requestId: request.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = SoftIme.bottom(context);
    return SoftFlowScaffold(
      title: widget.item.name,
      resizeToAvoidBottomInset: true,
      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: OnboardingStepIndicator(currentStep: _step, stepLabels: _stepLabels),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + keyboard),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.paddingOf(context).bottom),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: _submitting ? null : _back,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _step != _lastStep
                          ? 'Continue'
                          : (_isPaidDokyu ? 'Confirm Payment' : 'Submit Request'),
                      icon: _step == _lastStep ? Icons.send_rounded : Icons.arrow_forward_rounded,
                      iconTrailing: _step != _lastStep,
                      fullWidth: true,
                      loading: _submitting,
                      onPressed: _step == _lastStep ? _submit : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _applicantInfoStep();
    if (_step >= 1 && _step <= _serviceSteps.length) return _serviceFieldStep(_serviceSteps[_step - 1]);
    if (_step == _requirementsStep) return _requirementsAttachmentsStep();
    if (_step == _paymentStep) return _paymentStepWidget();
    return _reviewStepWidget();
  }

  Widget _applicantInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SoftColors.blueSoft,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: SoftColors.blue, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "We've prefilled this from your Resident Profile. Changes here only apply to this request — to update your saved profile, use Edit Profile.",
                  style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _goToEditProfile,
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SoftColors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(label: 'Full name', controller: _fullName),
        const SizedBox(height: AppSpacing.lg),
        AppSelectField<String>(
          label: 'Barangay',
          value: _barangay,
          options: MockCatalog.barangays,
          labelBuilder: (b) => b,
          onChanged: (v) => setState(() => _barangay = v),
          hintText: 'Select your barangay',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Purok / Sitio', controller: _purok, icon: Icons.place_rounded),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Mobile number',
          controller: _contact,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_rounded,
          hintText: '09XX XXX XXXX',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _serviceFieldStep(ServiceFormStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection(
          title: step.label,
          description: step.description,
          children: [for (final f in step.fields.where(_isFieldVisible)) _buildField(f)],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  void _goToEditProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen()));
  }

  Widget _buildField(ServiceFormField f) {
    // Already known on the Master Profile — read-only here, with an
    // explicit escape hatch, rather than a second editable copy that could
    // silently drift from the citizen's actual record. See the class-level
    // Master Profile doc comment.
    if (_prefilledFromProfile.contains(f.key)) {
      return _MasterSourcedField(label: f.label, value: _displayValue(f), onEditProfile: _goToEditProfile);
    }
    switch (f.type) {
      case ServiceFieldType.text:
        return AppTextField(label: f.label, hintText: f.hint, controller: _controllerFor(f.key));
      case ServiceFieldType.number:
        return AppTextField(
          label: f.label,
          hintText: f.hint,
          controller: _controllerFor(f.key),
          keyboardType: TextInputType.number,
        );
      case ServiceFieldType.textarea:
        return AppTextField(label: f.label, hintText: f.hint, controller: _controllerFor(f.key), maxLines: 4);
      case ServiceFieldType.date:
        return AppDateField(
          label: f.label,
          value: _values[f.key] as DateTime?,
          onChanged: (d) => setState(() => _values[f.key] = d),
          lastDate: DateTime.now(),
        );
      case ServiceFieldType.select:
        return AppSelectField<String>(
          label: f.label,
          value: _values[f.key] as String?,
          options: f.options!,
          labelBuilder: (o) => o,
          onChanged: (v) => setState(() => _values[f.key] = v),
          hintText: f.hint ?? 'Select ${f.label}',
        );
      case ServiceFieldType.multiselect:
        return _MultiSelectField(
          label: f.label,
          options: f.options!,
          selected: (_values[f.key] as Set<String>?) ?? <String>{},
          onChanged: (s) => setState(() => _values[f.key] = s),
        );
      case ServiceFieldType.checkbox:
        return _CheckboxField(
          label: f.label,
          value: (_values[f.key] as bool?) ?? false,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case ServiceFieldType.derivedAge:
        // Read-only — rebuilds live whenever the paired date field's
        // setState fires, since both fields live in the same step.
        return _DerivedAgeField(label: f.label, age: _computeAge(f.derivedFromKey!));
    }
  }

  Widget _requirementsAttachmentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The per-requirement uploaders (below) already show each
        // requirement's label as its own section header, so a separate
        // informational checklist here would just repeat the same list.
        AppTextField(
          label: _hasPurposeField ? 'Additional notes (optional)' : 'Purpose',
          hintText: 'e.g. Employment requirement, medical assistance for hospital bill...',
          controller: _notesController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Requirements',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: SoftColors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Attach a document for each requirement below.',
          style: TextStyle(fontSize: 12, color: SoftColors.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Consumer<MasterFileService>(
          builder: (context, masterFile, _) {
            final accountId = context.read<CitizenSessionService>().account!.id;
            return Column(
              children: [
                for (final req in _requirementInfos)
                  RequirementUploader(
                    requirement: req,
                    attachment: _requirementAttachments[req.label],
                    accent: widget.accent,
                    existingMasterDoc: masterFile.findByType(accountId, req.documentType),
                    onAttachNew: (a) {
                      setState(() => _requirementAttachments[req.label] = a);
                      masterFile.saveOrUpdate(
                        accountId: accountId,
                        documentType: req.documentType,
                        label: req.label,
                        attachment: a,
                        origin: widget.category == ServiceCategory.dokyu ? 'Dokyu' : 'Tulong',
                        serviceName: widget.item.name,
                      );
                    },
                    onUseExisting: () {
                      final existing = masterFile.findByType(accountId, req.documentType);
                      if (existing != null) {
                        setState(
                          () => _requirementAttachments[req.label] =
                              attachmentForReuse(existing.attachment, requirementLabel: req.label),
                        );
                      }
                    },
                    onRemove: () => setState(() => _requirementAttachments[req.label] = null),
                  ),
              ],
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewStepWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Review Your Request', style: SoftType.name),
        const SizedBox(height: 6),
        Text(
          _isPaidDokyu
              ? 'Make sure everything looks correct before continuing to payment.'
              : 'Make sure everything looks correct before submitting.',
          style: const TextStyle(fontSize: 12.5, color: SoftColors.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        _reviewRow('Full name', _fullName.text.trim(), onEdit: () => setState(() => _step = 0)),
        _reviewRow('Barangay', _barangay ?? '—', onEdit: () => setState(() => _step = 0)),
        _reviewRow(
          'Purok / Sitio',
          _purok.text.trim().isEmpty ? '—' : _purok.text.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        _reviewRow(
          'Mobile',
          _contact.text.trim().isEmpty ? '—' : _contact.text.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        for (int i = 0; i < _serviceSteps.length; i++) ...[
          for (final f in _serviceSteps[i].fields.where(_isFieldVisible))
            // Derived Age never gets its own Edit control — editing it
            // means changing the Date of Birth it's computed from, so only
            // that field's row is tappable. Master-Profile-sourced fields
            // route to "Edit Profile" instead of jumping back a step, same
            // as their read-only rendering in the field step itself.
            _reviewRow(
              f.label,
              _displayValue(f),
              onEdit: f.type == ServiceFieldType.derivedAge
                  ? null
                  : _prefilledFromProfile.contains(f.key)
                  ? _goToEditProfile
                  : () => setState(() => _step = i + 1),
              editLabel: _prefilledFromProfile.contains(f.key) ? 'Edit Profile' : 'Edit',
            ),
        ],
        _reviewRow(
          _hasPurposeField ? 'Additional notes' : 'Purpose',
          _notesController.text.trim().isEmpty ? '—' : _notesController.text.trim(),
          onEdit: () => setState(() => _step = _requirementsStep),
        ),
        _reviewRow(
          'Attachments',
          _attachmentCount == 0 ? '—' : '$_attachmentCount file(s)',
          onEdit: () => setState(() => _step = _requirementsStep),
        ),
        if (_isPaidDokyu) _reviewRow('Fee', widget.item.fee, onEdit: null),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _paymentStepWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Choose Payment Method', style: SoftType.name),
        const SizedBox(height: 6),
        Text(
          'Required fee for this request: ${widget.item.fee}',
          style: const TextStyle(fontSize: 12.5, color: SoftColors.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        PaymentMethodTile(
          icon: Icons.storefront_rounded,
          iconColor: widget.accent,
          title: 'Pay at Municipal Office',
          subtitle: 'Onsite — settle the fee in person when you visit or claim your document.',
          selected: _paymentMethod == 'Onsite',
          onTap: () => setState(() => _paymentMethod = 'Onsite'),
        ),
        const SizedBox(height: AppSpacing.sm),
        PaymentMethodTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.brand600,
          title: 'GCash',
          subtitle: 'Simulated online payment — no real transaction is made.',
          demo: true,
          selected: _paymentMethod == 'GCash',
          onTap: () => setState(() => _paymentMethod = 'GCash'),
        ),
        const SizedBox(height: AppSpacing.sm),
        PaymentMethodTile(
          icon: Icons.credit_card_rounded,
          iconColor: AppColors.emerald700,
          title: 'Maya',
          subtitle: 'Simulated online payment — no real transaction is made.',
          demo: true,
          selected: _paymentMethod == 'Maya',
          onTap: () => setState(() => _paymentMethod = 'Maya'),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value, {required VoidCallback? onEdit, String editLabel = 'Edit'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: SoftColors.muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: SoftColors.ink),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Text(
                editLabel,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only "N years old" display for a [ServiceFieldType.derivedAge]
/// field — never a text box, never independently editable. Rebuilds
/// automatically whenever its paired Date of Birth field changes, since
/// both live in the same `FormSection` and a birthdate edit triggers the
/// whole step's `setState`.
class _DerivedAgeField extends StatelessWidget {
  final String label;
  final int? age;

  const _DerivedAgeField({required this.label, required this.age});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SoftColors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_rounded, size: 17, color: SoftColors.muted),
              const SizedBox(width: 10),
              Text(
                age == null ? 'Select your Date of Birth above first' : '$age years old',
                style: const TextStyle(fontSize: 14, color: AppColors.textBody, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Read-only display for a field the citizen's Master (Resident) Profile
/// already answers — Sex, Civil Status, Occupation, Educational Attainment,
/// etc. Editing it here would create a second, request-only copy that can
/// silently drift from the citizen's actual record, so it's shown rather
/// than typed; "Edit Profile" is the one place that value can change, and
/// that change then applies to every future request too.
class _MasterSourcedField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEditProfile;

  const _MasterSourcedField({required this.label, required this.value, required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Expanded, not a bare fixed-size child in a spaceBetween Row —
            // a longer field label (e.g. "Educational attainment", now also
            // reachable here since the Master Profile started answering it
            // — see the Perlita Master Profile Web Admin sync) plus "Edit
            // Profile" together can exceed a narrow phone's width.
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SoftColors.ink),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onEditProfile,
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: SoftColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: AppColors.textBody, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _MultiSelectField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SoftColors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o, style: const TextStyle(fontSize: 12)),
                selected: selected.contains(o),
                onSelected: (v) {
                  final next = Set<String>.from(selected);
                  if (v) {
                    next.add(o);
                  } else {
                    next.remove(o);
                  }
                  onChanged(next);
                },
                selectedColor: AppColors.brand100,
                backgroundColor: AppColors.slate100,
                checkmarkColor: AppColors.brand700,
                labelStyle: TextStyle(
                  color: selected.contains(o) ? AppColors.brand700 : SoftColors.muted,
                  fontWeight: selected.contains(o) ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}

class _CheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: AppColors.brand500),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(label, style: const TextStyle(fontSize: 13, color: SoftColors.ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

