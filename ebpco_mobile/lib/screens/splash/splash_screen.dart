import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/login_screen.dart';
import '../home/root_shell.dart';
import '../../services/session_service.dart';

/// Every launch starts here: restores the stored session (if any), then
/// hands off to [LoginScreen] or [RootShell] — mirrors the design
/// reference's own splash → AuthGate handoff shape, but against a real
/// server call instead of a mock delay.
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
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => session.isSignedIn ? const RootShell() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary600,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Text('eBPCO', style: AppTypography.wordmark.copyWith(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              'Municipality of Castilla, Sorsogon',
              style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
