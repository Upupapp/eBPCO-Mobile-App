import 'package:flutter/material.dart';
import '../../../models/resident_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_date_field.dart';
import '../../../widgets/app_text_field.dart';

/// Add/edit sheet for one family member. Deliberately lighter than the
/// citizen's own Personal Information step (Section 4: "Full Name" as one
/// field, not first/middle/last) — children, seniors, and residents
/// without an Teresa, Rizal account must be fully representable here, so
/// "Has Teresa, Rizal Account?" defaults to No and is never required to be
/// Yes. Keyboard-safe layout: fixed header, scrollable middle, pinned
/// footer button.
class FamilyMemberFormSheet extends StatefulWidget {
  final Individual? existing;
  const FamilyMemberFormSheet({super.key, this.existing});

  @override
  State<FamilyMemberFormSheet> createState() => _FamilyMemberFormSheetState();
}

class _FamilyMemberFormSheetState extends State<FamilyMemberFormSheet> {
  late final TextEditingController _fullName;
  late final TextEditingController _occupation;
  String? _relationship;
  String? _sex;
  String? _civilStatus;
  DateTime? _birthdate;
  bool _hasAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fullName = TextEditingController(text: e?.firstName ?? '');
    _occupation = TextEditingController(text: e?.occupation ?? '');
    _relationship = (e?.relationshipToHead.isEmpty ?? true) ? null : e!.relationshipToHead;
    _sex = (e?.sex.isEmpty ?? true) ? null : e!.sex;
    _civilStatus = (e?.civilStatus.isEmpty ?? true) ? null : e!.civilStatus;
    _birthdate = e?.birthdate;
    _hasAccount = e?.hasTeresaRizalAccount ?? false;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _occupation.dispose();
    super.dispose();
  }

  void _submit() {
    if (_fullName.text.trim().isEmpty) {
      setState(() => _error = "Please enter the family member's name.");
      return;
    }
    if (_relationship == null) {
      setState(() => _error = 'Please select their relationship to the head of family.');
      return;
    }
    final result = Individual(
      individualId: widget.existing?.individualId ?? 'IND-${DateTime.now().microsecondsSinceEpoch}',
      firstName: _fullName.text.trim(),
      sex: _sex ?? '',
      birthdate: _birthdate,
      civilStatus: _civilStatus ?? '',
      occupation: _occupation.text.trim(),
      relationshipToHead: _relationship!,
      hasTeresaRizalAccount: _hasAccount,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(999)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.existing == null ? 'Add Family Member' : 'Edit Family Member',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(label: 'Full name', controller: _fullName, icon: Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                        AppSelectField<String>(
                          label: 'Relationship to Head of Family',
                          value: _relationship,
                          options: ResidentProfileOptions.relationshipToHead,
                          labelBuilder: (v) => v,
                          onChanged: (v) => setState(() => _relationship = v),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppSelectField<String>(
                                label: 'Sex',
                                value: _sex,
                                options: ResidentProfileOptions.sex,
                                labelBuilder: (v) => v,
                                onChanged: (v) => setState(() => _sex = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppDateField(
                                label: 'Birthdate',
                                value: _birthdate,
                                onChanged: (d) => setState(() => _birthdate = d),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppSelectField<String>(
                          label: 'Civil status',
                          value: _civilStatus,
                          options: ResidentProfileOptions.civilStatus,
                          labelBuilder: (v) => v,
                          onChanged: (v) => setState(() => _civilStatus = v),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(label: 'Occupation', controller: _occupation, icon: Icons.work_outline_rounded),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Has Teresa, Rizal Account?',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _hasAccount,
                                onChanged: (v) => setState(() => _hasAccount = v),
                                activeThumbColor: AppColors.brand500,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'It\'s okay if they don\'t have one — children, seniors, and dependents can still be added.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AppButton(
                    label: widget.existing == null ? 'Add Member' : 'Save Changes',
                    icon: Icons.check_rounded,
                    fullWidth: true,
                    size: AppButtonSize.lg,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
