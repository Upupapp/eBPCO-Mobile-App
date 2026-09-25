import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/soft_chrome.dart';
import 'auth_soft_chrome.dart';

/// Six-step registration. Frontend simulation only.
///
/// Personal → Terms → Valid ID → Face → Review → Status.
/// The sticky Back | Continue footer sits outside the scroll so a focused
/// field and Continue stay above the IME.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _sexes = ['Male', 'Female', 'Prefer not'];
  static const _idTypes = ["PhilSys", "Driver's license", 'UMID'];

  int _step = 0;
  late final bool _openedOnStatus;

  final _fullName = TextEditingController();
  final _birthDate = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _mobileFocus = FocusNode();
  final _mobileKey = GlobalKey();

  String? _sex;
  bool _termsAccepted = false;
  String? _idType;
  String? _idSource;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    _openedOnStatus = account != null;
    _step = _openedOnStatus ? 5 : 0;
    _mobileFocus.addListener(_keepMobileAboveKeyboard);
  }

  void _keepMobileAboveKeyboard() {
    if (!_mobileFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _mobileKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.05,
        duration: Duration.zero,
      );
    });
  }

  @override
  void dispose() {
    _mobileFocus.removeListener(_keepMobileAboveKeyboard);
    _mobileFocus.dispose();
    for (final c in [_fullName, _birthDate, _mobile, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _fullName.text.trim().isNotEmpty &&
            _birthDate.text.trim().isNotEmpty &&
            _sex != null &&
            _mobile.text.trim().isNotEmpty &&
            _email.text.trim().isNotEmpty &&
            _address.text.trim().isNotEmpty;
      case 1:
        return _termsAccepted;
      case 2:
        return _idType != null;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canContinue) {
      setState(() => _error = _blockedReason);
      return;
    }
    setState(() {
      _error = null;
      if (_step < 5) _step++;
    });
  }

  String get _blockedReason {
    switch (_step) {
      case 0:
        return 'Please complete the personal details to continue.';
      case 1:
        return 'Please acknowledge the preview terms to continue.';
      case 2:
        return 'Please choose an ID type to continue.';
      default:
        return 'Please complete this step to continue.';
    }
  }

  void _back() {
    if (_step == 0 || _step == 5) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
  }

  String? _matchedBarangay(String address) {
    final lower = address.toLowerCase();
    for (final name in teresaRegisterBarangays) {
      if (lower.contains(name.toLowerCase())) return name;
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final address = _address.text.trim();
    final parts = _fullName.text.trim().split(RegExp(r'\s+'));
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '—';
    final account = CitizenAccount(
      id: 'ESP-RES-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      firstName: first,
      lastName: last,
      email: _email.text.trim(),
      mobile: _mobile.text.trim(),
      barangay: _matchedBarangay(address) ?? 'Poblacion',
      purok: '—',
      address: address,
      birthdate: _birthDate.text.trim(),
      sex: _sex ?? '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 35,
      status: AppStatus.pendingReview.label,
    );
    await context.read<CitizenSessionService>().login(account);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _step = 5;
    });
  }

  void _goHome() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 5 ? 'Verification' : 'Create account';
    return Theme(
      data: authSoftTheme(Theme.of(context)),
      child: SoftWash(
        child: Scaffold(
          backgroundColor: SoftColors.clear,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            centerTitle: true,
            title: Text(title, style: SoftType.pageTitle),
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SoftCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: _back,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _Progress(
                    step: _step,
                    accountStatus: _statusOf(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: _buildStep(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: _footer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppStatus _statusOf(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account;
    if (account == null) return AppStatus.pendingReview;
    return AppStatusX.fromLabel(account.status);
  }

  Widget _footer() {
    if (_step == 5) return _statusFooter();
    final primaryLabel = _step == 4 ? 'Submit for verification' : 'Continue';
    return Row(
      children: [
        Expanded(
          child: AuthOutlineButton(label: 'Back', onPressed: _back),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppButton(
            label: primaryLabel,
            fullWidth: true,
            loading: _submitting,
            onPressed: _submitting
                ? null
                : (_step == 4 ? _submit : (_canContinue ? _next : null)),
          ),
        ),
      ],
    );
  }

  Widget _statusFooter() {
    final frame = _frameFor(_statusOf(context));
    if (frame == _StatusFrame.approved) {
      return AppButton(
        label: 'Go to Home',
        fullWidth: true,
        onPressed: _goHome,
      );
    }
    if (frame == _StatusFrame.rejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Reapply',
            fullWidth: true,
            onPressed: () => setState(() {
              _error = null;
              _step = 0;
            }),
          ),
          const SizedBox(height: 8),
          AuthOutlineButton(label: 'Back to Home', onPressed: _goHome),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Continue exploring',
          fullWidth: true,
          onPressed: _goHome,
        ),
        const SizedBox(height: 8),
        AuthOutlineButton(
          label: 'View application',
          onPressed: () => setState(() => _step = 4),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _personal();
      case 1:
        return _terms();
      case 2:
        return _validId();
      case 3:
        return _face();
      case 4:
        return _review();
      default:
        return _status();
    }
  }

  Widget _personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hakbang 1 · Personal', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Tell us about you', style: SoftType.h1),
        const SizedBox(height: 6),
        Text(
          'Basic details for resident verification in Teresa, Rizal.',
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        _field(label: 'Full name', controller: _fullName),
        const SizedBox(height: 12),
        _field(
          label: 'Birth date',
          controller: _birthDate,
          hintText: '12 Apr 1992',
        ),
        const SizedBox(height: 12),
        const Text(
          'Sex',
          style: TextStyle(
            fontFamily: AppTypography.sans,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: SoftColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in _sexes)
              _ChoiceChip(
                label: label,
                selected: _sex == label,
                onTap: () => setState(() => _sex = label),
              ),
          ],
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _mobileKey,
          child: _field(
            label: 'Mobile',
            controller: _mobile,
            hintText: '09XX XXX XXXX',
            keyboardType: TextInputType.phone,
            focusNode: _mobileFocus,
            fieldKey: const Key('register-mobile'),
          ),
        ),
        const SizedBox(height: 12),
        _field(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 12),
        _field(
          label: 'Address / Barangay',
          controller: _address,
          hintText: 'Purok 3, Dalig, Teresa, Rizal',
          icon: Icons.place_outlined,
        ),
        const SizedBox(height: 8),
        Text(
          'Samples: ${teresaRegisterBarangays.join(' · ')}',
          style: SoftType.cellLabel.copyWith(height: 1.35),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AuthErrorText(_error!),
        ],
      ],
    );
  }

  Widget _terms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hakbang 2 · Terms', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Terms & privacy', style: SoftType.h1),
        const SizedBox(height: 6),
        Text(
          'Please review before continuing. This build is a screens-only preview.',
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        AuthSoftCard(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Municipality of Teresa, Rizal',
                    style: SoftType.cellValue,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This application is a frontend simulation for design and usability review. It is not an official live government identity or records system.',
                    style: SoftType.body,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Information you enter stays on your device in this preview. Nothing is submitted to a municipal server, PhilSys, or third-party identity provider.',
                    style: SoftType.body,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Digital ID cards shown later are mock wallets for UX only — not a real government-issued ID.',
                    style: SoftType.body,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'By continuing you acknowledge this is a demo flow for the Teresa, Rizal app.',
                    style: SoftType.body,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help contacts: [TO BE PROVIDED]',
          style: SoftType.cellLabel,
        ),
        const SizedBox(height: 12),
        AuthSoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _termsAccepted,
                activeColor: SoftColors.blue,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'I understand this is a frontend preview. Data stays local and is not a real government registration.',
                    style: TextStyle(
                      fontFamily: AppTypography.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: SoftColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.blueWash,
          icon: Icons.info_outline_rounded,
          iconColor: SoftColors.blue,
          text:
              'Honesty: Terms text is placeholder for comps. Final legal copy is owned by LGU counsel.',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AuthErrorText(_error!),
        ],
      ],
    );
  }

  Widget _validId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hakbang 3 · Valid ID', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Upload a valid ID', style: SoftType.h1),
        const SizedBox(height: 6),
        Text(
          'Photo evidence for verification review. Demo upload only — files stay on device.',
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _idTypes)
              _ChoiceChip(
                label: type,
                selected: _idType == type,
                onTap: () => setState(() => _idType = type),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AuthDashedWell(
          onTap: () => setState(() => _idSource ??= 'photo'),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: SoftColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: SoftColors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _idSource == null
                    ? 'Drop or choose a photo'
                    : 'Photo attached (local preview)',
                style: SoftType.sectionLink.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _idSource == null
                    ? 'Clear front of ID · JPG or PNG'
                    : '${_idType ?? 'ID'} · $_idSource',
                style: SoftType.cellLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SourceButton(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              onTap: () => setState(() => _idSource = 'camera'),
            ),
            const SizedBox(width: 8),
            _SourceButton(
              icon: Icons.photo_outlined,
              label: 'Gallery',
              onTap: () => setState(() => _idSource = 'gallery'),
            ),
            const SizedBox(width: 8),
            _SourceButton(
              icon: Icons.description_outlined,
              label: 'File',
              onTap: () => setState(() => _idSource = 'file'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.blueWash,
          icon: Icons.info_outline_rounded,
          iconColor: SoftColors.blue,
          text:
              'Not a real ID check. Upload is simulated for UX comps. No document is stored on an LGU server in this preview.',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AuthErrorText(_error!),
        ],
      ],
    );
  }

  Widget _face() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hakbang 4 · Face check', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Face honesty check', style: SoftType.h1),
        const SizedBox(height: 6),
        Text(
          'Align your face in the oval. This step is simulated for the prototype.',
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        const _NoteBanner(
          wash: SoftColors.endedWash,
          icon: Icons.verified_user_outlined,
          iconColor: SoftColors.pendingInk,
          text:
              'Not real biometrics. This is a simulated face check for design comps only. It does not prove identity and does not enroll biometric data.',
        ),
        const SizedBox(height: 14),
        const _FacePreview(),
      ],
    );
  }

  Widget _review() {
    final account = context.watch<CitizenSessionService>().account;
    final name = _fullName.text.trim().isEmpty
        ? (account?.fullName ?? '—')
        : _fullName.text.trim();
    final place = _address.text.trim().isEmpty
        ? (account?.address ?? '—')
        : _address.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hakbang 5 · Review', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Review & submit', style: SoftType.h1),
        const SizedBox(height: 6),
        Text(
          'Confirm details before sending for verification review.',
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        AuthSoftCard(
          child: Column(
            children: [
              _reviewRow(
                icon: Icons.person_outline_rounded,
                title: 'Personal',
                value: '$name · $place',
                step: 0,
              ),
              _reviewRow(
                icon: Icons.badge_outlined,
                title: 'Valid ID',
                value: _idType == null
                    ? '—'
                    : '$_idType · photo attached (local preview)',
                step: 2,
              ),
              _reviewRow(
                icon: Icons.face_outlined,
                title: 'Face check',
                value: 'Simulated · complete',
                step: 3,
              ),
              _reviewRow(
                icon: Icons.check_rounded,
                title: 'Terms',
                value: _termsAccepted || _openedOnStatus
                    ? 'Acknowledged · frontend preview'
                    : 'Not acknowledged',
                step: 1,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.blueWash,
          icon: Icons.info_outline_rounded,
          iconColor: SoftColors.blue,
          text:
              'Submit is simulated. In this comps build, verification status is a local state — not an LGU office queue.',
        ),
      ],
    );
  }

  Widget _reviewRow({
    required IconData icon,
    required String title,
    required String value,
    required int step,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SoftColors.verifiedSoft,
              borderRadius: BorderRadius.circular(SoftRadius.sm),
            ),
            child: Icon(icon, size: 18, color: SoftColors.verifiedInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SoftType.cellValue),
                const SizedBox(height: 2),
                Text(value, style: SoftType.cellLabel),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _step = step),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Text('Edit', style: SoftType.sectionLink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status() {
    final status = _statusOf(context);
    final frame = _frameFor(status);
    return switch (frame) {
      _StatusFrame.approved => const _ApprovedStatus(),
      _StatusFrame.rejected => const _RejectedStatus(),
      _StatusFrame.pending => const _PendingStatus(),
    };
  }

  _StatusFrame _frameFor(AppStatus status) {
    return switch (status) {
      AppStatus.approved || AppStatus.verified => _StatusFrame.approved,
      AppStatus.rejected => _StatusFrame.rejected,
      _ => _StatusFrame.pending,
    };
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    Key? fieldKey,
    IconData? icon,
  }) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      fieldKey: fieldKey,
      icon: icon,
      scrollPadding: authFieldScrollPadding,
      labelColor: SoftColors.ink,
      textColor: SoftColors.ink,
      iconColor: SoftColors.muted,
      onChanged: (_) => setState(() => _error = null),
    );
  }
}

enum _StatusFrame { pending, approved, rejected }

class _Progress extends StatelessWidget {
  final int step;
  final AppStatus accountStatus;

  const _Progress({required this.step, required this.accountStatus});

  @override
  Widget build(BuildContext context) {
    final onStatus = step == 5;
    final frame = switch (accountStatus) {
      AppStatus.approved || AppStatus.verified => _StatusFrame.approved,
      AppStatus.rejected => _StatusFrame.rejected,
      _ => _StatusFrame.pending,
    };
    final Color fill;
    final String trailing;
    final double fraction;
    if (!onStatus) {
      fill = SoftColors.blue;
      trailing = '${step + 1} / 6';
      fraction = (step + 1) / 6;
    } else if (frame == _StatusFrame.approved) {
      fill = SoftColors.verifiedInk;
      trailing = 'Done';
      fraction = 1;
    } else if (frame == _StatusFrame.rejected) {
      fill = SoftColors.danger;
      trailing = 'Needs fix';
      fraction = 1;
    } else {
      fill = SoftColors.gold;
      trailing = '6 / 6';
      fraction = 1;
    }
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: SoftColors.line,
              color: fill,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          trailing,
          style: SoftType.cellLabel.copyWith(
            fontWeight: FontWeight.w500,
            color: onStatus ? fill : SoftColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blue : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        splashFactory: NoSplash.splashFactory,
        highlightColor: SoftColors.clear,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.sans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? SoftColors.white : SoftColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              border: Border.all(color: SoftColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: SoftColors.ink),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: SoftColors.ink,
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

class _NoteBanner extends StatelessWidget {
  final Color wash;
  final IconData icon;
  final Color iconColor;
  final String text;

  const _NoteBanner({
    required this.wash,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(SoftRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SoftType.body.copyWith(
                fontSize: 13,
                height: 1.4,
                color: SoftColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacePreview extends StatelessWidget {
  const _FacePreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SoftColors.blue, SoftColors.blueDeep],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(150, 180),
              painter: _OvalDashPainter(),
            ),
            const Positioned(top: 12, left: 12, child: _PreviewTag()),
            const Positioned(
              bottom: 14,
              child: Text(
                'Center your face · good lighting',
                style: TextStyle(
                  fontFamily: AppTypography.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: SoftColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SoftColors.ink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: SoftColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Preview · simulated',
            style: TextStyle(
              fontFamily: AppTypography.sans,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SoftColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OvalDashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoftColors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = Rect.fromLTWH(8, 4, size.width - 16, size.height - 8);
    final path = Path()..addOval(rect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PendingStatus extends StatelessWidget {
  const _PendingStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: SoftColors.pendingCream,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: const Icon(
            Icons.schedule_rounded,
            color: SoftColors.pendingInk,
          ),
        ),
        const SizedBox(height: 12),
        _StatusPill(
          label: AppStatus.pendingReview.label,
          wash: SoftColors.pendingCream,
          ink: SoftColors.pendingInk,
          dot: SoftColors.gold,
        ),
        const SizedBox(height: 14),
        const Text(
          'Waiting for review',
          style: SoftType.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your application is in the simulated review queue. You can keep exploring as Unverified.',
          textAlign: TextAlign.center,
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SoftColors.endedWash,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: const Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 13,
                height: 1.45,
                color: SoftColors.ink,
              ),
              children: [
                TextSpan(
                  text: 'Unverified access\n',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: SoftColors.pendingInk,
                  ),
                ),
                TextSpan(
                  text:
                      'Home, Balita, and Events stay open. Emergency is available. Dokyu and Tulong stay locked until Approved.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.blueWash,
          icon: Icons.info_outline_rounded,
          iconColor: SoftColors.blue,
          text:
              'Honesty: No real LGU officer is reviewing this. Status is frontend-simulated only.',
        ),
      ],
    );
  }
}

class _ApprovedStatus extends StatelessWidget {
  const _ApprovedStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: SoftColors.verifiedSoft,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: SoftColors.verifiedInk,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        _StatusPill(
          label: AppStatus.approved.label,
          wash: SoftColors.verifiedSoft,
          ink: SoftColors.verifiedInk,
          dot: SoftColors.verifiedInk,
        ),
        const SizedBox(height: 14),
        const Text(
          "You're verified",
          style: SoftType.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Dokyu and Tulong are unlocked for this simulated Verified resident account.',
          textAlign: TextAlign.center,
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: _UnlockTile(
                icon: Icons.description_outlined,
                title: 'Dokyu',
                subtitle: 'Documents',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _UnlockTile(
                icon: Icons.favorite_border_rounded,
                title: 'Tulong',
                subtitle: 'Assistance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.blueWash,
          icon: Icons.info_outline_rounded,
          iconColor: SoftColors.blue,
          text:
              'Digital ID wallet in Profile is a mock card — not a real government ID.',
        ),
      ],
    );
  }
}

class _RejectedStatus extends StatelessWidget {
  const _RejectedStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: SoftColors.dangerSoft,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: const Icon(Icons.close_rounded, color: SoftColors.danger),
        ),
        const SizedBox(height: 12),
        _StatusPill(
          label: AppStatus.rejected.label,
          wash: SoftColors.dangerSoft,
          ink: SoftColors.danger,
          dot: SoftColors.danger,
        ),
        const SizedBox(height: 14),
        const Text(
          'Needs a reapply',
          style: SoftType.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sample rejection for comps. Fix the noted issue and submit again.',
          textAlign: TextAlign.center,
          style: SoftType.body.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SoftColors.dangerSoft,
            borderRadius: BorderRadius.circular(SoftRadius.md),
          ),
          child: const Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 13,
                height: 1.45,
                color: SoftColors.ink,
              ),
              children: [
                TextSpan(
                  text: 'Reason (sample)\n',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: SoftColors.danger,
                  ),
                ),
                TextSpan(
                  text:
                      "Valid ID photo is unclear or cropped. Please re-upload a sharp front photo of your PhilSys, driver's license, or UMID.",
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _NoteBanner(
          wash: SoftColors.dangerSoft,
          icon: Icons.error_outline_rounded,
          iconColor: SoftColors.danger,
          text:
              'Simulated rejection. No real officer decision. Reapply restarts the local wizard state.',
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color wash;
  final Color ink;
  final Color dot;

  const _StatusPill({
    required this.label,
    required this.wash,
    required this.ink,
    required this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _UnlockTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.line),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(
        children: [
          Icon(icon, color: SoftColors.blue),
          const SizedBox(height: 6),
          Text(title, style: SoftType.cellValue),
          Text(subtitle, style: SoftType.cellLabel),
        ],
      ),
    );
  }
}
