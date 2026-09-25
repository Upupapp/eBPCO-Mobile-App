import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/soft_chrome.dart';
import 'auth_soft_chrome.dart';
import 'register_screen.dart';

/// Citizen sign-in. Frontend simulation only — no server is contacted.
///
/// Create account and Continue as Guest are peer links under Sign in.
/// Quick demo cards are access labels, not named residents.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _leaveIfPushed() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  List<CitizenAccount> get _knownAccounts => [
    ...MockCatalog.demoAccounts,
    MockCatalog.duplicateVerifiedDemoAccount,
    MockCatalog.unverifiedDuplicateAccountA,
    MockCatalog.unverifiedDuplicateAccountB,
  ];

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);

    final match = _knownAccounts.where(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
    );
    if (match.isEmpty) {
      setState(
        () => _error =
            'No resident account found for that email in this demo. Try a quick demo card below, or create an account.',
      );
      return;
    }
    await context.read<CitizenSessionService>().login(match.first);
    await _leaveIfPushed();
  }

  Future<void> _quickLogin(CitizenAccount account) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _loading = false);
    await context.read<CitizenSessionService>().login(account);
    if (!mounted) return;
    AppDialogs.toast(
      context,
      'This app is a frontend simulation — sign-in is mocked for now.',
    );
    await _leaveIfPushed();
  }

  Future<void> _continueAsGuest() async {
    await context.read<CitizenSessionService>().continueAsGuest();
    await _leaveIfPushed();
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final verified = MockCatalog.demoAccounts.last;
    final unverified = MockCatalog.demoAccounts.first;
    return Theme(
      data: authSoftTheme(Theme.of(context)),
      child: SoftWash(
        child: Scaffold(
          backgroundColor: SoftColors.clear,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canPop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SoftCircleButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const _BrandLockup(),
                  const SizedBox(height: 12),
                  const Text('Mag-sign in', style: SoftType.eyebrow),
                  const SizedBox(height: 4),
                  const Text('Welcome back', style: SoftType.h1),
                  const SizedBox(height: 6),
                  Text(
                    'Use your demo account or continue as Guest to browse public content.',
                    style: SoftType.body.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  _field(
                    label: 'Email or mobile',
                    controller: _emailController,
                    hintText: 'resident@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: '••••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    AuthErrorText(_error!),
                  ],
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Sign in',
                    fullWidth: true,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 18,
                    runSpacing: 4,
                    children: [
                      AuthInlineLink(
                        label: 'Create account',
                        onPressed: _loading ? null : _openRegister,
                      ),
                      AuthInlineLink(
                        label: 'Continue as Guest',
                        linkKey: const Key('continue-as-guest'),
                        onPressed: _loading ? null : _continueAsGuest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _HonestyBanner(
                    text:
                        'Frontend simulation. Demo cards below do not call a live LGU backend. Data stays on this device.',
                  ),
                  const SizedBox(height: 10),
                  const Text('Quick demo accounts', style: SoftType.cellLabel),
                  const SizedBox(height: 8),
                  _DemoCard(
                    key: const Key('demo-verified'),
                    initials: 'VR',
                    title: 'Verified resident',
                    subtitle: 'Full Dokyu + Tulong · simulation',
                    disc: SoftColors.blue,
                    discInk: SoftColors.white,
                    tagWash: SoftColors.blueWash,
                    tagInk: SoftColors.blue,
                    onTap: _loading ? null : () => _quickLogin(verified),
                  ),
                  const SizedBox(height: 8),
                  _DemoCard(
                    key: const Key('demo-unverified'),
                    initials: 'UV',
                    title: 'Unverified',
                    subtitle: 'Signed in · pending review · Emergency only',
                    disc: SoftColors.gold,
                    discInk: SoftColors.ink,
                    tagWash: SoftColors.pendingCream,
                    tagInk: SoftColors.pendingInk,
                    onTap: _loading ? null : () => _quickLogin(unverified),
                  ),
                  const SizedBox(height: 8),
                  _DemoCard(
                    key: const Key('demo-guest'),
                    initials: 'G',
                    title: 'Guest',
                    subtitle: 'Public Home / Balita / Events only',
                    disc: SoftColors.muted,
                    discInk: SoftColors.white,
                    tagWash: SoftColors.page,
                    tagInk: SoftColors.muted,
                    onTap: _loading ? null : _continueAsGuest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
  }) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      labelColor: SoftColors.ink,
      textColor: SoftColors.ink,
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          teresaRizalSealAsset,
          width: 84,
          height: 84,
          fit: BoxFit.contain,
          semanticLabel: 'Seal of Teresa, Rizal',
        ),
        const SizedBox(height: 10),
        const Text(
          'Municipality of Teresa, Rizal',
          textAlign: TextAlign.center,
          style: SoftType.cellLabel,
        ),
        const SizedBox(height: 2),
        Text(
          'Teresa, Rizal',
          textAlign: TextAlign.center,
          style: SoftType.greetingName.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _HonestyBanner extends StatelessWidget {
  final String text;
  const _HonestyBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: SoftColors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SoftType.body.copyWith(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String initials;
  final String title;
  final String subtitle;
  final Color disc;
  final Color discInk;
  final Color tagWash;
  final Color tagInk;
  final VoidCallback? onTap;

  const _DemoCard({
    super.key,
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.disc,
    required this.discInk,
    required this.tagWash,
    required this.tagInk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            border: Border.all(color: SoftColors.line),
            boxShadow: SoftShadows.cardSm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: disc,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: discInk,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoftType.cellValue),
                    const SizedBox(height: 2),
                    Text(subtitle, style: SoftType.cellLabel),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagWash,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
                child: Text(
                  'Demo',
                  style: SoftType.cellLabel.copyWith(
                    fontWeight: FontWeight.w500,
                    color: tagInk,
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
