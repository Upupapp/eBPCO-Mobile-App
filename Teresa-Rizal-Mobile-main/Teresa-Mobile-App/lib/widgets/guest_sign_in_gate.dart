import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth/register_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/soft_widget.dart';
import 'app_button.dart';
import 'soft_chrome.dart';

/// Bottom sheet for a Guest who hits a locked action.
///
/// Social likes, comments, and shares pass no [featureName] and use the
/// Pack B “Sign in to continue” copy. Profile and Digital ID pass the
/// destination name and keep that hub’s account copy.
Future<void> showGuestSignInGate(
  BuildContext context, [
  String? featureName,
  bool share = false,
]) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    barrierColor: SoftColors.ink.withValues(alpha: 0.55),
    builder: (_) => GuestSignInGate(featureName: featureName, share: share),
  );
}

class GuestSignInGate extends StatelessWidget {
  final String? featureName;
  final bool share;
  const GuestSignInGate({super.key, this.featureName, this.share = false});

  bool get _social => featureName == null;

  static const engageBody =
      'Likes, comments, and shares need a signed-in account. '
      'Guests can still read Balita and browse Events.';

  static const shareBody =
      'Sharing this post needs a signed-in account. '
      'Same gate as Like and Comment — not a Restricted Dokyu page.';

  static const simulationNote =
      'Frontend simulation — Guest / account gates are local '
      'preview state. No live LGU social backend.';

  @override
  Widget build(BuildContext context) {
    if (!_social) return _featureGate(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: SoftColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoftColors.line,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Sign in to continue', style: SoftType.h1),
              const SizedBox(height: 8),
              Text(share ? shareBody : engageBody, style: SoftType.body),
              if (!share) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SoftColors.blueWash,
                    borderRadius: BorderRadius.circular(SoftRadius.md),
                  ),
                  child: const Text(simulationNote, style: SoftType.body),
                ),
              ],
              const SizedBox(height: 16),
              SoftPillButton(
                label: 'Sign in',
                onPressed: () => _leaveGuest(context, register: false),
              ),
              const SizedBox(height: 10),
              SoftPillButton(
                label: 'Create account',
                kind: SoftPillKind.outline,
                onPressed: () => _leaveGuest(context, register: true),
              ),
              const SizedBox(height: 4),
              SoftPillButton(
                label: 'Not now',
                kind: SoftPillKind.text,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureGate(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SoftColors.white,
          borderRadius: BorderRadius.circular(SoftRadius.xl),
          border: Border.all(color: SoftColors.lineSoft),
          boxShadow: SoftShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoftColors.line,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: SoftStatusGuestMark(),
              ),
              const SizedBox(height: 12),
              Text(featureName!, style: SoftType.section),
              const SizedBox(height: 6),
              const Text(
                'This feature is available to registered Teresa, Rizal users. Create an account or sign in to continue.',
                style: SoftType.body,
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Create Account',
                fullWidth: true,
                onPressed: () => _leaveGuest(context, register: true),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Sign In',
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => _leaveGuest(context, register: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveGuest(
    BuildContext context, {
    required bool register,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await context.read<CitizenSessionService>().endGuestSession();
    nav.popUntil((route) => route.isFirst);
    if (register) {
      nav.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }
}

/// Small guest mark used at the top of the profile and Digital ID gate.
class SoftStatusGuestMark extends StatelessWidget {
  const SoftStatusGuestMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(SoftRadius.md),
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: SoftColors.blue,
      ),
    );
  }
}
