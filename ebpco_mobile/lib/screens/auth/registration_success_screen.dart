import 'package:flutter/material.dart';

import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../home/root_shell.dart';
import 'login_screen.dart';

/// After Create Account. Sign-up also signs in and sends the valid ID
/// ([signedIn], [idSent]); when either did not happen, the citizen is told to
/// sign in and upload the ID under Profile > Account verification, without
/// saying why (it must never reveal whether the email was already in use).
class RegistrationSuccessScreen extends StatelessWidget {
  final bool signedIn;
  final bool idSent;

  const RegistrationSuccessScreen({super.key, this.signedIn = false, this.idSent = false});

  /// What the screen says, for the three ways sign-up can end.
  static String messageFor({required bool signedIn, required bool idSent}) {
    if (signedIn && idSent) {
      return 'Your eBPCO account is ready, and your ID is waiting for verification by the Municipality. '
          'You will be notified once your account is verified. You can prepare applications while you wait.';
    }
    if (signedIn) {
      return 'Your eBPCO account is ready, but your ID could not be sent. Upload it under '
          'Profile > Account verification. The Municipality checks your ID before you can submit applications.';
    }
    return 'Your eBPCO account is ready. Sign in, then upload your valid ID under Profile > Account verification. '
        'The Municipality checks your ID before you can submit applications.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Signed in already: Back would land on Sign in.
      canPop: !signedIn,
      child: SoftWash(
        child: Scaffold(
          backgroundColor: SoftColors.clear,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: SoftColors.primary, shape: BoxShape.circle, boxShadow: SoftShadows.feature),
                    child: const Icon(Icons.check_rounded, color: SoftColors.white, size: 52),
                  ),
                  const SizedBox(height: 28),
                  Text('Account created', style: SoftType.hero.copyWith(fontSize: 32), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    messageFor(signedIn: signedIn, idSent: idSent),
                    style: SoftType.body.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  if (signedIn)
                    SoftPillButton(
                      label: 'Continue',
                      onPressed: () => Navigator.of(context)
                          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (route) => false),
                    )
                  else
                    SoftPillButton(
                      label: 'Go to Log In',
                      onPressed: () => Navigator.of(context)
                          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
