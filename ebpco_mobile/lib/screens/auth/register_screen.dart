import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/castilla.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'registration_success_screen.dart';

/// Three steps — Personal, Contact (incl. real email verification), Security
/// — mirroring `register.page.ts`'s own step shape exactly, including that
/// email verification happens inline on Step 2 before an account exists.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 1;
  String? _error;
  bool _submitting = false;

  // Step 1 — Personal
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  DateTime? _dob;
  String _sex = 'Prefer not to say';
  String _civilStatus = 'Single';
  final _nationality = TextEditingController(text: 'Filipino');

  // Step 2 — Contact
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _street = TextEditingController();
  String? _barangay;
  final _postal = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _emailVerified = false;
  bool _sendingCode = false;

  // Step 3 — Security
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final c in [_firstName, _middleName, _lastName, _nationality, _email, _mobile, _street, _postal, _code, _password, _confirmPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toStep2() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty || _dob == null) {
      setState(() => _error = 'Enter your first name, last name, and date of birth.');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty) return;
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.requestEmailVerification(_email.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _error = null);
    try {
      await CitizenApi.instance.confirmEmailVerification(_email.text.trim(), _code.text.trim());
      if (!mounted) return;
      setState(() => _emailVerified = true);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    }
  }

  void _toStep3() {
    if (!_emailVerified) {
      setState(() => _error = 'Verify your email before continuing.');
      return;
    }
    if (_mobile.text.trim().isEmpty || _barangay == null || _street.text.trim().isEmpty || _postal.text.trim().isEmpty) {
      setState(() => _error = 'Fill in your mobile number and complete address.');
      return;
    }
    setState(() {
      _error = null;
      _step = 3;
    });
  }

  Future<void> _submit() async {
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.register(
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
        lastName: _lastName.text.trim(),
        dateOfBirth: _dob!.toIso8601String().substring(0, 10),
        sex: _sex,
        civilStatus: _civilStatus,
        nationality: _nationality.text.trim(),
        email: _email.text.trim(),
        mobileNumber: _mobile.text.trim(),
        street: _street.text.trim(),
        barangay: _barangay!,
        city: castillaCity,
        province: castillaProvince,
        postalCode: _postal.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()));
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(step: _step),
              const SizedBox(height: AppSpacing.xxl),
              if (_step == 1) _personalStep(),
              if (_step == 2) _contactStep(),
              if (_step == 3) _securityStep(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.error),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.fieldLabel),
          const SizedBox(height: 6),
          TextField(controller: controller, keyboardType: keyboardType, obscureText: obscure),
        ],
      ),
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('First Name', _firstName),
        _field('Middle Name (optional)', _middleName),
        _field('Last Name', _lastName),
        Text('Date of Birth', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(_dob == null ? 'Select date' : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Sex', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _sex,
          items: const ['Male', 'Female', 'Prefer not to say'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _sex = v ?? _sex),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Civil Status', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _civilStatus,
          items: const ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _civilStatus = v ?? _civilStatus),
        ),
        _field('Nationality', _nationality),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(onPressed: _toStep2, child: const Text('Continue')),
      ],
    );
  }

  Widget _contactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Email', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          enabled: !_emailVerified,
          decoration: InputDecoration(
            suffixIcon: _emailVerified ? const Icon(Icons.check_circle, color: AppColors.success) : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_emailVerified)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _sendingCode ? null : _sendCode,
              child: Text(_codeSent ? 'Resend code' : 'Send verification code'),
            ),
          ),
        if (_codeSent && !_emailVerified) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: TextField(controller: _code, decoration: const InputDecoration(hintText: '6-digit code'))),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(onPressed: _confirmCode, child: const Text('Verify')),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _field('Mobile Number', _mobile, keyboardType: TextInputType.phone),
        _field('Street Address', _street),
        Text('Barangay', style: AppTypography.fieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _barangay,
          hint: const Text('Select barangay'),
          isExpanded: true,
          items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => _barangay = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City / Municipality', style: AppTypography.fieldLabel),
                  const SizedBox(height: 6),
                  TextField(controller: TextEditingController(text: castillaCity), enabled: false),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Province', style: AppTypography.fieldLabel),
                  const SizedBox(height: 6),
                  TextField(controller: TextEditingController(text: castillaProvince), enabled: false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _field('ZIP Code', _postal, keyboardType: TextInputType.number),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: ElevatedButton(onPressed: _toStep3, child: const Text('Continue'))),
          ],
        ),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Password', _password, obscure: true),
        _field('Confirm Password', _confirmPassword, obscure: true),
        Text('At least 8 characters.', style: AppTypography.hint),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 2), child: const Text('Back'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
          ],
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
    Widget dot(int n, String label) {
      final active = n == step;
      final done = n < step;
      return Column(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: active || done ? AppColors.primary500 : AppColors.gray200,
            child: Text('$n', style: AppTypography.caption.copyWith(color: active || done ? Colors.white : AppColors.gray500, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [dot(1, 'Personal'), dot(2, 'Contact'), dot(3, 'Security')],
    );
  }
}
