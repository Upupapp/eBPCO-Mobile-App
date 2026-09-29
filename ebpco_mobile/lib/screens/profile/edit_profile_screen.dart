import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/castilla.dart';
import '../../domain/lgu_contact.dart';
import '../../services/session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/message_bar.dart';

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

  /// The portal's `buildRectification`: only what changed is sent; a required
  /// field left blank is ignored, an emptied optional field is sent as null
  /// (clears it) only if something was there before.
  Map<String, dynamic> _buildPatch() {
    final p = context.read<SessionService>().profile;
    final patch = <String, dynamic>{};
    void required(String key, String next, String? before) {
      if (next.isNotEmpty && next != (before ?? '')) patch[key] = next;
    }

    void clearable(String key, String next, String? before) {
      if (next.isEmpty) {
        if (before != null && before.isNotEmpty) patch[key] = null;
      } else if (next != before) {
        patch[key] = next;
      }
    }

    required('firstName', _firstName.text.trim(), p?.firstName);
    required('lastName', _lastName.text.trim(), p?.lastName);
    required('mobileNumber', _mobile.text.trim(), p?.mobileNumber);
    clearable('middleName', _middleName.text.trim(), p?.middleName);
    clearable('street', _street.text.trim(), p?.street);
    clearable('barangay', _barangay ?? '', p?.barangay);
    clearable('city', castillaCity, p?.city);
    clearable('province', castillaProvince, p?.province);
    clearable('postalCode', _postal.text.trim(), p?.postalCode);
    return patch;
  }

  Future<void> _save() async {
    final patch = _buildPatch();
    final postal = patch['postalCode'];
    final mobile = patch['mobileNumber'];
    if (postal is String && !RegExp(r'^[0-9]{4}$').hasMatch(postal)) {
      setState(() => _error = 'A Philippine postal code is four digits.');
      return;
    }
    if (mobile is String && !RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(mobile)) {
      setState(() => _error = 'Enter a mobile number as 09XXXXXXXXX or +639XXXXXXXXX.');
      return;
    }
    if (patch.isEmpty) {
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(messageBar('Nothing to correct — those details are already on file.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.patchMe(patch);
      if (!mounted) return;
      await context.read<SessionService>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(messageBar('Sent to the Municipality.'));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(controller: controller, keyboardType: keyboardType, style: SoftType.field),
        ],
      ),
    );
  }

  Widget _heldRow(String label, String? value) {
    final shown = (value == null || value.isEmpty) ? 'Not recorded' : (label == 'Date of Birth' && value.length > 10 ? value.substring(0, 10) : value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13))),
          Text(shown, style: SoftType.cellValue),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SessionService>().profile;
    return SoftPageScaffold(
      title: 'Edit Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('First Name', _firstName),
            _field('Middle Name', _middleName),
            _field('Last Name', _lastName),
            const SoftFieldLabel('Email (cannot be changed)'),
            TextField(controller: TextEditingController(text: p?.email ?? ''), enabled: false, style: SoftType.field.copyWith(color: SoftColors.muted)),
            const SizedBox(height: 16),
            _field('Mobile Number', _mobile, keyboardType: TextInputType.phone),
            _field('Street Address', _street),
            const SoftFieldLabel('Barangay'),
            DropdownButtonFormField<String>(
              initialValue: castillaBarangays.contains(_barangay) ? _barangay : null,
              isExpanded: true,
              borderRadius: BorderRadius.circular(SoftRadius.md),
              items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _barangay = v),
            ),
            const SizedBox(height: 16),
            _field('Postal Code', _postal, keyboardType: TextInputType.number),
            const SizedBox(height: 4),
            const SoftSectionHeader(title: 'On record'),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heldRow('Date of Birth', p?.dateOfBirth),
                  const Divider(height: 1, color: SoftColors.line),
                  _heldRow('Sex', p?.sex),
                  const Divider(height: 1, color: SoftColors.line),
                  _heldRow('Civil Status', p?.civilStatus),
                  const Divider(height: 1, color: SoftColors.line),
                  _heldRow('Nationality', p?.nationality),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To correct any of these four, contact ${municipalEngineer.shortName} on ${municipalEngineer.mobile}.',
              style: SoftType.cellLabel.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: AppTypography.error),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 10),
            SoftPillButton(label: 'Save Changes', busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
