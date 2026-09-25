import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'Forgot Password',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: _sent
            ? [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SoftIconTile(
                    icon: Icons.mark_email_read_outlined,
                    background: SoftColors.verifiedSoft,
                    foreground: SoftColors.verifiedInk,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Check your email', style: SoftType.hero.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                Text(
                  'If ${_emailController.text.trim()} is a registered eBPCO account, we sent a link to reset your password.',
                  style: SoftType.body.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 28),
                SoftPillButton(label: 'Back to Log In', onPressed: () => Navigator.of(context).pop()),
              ]
            : [
                Text('Account recovery', style: SoftType.eyebrow.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Reset your password', style: SoftType.hero.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                Text("Enter the email on your account and we'll send you a reset link.", style: SoftType.body.copyWith(fontSize: 15)),
                const SizedBox(height: 24),
                const SoftFieldLabel('Email'),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: SoftType.field,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: AppTypography.error),
                ],
                const SizedBox(height: 24),
                SoftPillButton(label: 'Send Reset Link', busy: _submitting, onPressed: _submit),
              ],
      ),
    );
  }
}
