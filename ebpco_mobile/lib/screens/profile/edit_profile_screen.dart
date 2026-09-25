import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/castilla.dart';
import '../../services/session_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// `PATCH /me` — `null` clears a field, an omitted key leaves it alone,
/// same rule the web portal's `buildRectification` enforces. Only the
/// fields the server actually lets a citizen correct are editable here;
/// dateOfBirth/sex/civilStatus/nationality stay read-only, matching
/// `profile.page.ts`'s own "contact MEO to correct these four" notice.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _mobile;
  late final TextEditingController _street;
  late final TextEditingController _postal;
  String? _barangay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<SessionService>().profile;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _middleName = TextEditingController(text: p?.middleName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _mobile = TextEditingController(text: p?.mobileNumber ?? '');
    _street = TextEditingController(text: p?.street ?? '');
    _postal = TextEditingController(text: p?.postalCode ?? '');
    _barangay = p?.barangay;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _middleName, _lastName, _mobile, _street, _postal]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.patchMe({
        'firstName': _firstName.text.trim(),
        'middleName': _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
        'lastName': _lastName.text.trim(),
        'mobileNumber': _mobile.text.trim(),
        'street': _street.text.trim().isEmpty ? null : _street.text.trim(),
        if (_barangay != null) 'barangay': _barangay,
        'city': castillaCity,
        'province': castillaProvince,
        'postalCode': _postal.text.trim().isEmpty ? null : _postal.text.trim(),
      });
      if (!mounted) return;
      await context.read<SessionService>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.fieldLabel),
          const SizedBox(height: 6),
          TextField(controller: controller, keyboardType: keyboardType),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SessionService>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field('First Name', _firstName),
              _field('Middle Name', _middleName),
              _field('Last Name', _lastName),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email (cannot be changed)', style: AppTypography.fieldLabel),
                    const SizedBox(height: 6),
                    TextField(controller: TextEditingController(text: p?.email ?? ''), enabled: false),
                  ],
                ),
              ),
              _field('Mobile Number', _mobile, keyboardType: TextInputType.phone),
              _field('Street Address', _street),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barangay', style: AppTypography.fieldLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: castillaBarangays.contains(_barangay) ? _barangay : null,
                      isExpanded: true,
                      items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _barangay = v),
                    ),
                  ],
                ),
              ),
              _field('ZIP Code', _postal, keyboardType: TextInputType.number),
              if (_error != null) ...[
                Text(_error!, style: AppTypography.error),
                const SizedBox(height: AppSpacing.md),
              ],
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
