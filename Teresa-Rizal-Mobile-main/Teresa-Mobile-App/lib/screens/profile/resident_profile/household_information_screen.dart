import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';

/// Step 3 — Household Information. Maps to Web Admin Constituents >
/// Households. "Number of People" / "Number of Families" are shown as
/// read-only summaries derived from Family Information rather than
/// re-typed here — asking the citizen to manually keep a count in sync
/// with the family members they already entered would just invite drift.
class HouseholdInformationScreen extends StatefulWidget {
  const HouseholdInformationScreen({super.key});

  @override
  State<HouseholdInformationScreen> createState() => _HouseholdInformationScreenState();
}

class _HouseholdInformationScreenState extends State<HouseholdInformationScreen> {
  late final Household _original;
  late final String _accountId;
  late final TextEditingController _sitioPurok;
  late final TextEditingController _completeAddress;
  late final TextEditingController _numberOfRooms;
  String? _barangay;
  String? _housingOwnership;
  String? _housingType;
  String? _waterSource;
  String? _toiletFacility;
  String? _electricitySource;
  bool _hasInternet = false;
  bool _saving = false;
  String? _error;

  ResidentProfileService get _service => context.read<ResidentProfileService>();

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account!;
    _accountId = account.id;
    _original = context.read<ResidentProfileService>().profileFor(account).household;
    _sitioPurok = TextEditingController(text: _original.sitioPurok);
    _completeAddress = TextEditingController(text: _original.completeAddress);
    _numberOfRooms = TextEditingController(text: _original.numberOfRooms > 0 ? '${_original.numberOfRooms}' : '');
    _barangay = _original.barangay.isEmpty ? null : _original.barangay;
    _housingOwnership = _original.housingOwnership.isEmpty ? null : _original.housingOwnership;
    _housingType = _original.housingType.isEmpty ? null : _original.housingType;
    _waterSource = _original.waterSource.isEmpty ? null : _original.waterSource;
    _toiletFacility = _original.toiletFacility.isEmpty ? null : _original.toiletFacility;
    _electricitySource = _original.electricitySource.isEmpty ? null : _original.electricitySource;
    _hasInternet = _original.hasInternetAccess;
  }

  @override
  void dispose() {
    _sitioPurok.dispose();
    _completeAddress.dispose();
    _numberOfRooms.dispose();
    super.dispose();
  }

  String? _missingFieldError() {
    if (_barangay == null) return 'Please select your barangay.';
    if (_sitioPurok.text.trim().isEmpty) return 'Please enter your Sitio / Purok.';
    if (_completeAddress.text.trim().isEmpty) return 'Please enter your complete address.';
    if (_housingOwnership == null) return 'Please select your housing ownership.';
    if (_housingType == null) return 'Please select your housing type.';
    if (_waterSource == null) return 'Please select your water source.';
    if (_toiletFacility == null) return 'Please select your toilet / sanitation facility.';
    if (_electricitySource == null) return 'Please select your electricity source.';
    return null;
  }

  Future<void> _save({required bool markComplete}) async {
    if (markComplete) {
      final err = _missingFieldError();
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final updated = Household(
      householdId: _original.householdId,
      barangay: _barangay ?? '',
      sitioPurok: _sitioPurok.text.trim(),
      completeAddress: _completeAddress.text.trim(),
      housingOwnership: _housingOwnership ?? '',
      housingType: _housingType ?? '',
      numberOfRooms: int.tryParse(_numberOfRooms.text.trim()) ?? 0,
      waterSource: _waterSource ?? '',
      toiletFacility: _toiletFacility ?? '',
      electricitySource: _electricitySource ?? '',
      hasInternetAccess: _hasInternet,
      familyIds: _original.familyIds,
      otherFamilies: _original.otherFamilies,
    );
    await context.read<ResidentProfileService>().saveHousehold(_accountId, updated, markComplete: markComplete);
    if (!mounted) return;
    setState(() => _saving = false);
    AppDialogs.toast(context, markComplete ? 'Household information saved.' : 'Saved for later.');
    Navigator.of(context).pop();
  }

  Future<void> _addOtherFamily() async {
    final result = await showModalBottomSheet<_OtherFamilyResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OtherFamilyFormSheet(),
    );
    if (result != null && mounted) {
      await _service.addOtherFamilyToHousehold(
        _accountId,
        result.familyName,
        headName: result.headName,
        members: result.members,
      );
    }
  }

  Future<void> _removeOtherFamily(String familyId) => _service.removeOtherFamilyFromHousehold(_accountId, familyId);

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ResidentProfileService>().profileFor(context.watch<CitizenSessionService>().account!);

    return Scaffold(
      appBar: AppBar(title: const Text('Household Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  'A household represents the people who live together at the same residence. This is different from a family — one household can contain more than one family.',
                  style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Location',
                children: [
                  AppSelectField<String>(
                    label: 'Barangay',
                    value: _barangay,
                    options: MockCatalog.barangays,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _barangay = v),
                  ),
                  AppTextField(label: 'Sitio / Purok', controller: _sitioPurok, icon: Icons.place_outlined),
                  AppTextField(label: 'Complete address', controller: _completeAddress, maxLines: 2),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Residence',
                children: [
                  AppSelectField<String>(
                    label: 'Housing ownership',
                    value: _housingOwnership,
                    options: ResidentProfileOptions.housingOwnership,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _housingOwnership = v),
                  ),
                  AppSelectField<String>(
                    label: 'Housing type / material',
                    value: _housingType,
                    options: ResidentProfileOptions.housingType,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _housingType = v),
                  ),
                  AppTextField(
                    label: 'Number of rooms',
                    controller: _numberOfRooms,
                    keyboardType: TextInputType.number,
                    icon: Icons.meeting_room_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Utilities / Services',
                children: [
                  AppSelectField<String>(
                    label: 'Water source',
                    value: _waterSource,
                    options: ResidentProfileOptions.waterSource,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _waterSource = v),
                  ),
                  AppSelectField<String>(
                    label: 'Toilet / sanitation',
                    value: _toiletFacility,
                    options: ResidentProfileOptions.toiletFacility,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _toiletFacility = v),
                  ),
                  AppSelectField<String>(
                    label: 'Electricity',
                    value: _electricitySource,
                    options: ResidentProfileOptions.electricitySource,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _electricitySource = v),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Internet Access',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.slate700),
                          ),
                        ),
                        Switch(
                          value: _hasInternet,
                          onChanged: (v) => setState(() => _hasInternet = v),
                          activeThumbColor: AppColors.brand500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Household Composition',
                description: 'Based on your Family Information — update that section to change these.',
                children: [
                  _CompositionRow(label: 'People living in household', value: '${profile.householdResidentCount}'),
                  _CompositionRow(label: 'Families living in household', value: '${profile.householdFamilyCount}'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // A household is the physical residence — this is where
              // *other* family groups sharing it belong, distinct from
              // Family Information (which is only the signed-in citizen's
              // own family). Moved here from Family Information.
              FormSection(
                title: 'Families in this Household',
                description: 'A household can include more than one family living together.',
                children: [
                  _FamilyChip(
                    name: profile.familyName.trim().isEmpty
                        ? '${context.watch<CitizenSessionService>().account!.lastName} Family'
                        : profile.familyName,
                    isOwn: true,
                  ),
                  for (final f in profile.household.otherFamilies)
                    _FamilyChip(
                      name: f.familyName,
                      headName: f.headName,
                      memberCount: f.members.length,
                      onRemove: () => _removeOtherFamily(f.familyId),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _addOtherFamily,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add Another Family'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Save & Continue',
                onPressed: () => _save(markComplete: true),
                loading: _saving,
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Save for Later',
                variant: AppButtonVariant.ghost,
                onPressed: _saving ? null : () => _save(markComplete: false),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompositionRow extends StatelessWidget {
  final String label;
  final String value;
  const _CompositionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// One family group living in this household — the citizen's own (never
/// removable, no head/member entry needed since that's already captured in
/// Family Information) or another family they've acknowledged, which can
/// optionally show who leads it and how many members it has.
class _FamilyChip extends StatelessWidget {
  final String name;
  final bool isOwn;
  final String? headName;
  final int memberCount;
  final VoidCallback? onRemove;
  const _FamilyChip({required this.name, this.isOwn = false, this.headName, this.memberCount = 0, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (headName != null && headName!.trim().isNotEmpty) 'Head: ${headName!.trim()}',
      if (memberCount > 0) '$memberCount member${memberCount == 1 ? '' : 's'}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: isOwn ? AppColors.brand50 : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.diversity_3_outlined, size: 17, color: isOwn ? AppColors.brand600 : AppColors.slate500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOwn ? AppColors.brand700 : AppColors.slate700,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Text(subtitleParts.join(' · '), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isOwn)
            // Flexible, not a bare Text: at a large system text scale this
            // trailing label cannot shrink and pushed the row past its width
            // (measured 2026-08-29 — 82px of overflow at 280pt/200%). Letting
            // it wrap keeps the chip intact without shrinking the type, which
            // would defeat the setting the citizen chose.
            const Flexible(
              child: Text(
                'Your family',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11, color: AppColors.brand600, fontWeight: FontWeight.w600),
              ),
            )
          else if (onRemove != null)
            IconButton(
              tooltip: 'Remove this family from the household',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.slate400),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _OtherFamilyResult {
  final String familyName;
  final String headName;
  final List<OtherFamilyMember> members;
  const _OtherFamilyResult({required this.familyName, required this.headName, required this.members});
}

/// Captures a household-mate family group beyond just its name — family
/// head and members, each with their relationship to that family's head —
/// per the household restructure's requirement that other families in the
/// household aren't just acknowledged by name but can record who's in
/// them. Deliberately lighter than [FamilyMemberFormSheet] (plain
/// name/relationship, no full Individual record): these are someone
/// else's family being noted for household-composition purposes, not
/// Individuals-table records the citizen is authoring.
class _OtherFamilyFormSheet extends StatefulWidget {
  const _OtherFamilyFormSheet();

  @override
  State<_OtherFamilyFormSheet> createState() => _OtherFamilyFormSheetState();
}

class _OtherFamilyFormSheetState extends State<_OtherFamilyFormSheet> {
  final _familyName = TextEditingController();
  final _headName = TextEditingController();
  final List<TextEditingController> _memberNames = [];
  final List<String?> _memberRelationships = [];
  String? _error;

  @override
  void dispose() {
    _familyName.dispose();
    _headName.dispose();
    for (final c in _memberNames) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberRow() {
    setState(() {
      _memberNames.add(TextEditingController());
      _memberRelationships.add(null);
    });
  }

  void _removeMemberRow(int i) {
    setState(() {
      _memberNames.removeAt(i).dispose();
      _memberRelationships.removeAt(i);
    });
  }

  void _submit() {
    if (_familyName.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a family name.');
      return;
    }
    final members = <OtherFamilyMember>[
      for (var i = 0; i < _memberNames.length; i++)
        if (_memberNames[i].text.trim().isNotEmpty)
          OtherFamilyMember(name: _memberNames[i].text.trim(), relationship: _memberRelationships[i] ?? ''),
    ];
    Navigator.of(
      context,
    ).pop(_OtherFamilyResult(familyName: _familyName.text.trim(), headName: _headName.text.trim(), members: members));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Another Family',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'A different family group living in this same household.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: 'Family name', controller: _familyName, icon: Icons.diversity_3_outlined),
                AppTextField(
                  label: 'Family head (optional)',
                  controller: _headName,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Family Members',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _memberNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            label: 'Name',
                            controller: _memberNames[i],
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 3,
                          child: AppSelectField<String>(
                            label: 'Relationship to head',
                            value: _memberRelationships[i],
                            options: ResidentProfileOptions.relationshipToHead,
                            labelBuilder: (v) => v,
                            onChanged: (v) => setState(() => _memberRelationships[i] = v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove member',
                          onPressed: () => _removeMemberRow(i),
                          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.rose500),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _addMemberRow,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                  label: const Text('Add Member'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(label: 'Add Family', onPressed: _submit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
