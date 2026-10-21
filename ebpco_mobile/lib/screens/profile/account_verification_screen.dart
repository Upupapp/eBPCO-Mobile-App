import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/problem.dart';
import '../../domain/account_verification.dart';
import '../../services/session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/account_verification_card.dart';
import '../../widgets/message_bar.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/valid_id_form.dart';

/// Profile > Account verification (ebpco-api 067): where the account
/// stands, and the valid ID to send (`PUT /me/verification`) while it is not
/// verified. Home's banner and the wizard's Submit step send citizens here.
class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() => _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  final _draft = ValidIdDraft();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The Municipality may have decided since the app last asked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionService>().refreshProfile().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final problem = _draft.problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<SessionService>().submitVerification(
            idType: _draft.idType!,
            idNumber: _draft.idNumber.text,
            front: _draft.front!,
            back: _draft.back,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        messageBar('Your ID was sent. You will be notified once your account is verified.'),
      );
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = verificationUploadMessage(e));
      // 409: verified meanwhile. Show it.
      if (e.status == 409) context.read<SessionService>().refreshProfile().catchError((_) {});
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = context.watch<SessionService>().verification;
    final verified = accountCanSubmit(verification);

    return SoftPageScaffold(
      title: 'Account verification',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (verification != null) AccountVerificationCard(verification: verification),
          if (!verified) ...[
            const SizedBox(height: 20),
            Text(
              verification?.isRejected == true ? 'Upload your valid ID again' : 'Upload a valid ID',
              style: SoftType.h1.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'The Municipality checks your ID before you can submit applications. '
              'You can prepare applications while you wait.',
              style: SoftType.body,
            ),
            const SizedBox(height: 18),
            ValidIdForm(
              draft: _draft,
              enabled: !_sending,
              onChanged: () => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: AppTypography.error)),
            SoftPillButton(label: 'Send for verification', busy: _sending, onPressed: _send),
          ],
        ],
      ),
    );
  }
}
