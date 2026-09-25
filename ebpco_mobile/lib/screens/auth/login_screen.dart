import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../home/root_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Sign in — the design reference's sign-in layout (wash, large seal,
/// municipality line, left-aligned eyebrow and headline, pill fields, a
/// glowing pill button, a link row) against the real `/auth/token`.
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

  @override
  Widget build(BuildContext context) {
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.clear,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle, boxShadow: SoftShadows.seal),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),
              Text('Municipality of Castilla, Sorsogon', textAlign: TextAlign.center, style: SoftType.eyebrow.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text('eBPCO', textAlign: TextAlign.center, style: SoftType.pageTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 28),
              Text('Sign in', style: SoftType.eyebrow.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Text('Welcome back', style: SoftType.hero.copyWith(fontSize: 34)),
              const SizedBox(height: 8),
              Text('Sign in to file and track your permits.', style: SoftType.body.copyWith(fontSize: 16)),
              const SizedBox(height: 22),
              Text('Email', style: SoftType.fieldLabel.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: SoftType.field,
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: 16),
              Text('Password', style: SoftType.fieldLabel.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: SoftType.field,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Your password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SoftColors.muted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTypography.error),
              ],
              const SizedBox(height: 22),
              SoftPillButton(label: 'Sign in', busy: _submitting, onPressed: _submit),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Create account', style: SoftType.sectionLink.copyWith(fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: Text('Forgot password?', style: SoftType.sectionLink.copyWith(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
