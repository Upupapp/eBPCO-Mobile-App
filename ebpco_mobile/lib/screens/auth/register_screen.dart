import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/castilla.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
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
    const titles = ['Personal details', 'Contact & address', 'Secure your account'];
    return SoftPageScaffold(
      title: 'Create Account',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(step: _step),
            const SizedBox(height: 18),
            Text(titles[_step - 1], style: SoftType.h1.copyWith(fontSize: 24)),
            const SizedBox(height: 18),
            if (_step == 1) _personalStep(),
            if (_step == 2) _contactStep(),
            if (_step == 3) _securityStep(),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTypography.error),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(controller: controller, keyboardType: keyboardType, obscureText: obscure, style: SoftType.field),
        ],
      ),
    );
  }

  Widget _navRow({required VoidCallback onBack, required String nextLabel, required VoidCallback onNext, bool busy = false}) {
    return Row(
      children: [
        Expanded(child: SoftPillButton(label: 'Back', kind: SoftPillKind.outline, onPressed: busy ? null : onBack)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SoftPillButton(label: nextLabel, busy: busy, onPressed: onNext)),
      ],
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('First Name', _firstName),
        _field('Middle Name (optional)', _middleName),
        _field('Last Name', _lastName),
        const SoftFieldLabel('Date of Birth'),
        SoftPickerField(
          value: _dob == null ? null : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
          placeholder: 'Select date',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
        ),
        const SizedBox(height: 16),
        const SoftFieldLabel('Sex'),
        DropdownButtonFormField<String>(
          initialValue: _sex,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          items: const ['Male', 'Female', 'Prefer not to say'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _sex = v ?? _sex),
        ),
        const SizedBox(height: 16),
        const SoftFieldLabel('Civil Status'),
        DropdownButtonFormField<String>(
          initialValue: _civilStatus,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          items: const ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _civilStatus = v ?? _civilStatus),
        ),
        const SizedBox(height: 16),
        _field('Nationality', _nationality),
        const SizedBox(height: 10),
        SoftPillButton(label: 'Continue', onPressed: _toStep2),
      ],
    );
  }

  Widget _contactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SoftFieldLabel('Email'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          enabled: !_emailVerified,
          style: SoftType.field,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            suffixIcon: _emailVerified
                ? const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_circle_rounded, color: SoftColors.verifiedInk))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (_emailVerified)
          Align(alignment: Alignment.centerLeft, child: SoftStatusPill(label: 'Email verified', tone: SoftStatusTone.verified))
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _sendingCode ? null : _sendCode,
              child: Text(_codeSent ? 'Resend code' : 'Send verification code'),
            ),
          ),
        if (_codeSent && !_emailVerified) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  style: SoftType.field,
                  decoration: const InputDecoration(hintText: '6-digit code'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 110, child: SoftPillButton(label: 'Verify', onPressed: _confirmCode)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _field('Mobile Number', _mobile, keyboardType: TextInputType.phone),
        _field('Street Address', _street),
        const SoftFieldLabel('Barangay'),
        DropdownButtonFormField<String>(
          initialValue: _barangay,
          hint: const Text('Select barangay'),
          isExpanded: true,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          items: castillaBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => _barangay = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SoftFieldLabel('City / Municipality'),
                  TextField(controller: TextEditingController(text: castillaCity), enabled: false, style: SoftType.field),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SoftFieldLabel('Province'),
                  TextField(controller: TextEditingController(text: castillaProvince), enabled: false, style: SoftType.field),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field('ZIP Code', _postal, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        _navRow(onBack: () => setState(() => _step = 1), nextLabel: 'Continue', onNext: _toStep3),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Password', _password, obscure: true),
        _field('Confirm Password', _confirmPassword, obscure: true),
        Text('At least 8 characters.', style: SoftType.cellLabel),
        const SizedBox(height: 24),
        _navRow(onBack: () => setState(() => _step = 2), nextLabel: 'Create Account', onNext: _submit, busy: _submitting),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Personal', 'Contact', 'Security'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step of 3 · ${labels[step - 1]}', style: SoftType.eyebrow),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
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
    );
  }
}
