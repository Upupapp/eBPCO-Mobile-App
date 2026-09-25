import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';

/// "Update/request profile correction" from the Constituent flow (Section
/// 10). Since the Web Admin has no residents API to submit a correction
/// request against yet (see Section 8), this directly updates the local
/// mock profile rather than creating a separate "correction request" —
/// documented as a Web Admin alignment gap for later.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final CitizenAccount _original;
  late final TextEditingController _mobile;
  late final TextEditingController _occupation;
  late final TextEditingController _purok;
  late String _barangay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _original = context.read<CitizenSessionService>().account!;
    _mobile = TextEditingController(text: _original.mobile);
    _occupation = TextEditingController(text: _original.occupation == '—' ? '' : _original.occupation);
    _purok = TextEditingController(text: _original.purok == '—' ? '' : _original.purok);
    _barangay = _original.barangay;
  }

  @override
  void dispose() {
    _mobile.dispose();
    _occupation.dispose();
    _purok.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = CitizenAccount(
      id: _original.id,
      firstName: _original.firstName,
      lastName: _original.lastName,
      email: _original.email,
      mobile: _mobile.text.trim(),
      barangay: _barangay,
      purok: _purok.text.trim().isEmpty ? '—' : _purok.text.trim(),
      address: '${_purok.text.trim()}, Barangay $_barangay, Teresa, Rizal',
      birthdate: _original.birthdate,
      sex: _original.sex,
      civilStatus: _original.civilStatus,
      occupation: _occupation.text.trim().isEmpty ? '—' : _occupation.text.trim(),
      profileCompleteness: _computeCompleteness(),
      status: _original.status,
    );
    if (!mounted) return;
    await context.read<CitizenSessionService>().updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    AppDialogs.toast(context, 'Profile updated.');
    Navigator.of(context).pop();
  }

  int _computeCompleteness() {
    final fields = [_mobile.text, _occupation.text, _purok.text, _barangay];
    final filled = fields.where((f) => f.trim().isNotEmpty && f.trim() != '—').length;
    return (40 + (filled / fields.length * 60)).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Full name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(12)),
                child: Text(_original.fullName, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
              ),
              const _ReadOnlyNote(),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Mobile number',
                controller: _mobile,
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSelectField<String>(
                label: 'Barangay',
                value: _barangay,
                options: MockCatalog.barangays,
                labelBuilder: (b) => b,
                onChanged: (v) => setState(() => _barangay = v ?? _barangay),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Purok / Sitio', controller: _purok, icon: Icons.place_outlined),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Occupation', controller: _occupation, icon: Icons.work_outline_rounded),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Save Changes',
                onPressed: _save,
                loading: _saving,
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6),
      child: Text(
        'Name and Resident ID are locked — request a correction at your barangay hall if these are incorrect.',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }
}
