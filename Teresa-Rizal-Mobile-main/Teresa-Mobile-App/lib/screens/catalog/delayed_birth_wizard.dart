import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';
import '../../data/catalog_dates.dart';
import '../../utils/age_calculator.dart';
import '../../widgets/form/barangay_picker.dart';
import '../../widgets/form/soft_form_fields.dart';
import 'catalog_chrome.dart';
import 'remove_requirement_dialog.dart';

enum BirthPlace { hospital, clinic, home, other }

class DelayedBirthWizard extends StatefulWidget {
  final int initialStep;
  final bool focusFather;
  final bool showLastNameError;
  final bool showRemoveDialog;
  final String? affidavitFile;
  final String? attendantFile;

  const DelayedBirthWizard({
    super.key,
    this.initialStep = 0,
    this.focusFather = false,
    this.showLastNameError = false,
    this.showRemoveDialog = false,
    this.affidavitFile,
    this.attendantFile,
  });

  @override
  State<DelayedBirthWizard> createState() => _DelayedBirthWizardState();
}

class _DelayedBirthWizardState extends State<DelayedBirthWizard> {
  late int _step;
  String _whose = 'My child';
  final _first = TextEditingController(text: 'Angelo');
  final _middle = TextEditingController();
  final _last = TextEditingController(text: 'Mercado');
  final _mother = TextEditingController(text: 'Rosario Diaz Mercado');
  final _father = TextEditingController(text: 'Mateo Cruz Villanueva');
  final _address = TextEditingController(text: 'Purok 5');
  final _firstNode = FocusNode();
  final _middleNode = FocusNode();
  final _lastNode = FocusNode();
  final _motherNode = FocusNode();
  final _fatherNode = FocusNode();
  final _addressNode = FocusNode();
  DateTime? _dob = DateTime(2019, 6, 21);
  String? _sex = 'Male';
  bool _married = false;
  bool _ack = true;
  String? _lastError;
  BirthPlace _place = BirthPlace.home;
  String _barangay = 'May-Iba';
  String _attendant = 'Midwife';
  String _birthType = 'Single';
  String? _affidavitFile;
  String? _attendantFile;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _affidavitFile = widget.affidavitFile;
    _attendantFile = widget.attendantFile;
    if (widget.showLastNameError) {
      _last.text = '';
      _lastError = 'Enter the child\'s last name';
      WidgetsBinding.instance.addPostFrameCallback((_) => _lastNode.requestFocus());
    }
    if (widget.focusFather) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fatherNode.requestFocus());
    }
    if (widget.showRemoveDialog) {
      _affidavitFile ??= ServiceCatalogMock.affidavitFileName;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setAck(false));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _mother, _father, _address]) {
      c.dispose();
    }
    for (final n in [_firstNode, _middleNode, _lastNode, _motherNode, _fatherNode, _addressNode]) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _setAck(bool yes) async {
    if (!yes && _ack && _affidavitFile != null) {
      setState(() => _ack = false);
      final remove = await showRemoveRequirementDialog(context, RemoveRequirementCopy.affidavit);
      if (!mounted) return;
      setState(() {
        if (remove) {
          _ack = false;
          _father.clear();
          _affidavitFile = null;
        } else {
          _ack = true;
        }
      });
      return;
    }
    setState(() {
      _ack = yes;
      if (!yes) _father.clear();
    });
  }

  Future<void> _setPlace(BirthPlace place) async {
    if (_place == BirthPlace.home && place != BirthPlace.home && _attendantFile != null) {
      setState(() => _place = place);
      final remove = await showRemoveRequirementDialog(context, RemoveRequirementCopy.attendant);
      if (!mounted) return;
      setState(() {
        if (remove) {
          _place = place;
          _attendantFile = null;
        } else {
          _place = BirthPlace.home;
        }
      });
      return;
    }
    setState(() => _place = place);
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2019, 6, 21),
      firstDate: DateTime(1990),
      lastDate: DateTime(2026, 9, 24),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickBarangay() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await BarangayPicker.show(
      context,
      title: 'Barangay',
      selected: _barangay,
      selectedHint: 'Selected',
    );
    if (picked != null) setState(() => _barangay = picked);
  }

  void _continue() {
    if (_step == 1 && _last.text.trim().isEmpty) {
      setState(() => _lastError = 'Enter the child\'s last name');
      _lastNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _lastNode.context;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }
    if (_step >= 4) return;
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _intro();
    return CatalogPage(
      title: ServiceCatalogMock.dokyu
          .firstWhere((service) => service.delayedBirth)
          .appBarTitle,
      pinned: [
        WizardHead(
          step: _step,
          label: ServiceCatalogMock.wizardSteps[_step - 1].label,
        ),
      ],
      footer: DualFooter(
        onBack: () => setState(() => _step -= 1),
        onNext: _step == 4 && _missingFiles > 0 ? null : _continue,
      ),
      body: ListView(
        key: const Key('wizard-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          if (_step == 1) ..._registrant(),
          if (_step == 2) ..._parents(),
          if (_step == 3) ..._birth(),
          if (_step == 4) ..._requirements(),
        ],
      ),
    );
  }

  int get _missingFiles {
    var missing = 1;
    if (_ack) missing += 1;
    if (_place == BirthPlace.home) missing += 1;
    return missing;
  }

  Widget _intro() {
    return CatalogPage(
      title: ServiceCatalogMock.dokyu
          .firstWhere((service) => service.delayedBirth)
          .appBarTitle,
      footer: DualFooter(
        back: 'Not now',
        next: 'Start · Hakbang 1',
        onBack: () => Navigator.of(context).maybePop(),
        onNext: () => setState(() => _step = 1),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          const Text('Before you start', style: SoftType.h1),
          const SizedBox(height: 8),
          const Text(ServiceCatalogMock.wizardSavedLine, style: CatalogType.note),
          const SizedBox(height: 12),
          for (final step in ServiceCatalogMock.wizardSteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Hakbang ${step.number} · ${step.label}${step.conditional ? ' · Conditional' : ''}',
                style: CatalogType.note,
              ),
            ),
          const HonestyNote(text: ServiceCatalogMock.wizardIntroHonesty),
        ],
      ),
    );
  }

  List<Widget> _registrant() {
    final age = _dob == null ? null : calculateAge(_dob!, asOf: DateTime(2026, 9, 24));
    return [
      const Text('Whose birth is this?', style: SoftType.h1),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final who in ['My child', 'Myself', 'Someone else'])
            ChoiceChip(
              label: Text(who),
              selected: _whose == who,
              onSelected: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _whose = who);
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      SoftFormField(
        label: 'First name',
        controller: _first,
        focusNode: _firstNode,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _middleNode.requestFocus(),
      ),
      SoftFormField(
        label: 'Middle name · optional',
        controller: _middle,
        focusNode: _middleNode,
        hint: 'Leave blank if none',
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _lastNode.requestFocus(),
      ),
      SoftFormField(
        fieldKey: const Key('child-last-name'),
        label: 'Last name',
        controller: _last,
        focusNode: _lastNode,
        error: _lastError,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_lastError != null) setState(() => _lastError = null);
        },
        onSubmitted: (_) => _pickDate(),
      ),
      const Text('Date of birth', style: CatalogType.fieldLabel),
      const SizedBox(height: 6),
      Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        child: InkWell(
          key: const Key('child-dob'),
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.md),
              border: Border.all(color: SoftColors.line, width: 1.5),
            ),
            child: Text(
              _dob == null ? 'Select a date' : formatCatalogDate(_dob!),
              style: CatalogType.field,
            ),
          ),
        ),
      ),
      if (age != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Age $age · more than 30 days after birth, so this is a delayed registration',
            style: CatalogType.helper,
          ),
        ),
      const SizedBox(height: 12),
      const Text('Sex', style: CatalogType.fieldLabel),
      Wrap(
        spacing: 8,
        children: [
          for (final sex in ['Male', 'Female', 'Prefer not'])
            ChoiceChip(
              label: Text(sex),
              selected: _sex == sex,
              onSelected: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _sex = sex);
              },
            ),
        ],
      ),
      const HonestyNote(text: ServiceCatalogMock.h1Honesty),
    ];
  }

  List<Widget> _parents() {
    return [
      SoftFormField(
        label: 'Mother\'s full maiden name',
        controller: _mother,
        focusNode: _motherNode,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) {
          if (!_married && _ack) {
            _fatherNode.requestFocus();
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
      ),
      const Text(
        'Were the parents married to each other when the child was born?',
        style: SoftType.h1,
      ),
      const SizedBox(height: 8),
      YesNoTiles(
        label: '',
        value: _married,
        onChanged: (yes) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _married = yes);
        },
      ),
      if (!_married) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SoftColors.blueWash,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: const Border(left: BorderSide(color: SoftColors.blue, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '+ SHOWN BECAUSE PARENTS WERE NOT MARRIED',
                style: CatalogType.revealEyebrow,
              ),
              const SizedBox(height: 8),
              YesNoTiles(
                label: 'Does the father acknowledge the child?',
                value: _ack,
                onChanged: (yes) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _setAck(yes);
                },
              ),
              if (_ack) ...[
                const SizedBox(height: 8),
                SoftFormField(
                  fieldKey: const Key('father-name-field'),
                  label: 'Father\'s full name',
                  controller: _father,
                  focusNode: _fatherNode,
                  helper: 'As written on the Affidavit of Acknowledgment',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
                const Text(ServiceCatalogMock.paternityNote, style: CatalogType.note),
              ],
            ],
          ),
        ),
      ],
      const HonestyNote(text: ServiceCatalogMock.parentsRule),
    ];
  }

  List<Widget> _birth() {
    return [
      const Text('Where was the child born?', style: SoftType.h1),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final place in BirthPlace.values)
            ChoiceChip(
              label: Text(_placeLabel(place)),
              selected: _place == place,
              onSelected: (_) => _setPlace(place),
            ),
        ],
      ),
      if (_place == BirthPlace.home) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SoftColors.blueWash,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: const Border(left: BorderSide(color: SoftColors.blue, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('+ SHOWN BECAUSE YOU PICKED HOME', style: CatalogType.revealEyebrow),
              SoftFormField(
                label: 'House address at the time',
                controller: _address,
                focusNode: _addressNode,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _pickBarangay(),
              ),
              const Text('Barangay', style: CatalogType.fieldLabel),
              InkWell(
                key: const Key('h3-barangay'),
                onTap: _pickBarangay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(_barangay, style: CatalogType.field),
                ),
              ),
              const Text('Town', style: CatalogType.fieldLabel),
              const Text('Teresa, Rizal', style: CatalogType.field),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(ServiceCatalogMock.attendantNote, style: CatalogType.note),
        ),
      ],
      const SizedBox(height: 8),
      const Text('Who attended the birth?', style: CatalogType.fieldLabel),
      Wrap(
        spacing: 8,
        children: [
          for (final who in ['Physician', 'Nurse', 'Midwife', 'Traditional attendant (hilot)', 'None'])
            ChoiceChip(
              label: Text(who),
              selected: _attendant == who,
              onSelected: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _attendant = who);
              },
            ),
        ],
      ),
      const Text('Type of birth', style: CatalogType.fieldLabel),
      Wrap(
        spacing: 8,
        children: [
          for (final kind in ['Single', 'Twin', 'Triplet or more'])
            ChoiceChip(
              label: Text(kind),
              selected: _birthType == kind,
              onSelected: (_) => setState(() => _birthType = kind),
            ),
        ],
      ),
    ];
  }

  List<Widget> _requirements() {
    final extra = <RequirementSpec>[
      if (_ack) ServiceCatalogMock.affidavitRequirement,
      if (_place == BirthPlace.home) ServiceCatalogMock.attendantRequirement,
    ];
    final all = [
      ServiceCatalogMock.baseRequirements[0],
      ServiceCatalogMock.baseRequirements[1],
      ...extra,
      ServiceCatalogMock.baseRequirements[2],
    ];
    return [
      const Text('Supporting documents', style: SoftType.h1),
      Text(ServiceCatalogMock.h4Progress, style: CatalogType.meta),
      for (final item in all)
        Container(
          key: Key('req-${item.id}'),
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.conditional ? SoftColors.goldSoft : SoftColors.white,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(color: item.conditional ? SoftColors.gold : SoftColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: CatalogType.tileTitle),
              if (item.detail.isNotEmpty) Text(item.detail, style: CatalogType.meta),
              if (item.fromHakbang.isNotEmpty)
                Text(item.fromHakbang, style: CatalogType.sample),
            ],
          ),
        ),
      const HonestyNote(text: ServiceCatalogMock.h4Honesty),
    ];
  }

  String _placeLabel(BirthPlace place) => switch (place) {
        BirthPlace.hospital => 'Hospital',
        BirthPlace.clinic => 'Lying-in or clinic',
        BirthPlace.home => 'Home',
        BirthPlace.other => 'Other',
      };
}
