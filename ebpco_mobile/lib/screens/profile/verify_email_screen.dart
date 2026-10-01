import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../services/session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/message_bar.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

/// Confirming the email of an account created before sign-up asked for a
/// code (merged from eBPCOMobile's contact verification). Sign-up tells a
/// citizen who skips the code that they can "verify this email later from
/// your Profile"; this is that. A code goes to the account's own email
/// (`POST /me/contacts/email/request`) and the six digits confirm it
/// (`/confirm`), which marks the email verified for the office too.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _sending = false;
  bool _confirming = false;
  bool _codeSent = false;
  String? _notice;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _notice = null;
      _error = null;
    });
    try {
      final result = await CitizenApi.instance.requestMyEmailCode();
      if (!mounted) return;
      if (result.kind == 'already-verified') {
        await _verified();
        return;
      }
      setState(() {
        _codeSent = result.kind == 'sent' || result.kind == 'too-soon';
        _notice = result.kind == 'sent' ? 'A 6-digit code was sent. It expires in a few minutes.' : result.detail;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.citizenMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the Municipality’s system. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code exactly as sent.');
      return;
    }
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await CitizenApi.instance.confirmMyEmailCode(code);
      if (mounted) await _verified();
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.citizenMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the Municipality’s system. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _verified() async {
    await context.read<SessionService>().refreshProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(messageBar('Your email address is verified.'));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<SessionService>().profile?.email ?? '';
    return SoftPageScaffold(
      title: 'Verify Email',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Confirm your email', style: SoftType.h1),
          const SizedBox(height: 6),
          Text(
            'The Municipality sends notices about your applications to this address. We will send a 6-digit code '
            'to it; enter the code here to confirm it is yours.',
            style: SoftType.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Email address', style: SoftType.cellLabel),
                const SizedBox(height: 4),
                Text(email, style: SoftType.tileTitle),
                const SizedBox(height: 14),
                SoftPillButton(
                  label: _codeSent ? 'Send a new code' : 'Send code',
                  kind: _codeSent ? SoftPillKind.outline : SoftPillKind.primary,
                  icon: Icons.mark_email_unread_outlined,
                  busy: _sending,
                  onPressed: _sending ? null : _send,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          style: SoftType.field,
                          decoration: const InputDecoration(hintText: '6-digit code'),
                          onSubmitted: (_) => _confirm(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(width: 110, child: SoftPillButton(label: 'Confirm', busy: _confirming, onPressed: _confirming ? null : _confirm)),
                    ],
                  ),
                ],
                if (_notice != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_notice!, style: SoftType.cellLabel)),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: AppTypography.error)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'If the code does not arrive, check your spam folder, or ask the office to confirm your email for you.',
            style: SoftType.tileSub,
          ),
        ],
      ),
    );
  }
}
