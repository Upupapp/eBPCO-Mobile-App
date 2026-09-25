import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_status.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'status_chip.dart';

/// Explains an account's verification state in plain language, not just a
/// status label — Section 10's "the mobile user should clearly understand
/// what they need to do next." Reuses the same universal AppStatus
/// vocabulary as service requests (see theme/app_status.dart) rather than
/// a parallel enum, so `account.status` is the one place this ever reads
/// from. Used on the Profile screen and at the end of the registration
/// wizard.
class VerificationStatusPanel extends StatelessWidget {
  final AppStatus status;
  final VoidCallback? onAction;

  const VerificationStatusPanel({super.key, required this.status, this.onAction});

  IconData get _icon => switch (status) {
    AppStatus.approved => Icons.verified_rounded,
    AppStatus.rejected => Icons.error_outline_rounded,
    AppStatus.underVerification => Icons.fact_check_outlined,
    _ => Icons.hourglass_top_rounded,
  };

  String get _explanation => switch (status) {
    AppStatus.pendingReview =>
      'Teresa, Rizal LGU is reviewing your submitted information. This usually takes 1–3 business days — no action needed from you right now.',
    AppStatus.underVerification =>
      'Some of your details need a closer look from Teresa, Rizal LGU staff. No action needed from you right now.',
    AppStatus.approved => 'Your account has been verified. You now have full access to Teresa, Rizal mobile services.',
    AppStatus.rejected =>
      'Your submission needs corrections before it can be verified. Please review and resubmit your information.',
    _ => 'Complete your registration to begin the verification process.',
  };

  String? get _actionLabel => switch (status) {
    AppStatus.rejected => 'Resubmit Information',
    AppStatus.draft => 'Continue Registration',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final actionLabel = _actionLabel;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: status.style.background, borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, size: 19, color: status.style.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Verification',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    // StatusChip and this title never share a Row: the
                    // longest AppStatus label ("Under Verification") next
                    // to a title in the same Row is exactly the pattern
                    // that caused repeated RenderFlex overflows elsewhere
                    // in this app (a non-flex StatusChip sibling of an
                    // Expanded title gets measured at its unconstrained
                    // natural width). Each on its own line sidesteps it
                    // entirely rather than relying on Flexible tricks.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(status: status),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_explanation, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel,
              variant: status == AppStatus.rejected ? AppButtonVariant.danger : AppButtonVariant.primary,
              size: AppButtonSize.sm,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
