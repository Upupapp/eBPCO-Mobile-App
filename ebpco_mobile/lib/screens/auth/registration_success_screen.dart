import 'package:flutter/material.dart';

import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import 'login_screen.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftWash(
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
                  'Your eBPCO account is ready. Sign in to browse permits and file your first application.',
                  style: SoftType.body.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SoftPillButton(
                  label: 'Go to Log In',
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
