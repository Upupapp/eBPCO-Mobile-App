import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/register_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/soft_widget.dart';
import 'app_button.dart';
import 'soft_chrome.dart';

/// Why a feature is being withheld — drives which message/actions
/// [RestrictedFeatureNotice] shows. See Sections 6/7 of the nav-and-access
/// spec for the exact copy.
enum RestrictionReason { guestOnly, needsVerification }

/// Shown in place of a screen's real content when the signed-in-state
/// doesn't meet that screen's required [AccessLevel] (see AccessGuard).
/// Never navigates a Guest/unverified user into a broken or empty screen —
/// this is the one, reusable "you can't be here yet, here's what to do"
/// notice for the whole app.
class RestrictedFeatureNotice extends StatelessWidget {
  final RestrictionReason reason;
  final String featureName;

  const RestrictedFeatureNotice({
    super.key,
    required this.reason,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    final isGuest = reason == RestrictionReason.guestOnly;
    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isGuest
                            ? SoftColors.blueSoft
                            : SoftColors.pendingCream,
                        borderRadius: BorderRadius.circular(SoftRadius.md),
                      ),
                      child: Icon(
                        isGuest
                            ? Icons.lock_outline_rounded
                            : Icons.verified_user_outlined,
                        size: 18,
                        color: isGuest ? SoftColors.blue : SoftColors.pendingInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      featureName,
                      textAlign: TextAlign.center,
                      style: SoftType.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGuest
                          ? 'This feature is available to registered Teresa, Rizal users. Create an account or sign in to continue.'
                          : 'Complete your account verification to access this service.',
                      textAlign: TextAlign.center,
                      style: SoftType.body,
                    ),
                    const SizedBox(height: 24),
                    if (isGuest)
                      ..._guestActions(context)
                    else
                      ..._unverifiedActions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pop back to the root route instead of pushing a fresh LoginScreen/
  // RegisterScreen on top of an otherwise-emptied stack — see
  // teresa_rizal_drawer.dart's _goToAuth for the full explanation. The root
  // route is _AuthGate (main.dart), already reactively showing
  // LoginScreen once endGuestSession() completes; the previous
  // `pushAndRemoveUntil(..., (route) => false)` removed _AuthGate from
  // the stack entirely, so any later login()/logout() had nothing left
  // to react to — the root cause behind demo accounts appearing to "stop
  // opening" once reached through this notice.
  Future<void> _endGuestAndGoToRoot(BuildContext context) async {
    await context.read<CitizenSessionService>().endGuestSession();
    if (context.mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }
  }

  List<Widget> _guestActions(BuildContext context) => [
    AppButton(
      label: 'Create Account',
      icon: Icons.person_add_alt_1_rounded,
      fullWidth: true,
      size: AppButtonSize.lg,
      onPressed: () async {
        await _endGuestAndGoToRoot(context);
        if (context.mounted) {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
        }
      },
    ),
    const SizedBox(height: 10),
    AppButton(
      label: 'Sign In',
      variant: AppButtonVariant.secondary,
      fullWidth: true,
      onPressed: () => _endGuestAndGoToRoot(context),
    ),
  ];

  List<Widget> _unverifiedActions(BuildContext context) => [
    AppButton(
      label: 'Continue Verification',
      icon: Icons.arrow_forward_rounded,
      iconTrailing: true,
      fullWidth: true,
      size: AppButtonSize.lg,
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
    ),
  ];
}
