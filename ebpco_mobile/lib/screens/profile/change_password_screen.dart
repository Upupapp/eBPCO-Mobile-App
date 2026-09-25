import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/password_policy.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../services/notifications_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/password_checklist.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../auth/login_screen.dart';

/// `POST /auth/password/change`. The server ends every session on the
/// account when the password changes, so — like the portal — a success signs
/// this device out and returns to Sign in rather than leaving it holding
/// tokens that no longer work. The server's own policy message is shown as
/// returned; the checklist is guidance, not the gate.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _next.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _next.text.isEmpty) {
      setState(() => _error = 'Enter your current password and a new one.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.changePassword(_current.text, _next.text);
      if (!mounted) return;
      await context.read<SessionService>().logout();
      if (!mounted) return;
      context.read<ApplicationsService>().clear();
      context.read<NotificationsService>().clear();
      context.read<BusinessesService>().clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed. Sign in again with your new password.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftFieldLabel(label),
          TextField(
            controller: controller,
            obscureText: _obscure,
            style: SoftType.field,
            decoration: InputDecoration(
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SoftColors.muted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionService>().profile;
    return SoftPageScaffold(
      title: 'Change Password',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _passwordField('Current Password', _current),
            _passwordField('New Password', _next),
            PasswordChecklist(
              password: _next.text,
              context_: PasswordContext(email: profile?.email, firstName: profile?.firstName, lastName: profile?.lastName),
            ),
            const SizedBox(height: 12),
            _passwordField('Confirm New Password', _confirm),
            Text('Changing your password signs you out on every device.', style: SoftType.cellLabel.copyWith(fontSize: 13)),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTypography.error),
            ],
            const SizedBox(height: 22),
            SoftPillButton(label: 'Change Password', busy: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
