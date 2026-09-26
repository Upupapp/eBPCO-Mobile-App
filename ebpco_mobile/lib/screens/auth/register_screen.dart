import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/castilla.dart';
import '../../domain/password_policy.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/password_checklist.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../profile/legal_screen.dart';
import 'registration_success_screen.dart';

/// Three steps — Personal, Contact (incl. real email verification), Security
/// — with the same rules as the citizen portal's `register.page.ts`: 18+,
/// 09XXXXXXXXX mobile, 4-digit postal code, the server's password policy,
/// Terms and Privacy both agreed, and the portal's escape hatch when the
/// Municipality cannot send a verification code at all.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  int _step = 1;
  String? _error;
  final _scroll = ScrollController();

  /// Every step change starts at the top with no leftover error.
  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }
  bool _submitting = false;

  // Step 1 — Personal
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  DateTime? _dob;
  String? _sex;
  String? _civilStatus;
  String _nationality = 'Filipino';
  final _otherNationality = TextEditingController();

  // Step 2 — Contact
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _street = TextEditingController();
  String? _barangay;
  final _postal = TextEditingController(text: castillaPostalCode);
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _emailVerified = false;
  bool _sendingCode = false;
  bool _confirmingCode = false;
  String? _codeNotice;
  String? _codeError;
  String? _skipVerification;
  String _verifiedFor = '';

  // Step 3 — Security
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onEmailEdited);
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _firstName, _middleName, _lastName, _otherNationality, _email, _mobile, _street, _postal, _code, _password, _confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// A code belongs to the address it was sent to — editing the email after
  /// sending or confirming resets verification, as on the portal.
  void _onEmailEdited() {
    if ((_codeSent || _emailVerified || _skipVerification != null) && _email.text.trim() != _verifiedFor) {
      setState(() {
        _codeSent = false;
        _emailVerified = false;
        _code.clear();
        _codeNotice = null;
        _codeError = null;
        _skipVerification = null;
      });
    }
  }

  int _ageFrom(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age -= 1;
    return age;
  }

  void _toStep2() {
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _dob == null ||
        _sex == null ||
        _civilStatus == null) {
      setState(() => _error = 'Please complete all required fields.');
      return;
    }
    if (_ageFrom(_dob!) < 18) {
      setState(() => _error = 'You must be at least 18 years old to register.');
      return;
    }
    if (_nationality == 'Other' && _otherNationality.text.trim().isEmpty) {
      setState(() => _error = 'Please specify your nationality.');
      return;
    }
    _goTo(2);
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _codeError = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _sendingCode = true;
      _codeError = null;
      _codeNotice = null;
      _error = null;
    });
    try {
      final result = await CitizenApi.instance.requestEmailVerification(email);
      if (!mounted) return;
      setState(() {
        _verifiedFor = email;
        if (result.kind == 'sent') {
          _codeSent = true;
          _skipVerification = null;
          _codeNotice = 'A 6-digit code was sent. It expires in a few minutes.';
        } else if (result.kind == 'too-soon') {
          _codeSent = true;
          _codeNotice = result.detail;
        } else {
          _codeSent = false;
          _skipVerification =
              '${result.detail} You can continue without verifying now, and verify this email later from your Profile.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifiedFor = email;
        _skipVerification = 'Could not reach the Municipality’s system to send a code. '
            'You can continue without verifying now, and verify this email later from your Profile.';
      });
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _confirmCode() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _codeError = 'Enter the 6-digit code exactly as sent.');
      return;
    }
    setState(() {
      _confirmingCode = true;
      _codeError = null;
      _codeNotice = null;
    });
    try {
      await CitizenApi.instance.confirmEmailVerification(_email.text.trim(), _code.text.trim());
      if (!mounted) return;
      setState(() {
        _emailVerified = true;
        _codeSent = false;
        _code.clear();
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _codeError = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _confirmingCode = false);
    }
  }

  void _toStep3() {
    final missing = <(bool, String)>[
      (_email.text.trim().isEmpty, 'Email Address'),
      (_mobile.text.trim().isEmpty, 'Mobile Number'),
      (_street.text.trim().isEmpty, 'House Number / Street'),
      (_barangay == null, 'Barangay'),
      (_postal.text.trim().isEmpty, 'Postal Code'),
    ];
    final firstMissing = missing.where((m) => m.$1).firstOrNullValue;
    if (firstMissing != null) {
      setState(() => _error = '${firstMissing.$2} is required.');
      return;
    }
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (!RegExp(r'^09\d{9}$').hasMatch(_mobile.text.trim())) {
      setState(() => _error = 'Mobile number must be in the format 09XXXXXXXXX.');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(_postal.text.trim())) {
      setState(() => _error = 'Postal code must be exactly 4 digits.');
      return;
    }
    if (!_emailVerified && _codeSent && _skipVerification == null) {
      setState(() => _error = 'Please confirm the code sent to your email, or use Resend Code if it did not arrive.');
      return;
    }
    _goTo(3);
  }

  PasswordContext get _passwordContext =>
      PasswordContext(email: _email.text.trim(), firstName: _firstName.text.trim(), lastName: _lastName.text.trim());

  Future<void> _submit() async {
    final rejection = firstPasswordRejectionMessage(_password.text, _passwordContext);
    if (rejection != null) {
      setState(() => _error = rejection);
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy) {
      setState(() => _error = 'You must agree to the Terms & Conditions and Privacy Policy.');
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
        sex: _sex!,
        civilStatus: _civilStatus!,
        nationality: _nationality == 'Other' ? _otherNationality.text.trim() : _nationality,
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
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openLegal({required bool privacy}) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalScreen(showPrivacy: privacy)));

  @override
  Widget build(BuildContext context) {
    const titles = ['Personal details', 'Contact & address', 'Secure your account'];
    return SoftPageScaffold(
      title: 'Create Account',
      body: SingleChildScrollView(
        controller: _scroll,
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
          ],
        ),
      ),
    );
  }

  Widget _errorLine() => _error == null
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_error!, style: AppTypography.error));

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textCapitalization: capitalization,
            style: SoftType.field,
            decoration: InputDecoration(hintText: hint),
          ),
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

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: value,
            hint: const Text('Select'),
            isExpanded: true,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            menuMaxHeight: 360,
            items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('First Name *', _firstName, capitalization: TextCapitalization.words),
        _field('Middle Name', _middleName, capitalization: TextCapitalization.words),
        _field('Last Name *', _lastName, capitalization: TextCapitalization.words),
        const SoftFieldLabel('Date of Birth *'),
        SoftPickerField(
          value: _dob == null ? null : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
          placeholder: 'Select date',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
        ),
        const SizedBox(height: 16),
        _dropdown('Sex *', _sex, const ['Male', 'Female', 'Prefer not to say'], (v) => setState(() => _sex = v)),
        _dropdown(
          'Civil Status *',
          _civilStatus,
          const ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'],
          (v) => setState(() => _civilStatus = v),
        ),
        _dropdown('Nationality *', _nationality, nationalities, (v) => setState(() => _nationality = v ?? _nationality)),
        if (_nationality == 'Other') _field('Specify your nationality *', _otherNationality, capitalization: TextCapitalization.words),
        _errorLine(),
        SoftPillButton(label: 'Continue', onPressed: _toStep2),
      ],
    );
  }

  Widget _contactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SoftFieldLabel('Email Address *'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
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
          const Align(alignment: Alignment.centerLeft, child: SoftStatusPill(label: 'Email verified', tone: SoftStatusTone.verified))
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _sendingCode ? null : _sendCode,
              child: Text(_sendingCode ? 'Sending…' : (_codeSent ? 'Resend Code' : 'Verify Email')),
            ),
          ),
        if (_codeSent && !_emailVerified) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: SoftType.field,
                  decoration: const InputDecoration(hintText: '6-digit code'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 110, child: SoftPillButton(label: 'Confirm', busy: _confirmingCode, onPressed: _confirmCode)),
            ],
          ),
        ],
        if (_codeNotice != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_codeNotice!, style: SoftType.cellLabel)),
        if (_codeError != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_codeError!, style: AppTypography.error)),
        if (_skipVerification != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_skipVerification!, style: SoftType.cellLabel.copyWith(color: SoftColors.pendingInk)),
          ),
        const SizedBox(height: 16),
        _field(
          'Mobile Number *',
          _mobile,
          keyboardType: TextInputType.phone,
          hint: '09XXXXXXXXX',
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        ),
        _field('House Number / Street *', _street),
        _dropdown('Barangay *', _barangay, castillaBarangays, (v) => setState(() => _barangay = v)),
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
        _field(
          'Postal Code *',
          _postal,
          keyboardType: TextInputType.number,
          hint: '4 digits',
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        ),
        _errorLine(),
        _navRow(onBack: () => _goTo(1), nextLabel: 'Continue', onNext: _toStep3),
      ],
    );
  }

  Widget _passwordField(String label, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: SoftType.field,
            decoration: InputDecoration(
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SoftColors.muted),
                  onPressed: toggle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agreeRow({required bool value, required ValueChanged<bool> onChanged, required String linkLabel, required VoidCallback onLink}) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Flexible(child: GestureDetector(onTap: () => onChanged(!value), child: Text('I agree to the ', style: SoftType.body.copyWith(color: SoftColors.ink)))),
        GestureDetector(onTap: onLink, child: Text(linkLabel, style: SoftType.sectionLink.copyWith(fontSize: 14))),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _passwordField('Password *', _password, _obscure, () => setState(() => _obscure = !_obscure)),
        PasswordChecklist(password: _password.text, context_: _passwordContext),
        const SizedBox(height: 12),
        _passwordField('Confirm Password *', _confirmPassword, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
        _agreeRow(
          value: _acceptedTerms,
          onChanged: (v) => setState(() => _acceptedTerms = v),
          linkLabel: 'Terms & Conditions',
          onLink: () => _openLegal(privacy: false),
        ),
        _agreeRow(
          value: _acceptedPrivacy,
          onChanged: (v) => setState(() => _acceptedPrivacy = v),
          linkLabel: 'Privacy Policy',
          onLink: () => _openLegal(privacy: true),
        ),
        const SizedBox(height: 12),
        _errorLine(),
        _navRow(onBack: () => _goTo(2), nextLabel: 'Create Account', onNext: _submit, busy: _submitting),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNullValue => isEmpty ? null : first;
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
