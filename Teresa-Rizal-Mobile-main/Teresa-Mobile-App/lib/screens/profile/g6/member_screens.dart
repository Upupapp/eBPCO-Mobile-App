import 'package:flutter/material.dart';
import '../../../theme/g6_tokens.dart';

import '../../../models/service_request.dart';
import '../../../services/mock_catalog.dart';
import '../../../theme/soft_widget.dart';
import '../../shared/service_catalog_screen.dart';
import 'g6_chrome.dart';
import 'g6_filing.dart';
import 'g6_sample.dart';

const _relationships = [
  'Spouse',
  'Child',
  'Parent',
  'Sibling',
  'Grandparent',
  'Other',
];
const _sexes = ['Male', 'Female', 'Prefer not'];

/// Member detail. Household members do not get a Digital ID card.
class G6MemberDetailScreen extends StatelessWidget {
  final G6Member member;
  const G6MemberDetailScreen({super.key, required this.member});

  Future<void> _newRequest(BuildContext context) async {
    G6FilingContext.memberName = member.name;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceCatalogScreen(
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          catalog: MockCatalog.documentTypes,
          accent: SoftColors.blue,
        ),
      ),
    );
    G6FilingContext.memberName = null;
  }

  Future<void> _remove(BuildContext context) async {
    final ok = await showG6RemoveMember(context, member);
    if (ok && context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<G6Member>(
      MaterialPageRoute(builder: (_) => G6AddMemberScreen(existing: member)),
    );
    if (updated != null && context.mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = member.verify == G6Verify.pending;
    return G6Shell(
      title: 'Family member',
      footer: G6DualFooter(
        left: G6Button(
          label: 'Remove',
          kind: G6ButtonKind.dangerSoft,
          icon: Icons.delete_outline_rounded,
          onPressed: () => _remove(context),
        ),
        right: G6Button(
          label: pending ? 'Edit details' : 'Edit',
          kind: pending ? G6ButtonKind.outline : G6ButtonKind.blue,
          icon: Icons.edit_outlined,
          onPressed: () => _edit(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(
            children: [
              G6Initials(
                initials: member.initials,
                tone: member.tone,
                size: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reyes household · Dalig',
                      style: SoftType.eyebrow,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.name,
                      style: SoftType.h1.copyWith(fontSize: G6Type.px20),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        G6KindChip(member.relationship),
                        G6VerifyChip(
                          verify: member.verify,
                          label: pending ? 'Pending verification' : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: G6Palette.cream,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for review',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px14,
                      fontWeight: FontWeight.w500,
                      color: G6Palette.goldInk,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'A records officer checks the birth certificate you attached. Timing shown is a sample.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px12,
                      height: 1.42,
                      color: SoftColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const _PendingRail(),
            const SizedBox(height: 10),
            _Facts(
              rows: [
                _Fact('Birth date', member.birthLabel, sub: member.ageLabel),
                _Fact('Sex', member.sex),
                _Fact(
                  'Document',
                  member.documentLabel ?? 'Birth certificate',
                  sub: 'Attached · local only',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: SoftColors.chipWash,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
              ),
              child: Opacity(
                opacity: 0.55,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SoftColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: SoftColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requests for ${member.firstName}',
                            style: SoftType.name,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Available after verification',
                            style: SoftType.cellLabel,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const G6Honesty(
              lead: 'Simulated review.',
              rest: 'No live LGU officer queue or civil registry check.',
              compact: true,
            ),
          ] else ...[
            const SizedBox(height: 14),
            _Facts(
              rows: [
                _Fact('Relationship', member.relationship),
                _Fact('Birth date', member.birthLabel, sub: member.ageLabel),
                _Fact('Sex', member.sex),
                if (member.civilStatus != null)
                  _Fact('Civil status', member.civilStatus!),
                if (member.mobile != null) _Fact('Mobile', member.mobile!),
              ],
            ),
            if (member.verified) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'New request for ${member.firstName}',
                    style: SoftType.cellValue.copyWith(fontSize: G6Type.px14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              G6Button(
                label: 'New request for ${member.firstName}',
                icon: Icons.description_outlined,
                onPressed: () => _newRequest(context),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: SoftColors.chipWash,
                  borderRadius: BorderRadius.circular(SoftRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: SoftColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Requests for ${member.firstName} unlock after verification',
                        style: SoftType.cellLabel.copyWith(
                          fontSize: G6Type.px13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (member.verified) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SoftColors.blueWash,
                  borderRadius: BorderRadius.circular(SoftRadius.md),
                  border: Border.all(color: SoftColors.line),
                ),
                child: const Row(
                  children: [
                    _DocIcon(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PhilSys ID · front', style: SoftType.name),
                          SizedBox(height: 2),
                          Text(
                            'On file · added Sep 12 · local only',
                            style: SoftType.cellLabel,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!member.minor)
              G6Honesty(
                lead: '${member.firstName} is 18+.',
                rest:
                    '${member.sex == 'Female' ? 'She' : 'He'} can create ${member.sex == 'Female' ? 'her' : 'his'} own Teresa, Rizal account to get ${member.sex == 'Female' ? 'her' : 'his'} own Digital ID. Sample record, frontend simulation.',
              ),
          ],
        ],
      ),
    );
  }
}

class _DocIcon extends StatelessWidget {
  const _DocIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: SoftShadows.cardSm,
      ),
      child: const Icon(Icons.badge_outlined, size: 18, color: SoftColors.blue),
    );
  }
}

class _PendingRail extends StatelessWidget {
  const _PendingRail();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Added by you', 'Sep 25 · 3:40 AM', 0),
      ('Under review', 'Usually 1–3 working days · sample', 1),
      ('Verified', 'Requests for Paolo unlock', 2),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? SoftColors.verifiedInk
                              : (i == 1
                                    ? SoftColors.gold
                                    : SoftColors.toggleTrack),
                          boxShadow: [
                            BoxShadow(
                              color: i == 0
                                  ? SoftColors.verifiedSoft
                                  : (i == 1
                                        ? G6Palette.cream
                                        : SoftColors.chipWash),
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(width: 2, height: 28, color: SoftColors.line),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$1,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px13,
                            fontWeight: FontWeight.w500,
                            color: i == 1
                                ? SoftColors.endedInk
                                : (i == 2 ? SoftColors.muted : SoftColors.ink),
                          ),
                        ),
                        Text(steps[i].$2, style: SoftType.cellLabel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Fact {
  final String label;
  final String value;
  final String? sub;
  const _Fact(this.label, this.value, {this.sub});
}

class _Facts extends StatelessWidget {
  final List<_Fact> rows;
  const _Facts({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: SoftColors.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px13,
                      color: SoftColors.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rows[i].value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px13,
                            fontWeight: FontWeight.w500,
                            color: SoftColors.ink,
                          ),
                        ),
                        if (rows[i].sub != null)
                          Text(rows[i].sub!, style: SoftType.cellLabel),
                      ],
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

/// Full-height push. Not a bottom sheet.
class G6AddMemberScreen extends StatefulWidget {
  final G6Member? existing;

  /// Comp frame: focused name, harness keypad, footer above the IME.
  final bool keyboardFrame;

  /// Evidence caption above the footer. Off for the live screen and the
  /// keyboard layout test, which measures the name-to-footer gap.
  final bool keyboardCaption;

  const G6AddMemberScreen({
    super.key,
    this.existing,
    this.keyboardFrame = false,
    this.keyboardCaption = false,
  });

  @override
  State<G6AddMemberScreen> createState() => _G6AddMemberScreenState();
}

class _G6AddMemberScreenState extends State<G6AddMemberScreen> {
  late String _relationship = widget.existing?.relationshipToYou ?? 'Child';
  late String _sex = widget.existing?.sex ?? 'Male';
  late final TextEditingController _name = TextEditingController(
    text: widget.keyboardFrame
        ? 'Paolo Santos'
        : (widget.existing?.name ?? 'Paolo Santos Reyes'),
  );
  final FocusNode _nameFocus = FocusNode();
  late DateTime? _birth = widget.keyboardFrame ? null : DateTime(2018, 3, 3);
  int _step = 0;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool _openingBirth = false;

  /// `next` on Full name closes the IME and opens the birth-date picker.
  /// It does not advance the wizard. `onEditingComplete` and `onSubmitted`
  /// both fire for `TextInputAction.next`; the flag keeps that to one picker.
  Future<void> _nextToBirth() async {
    if (_openingBirth) return;
    _openingBirth = true;
    FocusManager.instance.primaryFocus?.unfocus();
    await _pickDate();
    _openingBirth = false;
  }

  String _birthLabel() {
    final birth = _birth;
    if (birth == null) return 'DD Mon YYYY';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = birth.day.toString().padLeft(2, '0');
    return '$dd ${months[birth.month - 1]} ${birth.year}';
  }

  String? _ageHint() {
    final birth = _birth;
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    if (age < 0) age = 0;
    if (age < 18) return 'Age $age · minor, listed under your household';
    return 'Age $age · adult, can create their own Teresa, Rizal account';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(2018, 3, 3),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  void _save() {
    final name = _name.text.trim().isEmpty ? 'New member' : _name.text.trim();
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    final now = DateTime.now();
    var age = 0;
    if (_birth != null) {
      age = now.year - _birth!.year;
      if (now.month < _birth!.month ||
          (now.month == _birth!.month && now.day < _birth!.day)) {
        age--;
      }
    }
    Navigator.of(context).pop(
      G6Member(
        id:
            widget.existing?.id ??
            'g6-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        initials: initials.isEmpty ? 'NM' : initials,
        relationship: _relationship == 'Child' ? 'Child' : _relationship,
        relationshipToYou: _relationship,
        age: age,
        verify: G6Verify.pending,
        tone: G6AvatarTone.gold,
        birthLabel: _birthLabel(),
        ageLabel: age < 18 ? '$age yrs · minor' : '$age yrs',
        sex: _sex,
        minor: age < 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return G6Shell(
      title: editing ? 'Edit member' : 'Add member',
      liftFooterWithInset: true,
      pinned: _PinnedHead(step: _step),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.keyboardCaption)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: G6Annotation(
                'Keyboard DoD: focused Full name and the Back | Continue footer sit above the IME. Page scrolls so the active field stays visible; Sex and ID upload scroll below.',
              ),
            ),
          Padding(
            key: const ValueKey('g6-member-footer'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: G6Button(
                    label: 'Back',
                    kind: G6ButtonKind.outline,
                    onPressed: () {
                      if (_step == 1) {
                        setState(() => _step = 0);
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: G6Button(
                    label: _step == 0 ? 'Continue' : 'Save member',
                    onPressed: () {
                      if (_step == 0) {
                        setState(() => _step = 1);
                      } else {
                        _save();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _step == 1 ? _review() : _details(editing),
        ),
      ),
    );
  }

  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing != null ? 'Edit member' : 'Add a family member',
          style: SoftType.h1.copyWith(fontSize: G6Type.px21),
        ),
        const SizedBox(height: 12),
        _Facts(
          rows: [
            _Fact('Relationship', _relationship),
            _Fact('Full name', _name.text.trim()),
            _Fact('Birth date', _birthLabel()),
            _Fact('Sex', _sex),
          ],
        ),
        const G6Honesty(
          lead: 'Frontend simulation.',
          rest: 'Not sent to the civil registry or CBMS.',
          compact: true,
        ),
      ],
    );
  }

  Widget _details(bool editing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          editing ? 'Edit member' : 'Add a family member',
          style: SoftType.h1.copyWith(fontSize: G6Type.px21, height: 1.1),
        ),
        const SizedBox(height: 6),
        const _FieldLabel('Relationship to you'),
        _RelationshipGrid(
          selected: _relationship,
          names: _relationships,
          onSelected: (value) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _relationship = value);
          },
        ),
        const SizedBox(height: 6),
        const _FieldLabel('Full name'),
        TextField(
          key: const ValueKey('g6-member-name'),
          controller: _name,
          focusNode: _nameFocus,
          autofocus: widget.keyboardFrame,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.all(20),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px14,
            color: SoftColors.ink,
          ),
          cursorColor: SoftColors.blue,
          onEditingComplete: _nextToBirth,
          onSubmitted: (_) => _nextToBirth(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            filled: true,
            fillColor: SoftColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SoftColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SoftColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SoftColors.blue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _FieldLabel('Birth date'),
        GestureDetector(
          key: const ValueKey('g6-member-birth'),
          onTap: _nextToBirth,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: SoftColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SoftColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _birthLabel(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px14,
                      color: _birth == null ? SoftColors.muted : SoftColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: SoftColors.muted,
                ),
              ],
            ),
          ),
        ),
        if (_ageHint() != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _ageHint()!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px11,
                color: SoftColors.blueDeep,
              ),
            ),
          ),
        const SizedBox(height: 12),
        const _FieldLabel('Sex'),
        Row(
          children: [
            for (final sex in _sexes) ...[
              if (sex != _sexes.first) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _sex = sex);
                  },
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _sex == sex ? SoftColors.blue : SoftColors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _sex == sex ? SoftColors.blue : SoftColors.line,
                      ),
                    ),
                    child: Text(
                      sex,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px12,
                        fontWeight: FontWeight.w500,
                        color: _sex == sex
                            ? SoftColors.white
                            : SoftColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px12,
              fontWeight: FontWeight.w500,
              color: SoftColors.ink,
            ),
            children: [
              TextSpan(text: 'Birth certificate or valid ID '),
              TextSpan(
                text: '· optional',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: SoftColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const _UploadTile(),
        const G6Honesty(
          lead: 'Frontend simulation.',
          rest: 'Not sent to the civil registry or CBMS.',
          compact: true,
        ),
      ],
    );
  }
}

class _PinnedHead extends StatelessWidget {
  final int step;
  const _PinnedHead({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('g6-member-pinned-head'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: step == 0 ? 0.5 : 1,
                    minHeight: 4,
                    backgroundColor: SoftColors.line,
                    color: SoftColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                step == 0 ? '1 / 2' : '2 / 2',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px12,
                  fontWeight: FontWeight.w500,
                  color: SoftColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step == 0 ? 'Hakbang 1 · Member details' : 'Hakbang 2 · Review',
            style: SoftType.eyebrow,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: G6Type.px12,
          fontWeight: FontWeight.w500,
          color: SoftColors.ink,
        ),
      ),
    );
  }
}

class _RelationshipGrid extends StatelessWidget {
  final String selected;
  final List<String> names;
  final ValueChanged<String> onSelected;
  const _RelationshipGrid({
    required this.selected,
    required this.names,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 65.5,
      ),
      children: [
        for (final name in names)
          _RelTile(
            label: name,
            selected: selected == name,
            icon: switch (name) {
              'Spouse' => Icons.favorite_border_rounded,
              'Child' => Icons.child_care_outlined,
              'Parent' => Icons.person_outline_rounded,
              'Sibling' => Icons.people_outline_rounded,
              'Grandparent' => Icons.person_add_alt_1_outlined,
              _ => Icons.more_horiz_rounded,
            },
            onTap: () => onSelected(name),
          ),
      ],
    );
  }
}

class _RelTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RelTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blueWash : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? SoftColors.blue : SoftColors.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px11,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                      color: selected ? SoftColors.blueDeep : SoftColors.ink,
                    ),
                  ),
                ],
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SoftColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: SoftColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile();

  @override
  Widget build(BuildContext context) {
    return G6DashedBox(
      radius: 16,
      fill: SoftColors.blueWash,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: SoftColors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.upload_rounded,
                      size: 16,
                      color: SoftColors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attach a document', style: SoftType.name),
                      SizedBox(height: 1),
                      Text(
                        'Speeds up verification · stays on this device',
                        style: SoftType.cellLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Source('Camera', Icons.photo_camera_outlined)),
                SizedBox(width: 6),
                Expanded(child: _Source('Gallery', Icons.image_outlined)),
                SizedBox(width: 6),
                Expanded(child: _Source('File', Icons.description_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Source extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Source(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SoftColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: SoftColors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px12,
              fontWeight: FontWeight.w500,
              color: SoftColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showG6RemoveMember(BuildContext context, G6Member member) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    builder: (context) => G6RemoveSheet(member: member),
  ).then((value) => value ?? false);
}

class G6RemoveSheet extends StatelessWidget {
  final G6Member member;
  const G6RemoveSheet({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: SoftColors.toggleTrack,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SoftColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_remove_outlined,
              color: SoftColors.danger,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Remove ${member.name}?',
            textAlign: TextAlign.center,
            style: SoftType.pageTitle.copyWith(fontSize: G6Type.px17),
          ),
          const SizedBox(height: 6),
          Text(
            '${member.sex == 'Female' ? 'She' : 'He'} will be removed from the Reyes household on this device. Requests you already filed for ${member.sex == 'Female' ? 'her' : 'him'} stay in My requests.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px13,
              height: 1.4,
              color: SoftColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SoftColors.blueWash,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              border: Border.all(color: SoftColors.line),
            ),
            child: Row(
              children: [
                G6Initials(
                  initials: member.initials,
                  tone: member.tone,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: SoftType.name),
                      Text(
                        '${member.relationship} · ${member.age} yrs · ${member.verifyLabel}',
                        style: SoftType.cellLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          G6Honesty(
            lead: 'Local preview.',
            rest:
                "Only this device's sample household changes. No civil registry or CBMS record is touched. If ${member.sex == 'Female' ? 'she' : 'he'} moved out, ${member.sex == 'Female' ? 'she' : 'he'} can create ${member.sex == 'Female' ? 'her' : 'his'} own account.",
            tone: G6HonestyTone.danger,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: G6Button(
                  label: 'Keep member',
                  kind: G6ButtonKind.outline,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: G6Button(
                  label: 'Remove',
                  kind: G6ButtonKind.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
