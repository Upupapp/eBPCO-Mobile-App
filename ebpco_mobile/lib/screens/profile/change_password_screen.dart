import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: 'Change Password',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SoftFieldLabel('Current Password'),
            TextField(controller: _current, obscureText: true, style: SoftType.field),
            const SizedBox(height: 16),
            const SoftFieldLabel('New Password'),
            TextField(controller: _next, obscureText: true, style: SoftType.field, decoration: const InputDecoration(hintText: 'At least 8 characters')),
            const SizedBox(height: 16),
            const SoftFieldLabel('Confirm New Password'),
            TextField(controller: _confirm, obscureText: true, style: SoftType.field),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTypography.error),
            ],
            const SizedBox(height: 26),
            SoftPillButton(label: 'Change Password', busy: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
