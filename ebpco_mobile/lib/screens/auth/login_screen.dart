import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../home/root_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Sign in, against the real `/auth/token`.
///
/// The same language as onboarding, so the first two screens read as one
/// app: a hero with the curved edge, here the Castilla Town Hall under the
/// municipality's red, the seal sitting on the curve, then the form. Forgot
/// password sits with the field it is about; Create account is its own
/// button under "New to eBPCO?", not a link competing with it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final session = context.read<SessionService>();
    final ok = await session.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (route) => false);
    } else {
      setState(() => _error = session.lastError ?? 'Could not sign in.');
    }
  }

  InputDecoration _field(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Icon(icon, size: 21, color: SoftColors.muted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status-bar icons over the photograph.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoftColors.page,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _Hero(),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 6, 24, 24 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', textAlign: TextAlign.center, style: SoftType.hero.copyWith(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to file and track your permits.',
                    textAlign: TextAlign.center,
                    style: SoftType.body.copyWith(fontSize: 15.5),
                  ),
                  const SizedBox(height: 22),
                  Text('Email', style: SoftType.fieldLabel.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    style: SoftType.field,
                    decoration: _field('you@example.com', Icons.mail_outline_rounded),
                  ),
                  const SizedBox(height: 16),
                  Text('Password', style: SoftType.fieldLabel.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    style: SoftType.field,
                    onSubmitted: (_) => _submit(),
                    decoration: _field(
                      'Your password',
                      Icons.lock_outline_rounded,
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SoftColors.muted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: Text('Forgot password?', style: SoftType.sectionLink.copyWith(fontSize: 14.5)),
                    ),
                  ),
                  if (_error != null) ...[
                    SoftCard(
                      color: SoftColors.dangerSoft,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 20, color: SoftColors.danger),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: SoftType.body.copyWith(color: SoftColors.danger))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 6),
                  SoftPillButton(label: 'Sign in', busy: _submitting, onPressed: _submitting ? null : _submit),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: SoftColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('New to eBPCO?', style: SoftType.tileSub),
                      ),
                      const Expanded(child: Divider(color: SoftColors.line)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SoftPillButton(
                    label: 'Create an account',
                    kind: SoftPillKind.outline,
                    icon: Icons.person_add_alt_1_outlined,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Office of the Building Official\nMunicipality of Castilla, Sorsogon',
                    textAlign: TextAlign.center,
                    style: SoftType.tileSub.copyWith(fontSize: 12.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Town Hall under the municipality's red, curved at the bottom like the
/// onboarding hero, with the seal sitting on the curve.
class _Hero extends StatelessWidget {
  const _Hero();

  static const double _seal = 96;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = top + 226;
    return SizedBox(
      height: height + _seal / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: _seal / 2,
            child: ClipPath(
              clipper: _ArcBottomClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/castilla_town_hall.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.2)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB87A1220), Color(0xD1A5182A), Color(0xEBC81E2C)],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, top + 26, 24, 0),
                    child: Column(
                      children: [
                        Text(
                          'MUNICIPALITY OF CASTILLA · SORSOGON',
                          textAlign: TextAlign.center,
                          style: SoftType.eyebrow.copyWith(color: const Color(0xD9FFFFFF), fontSize: 12, letterSpacing: 1.6),
                        ),
                        const SizedBox(height: 10),
                        Text('eBPCO', style: SoftType.hero.copyWith(color: SoftColors.white, fontSize: 46, letterSpacing: -1)),
                        const SizedBox(height: 6),
                        Text(
                          'Building Permit and\nCertificate of Occupancy',
                          textAlign: TextAlign.center,
                          style: SoftType.body.copyWith(color: const Color(0xE6FFFFFF), fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: _seal,
                height: _seal,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: SoftColors.gold, width: 2),
                  boxShadow: SoftShadows.seal,
                ),
                child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The onboarding hero's curve: straight down both sides, then an arc that
/// dips below the middle.
class _ArcBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final shoulder = size.height * 0.80;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, shoulder)
      ..quadraticBezierTo(size.width / 2, size.height * 1.2, 0, shoulder)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
