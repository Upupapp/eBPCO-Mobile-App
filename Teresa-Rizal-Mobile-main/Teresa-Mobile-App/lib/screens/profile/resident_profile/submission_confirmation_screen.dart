import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../profile_screen.dart';

/// Shown immediately after "Submit for LGU Verification" — confirms the
/// (local, simulated) submission and routes back to Profile (reached via
/// the hamburger drawer now that Profile is no longer a bottom tab).
class SubmissionConfirmationScreen extends StatelessWidget {
  const SubmissionConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, size: 44, color: AppColors.emerald500),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Profile Submitted',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your resident information has been submitted to Teresa, Rizal LGU for verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 15, color: AppColors.amber700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pending Verification',
                            textWidthBasis: TextWidthBasis.longestLine,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  AppButton(
                    label: 'Back to Profile',
                    size: AppButtonSize.lg,
                    fullWidth: true,
                    onPressed: () {
                      // Profile is no longer a bottom tab (moved into the
                      // hamburger drawer — see root_shell.dart) — land on
                      // Home, then push Profile on top of it.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
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
