import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../theme/soft_widget.dart';
import '../auth/login_screen.dart';
import '../home/root_shell.dart';
import '../onboarding/onboarding_screen.dart';

/// Every launch starts here — the design reference's splash (one solid
/// brand color, the seal in rings, nothing else) in eBPCO red. Restores the
/// stored session against the real API, then hands off: signed in →
/// [RootShell]; first run → [OnboardingScreen]; otherwise [LoginScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final session = context.read<SessionService>();
    await session.restore();
    final onboardingDone = await OnboardingPrefs.isDone();
    if (!mounted) return;
    final Widget next = session.isSignedIn
        ? const RootShell()
        : onboardingDone
        ? const LoginScreen()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next,
        transitionDuration: const Duration(milliseconds: 380),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoftColors.primaryDeep,
        body: Stack(
          children: [
            Center(
              child: Container(
                width: 196,
                height: 196,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: SoftColors.white, width: 4),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SoftColors.white,
                    border: Border.all(color: SoftColors.gold, width: 5),
                  ),
                  child: Image.asset(
                    'assets/images/ebpco_seal.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: SoftColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
