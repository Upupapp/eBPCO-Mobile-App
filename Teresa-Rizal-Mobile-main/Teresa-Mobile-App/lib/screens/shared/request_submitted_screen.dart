import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import 'request_detail_screen.dart';

/// "Show confirmation" step from Section 5 — a dedicated success screen
/// (not just a toast) so the submission feels real and gives the citizen
/// their reference number to note down, mirroring how a real government
/// service confirms a filed request.
///
/// "Track This Request" navigates using THIS screen's own [context] rather
/// than accepting a `VoidCallback` built by whichever screen pushed this
/// one — that closure would capture the pushing screen's own context,
/// which `pushReplacement` disposes the moment this screen takes its
/// place. Tapping the button then throws "Looking up a deactivated
/// widget's ancestor is unsafe" and silently does nothing, which is
/// exactly the bug this shape avoids: [requestId] is plain data, safe to
/// carry across the replacement, and the navigation itself always runs
/// against this screen's own still-live context.
class RequestSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final String typeName;
  final Color accent;
  final String requestId;

  const RequestSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.typeName,
    required this.accent,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 44, color: AppColors.emerald500),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'Request Submitted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                typeName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.slate500),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  children: [
                    const Text(
                      'REFERENCE NUMBER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      referenceNumber,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Your request status is now "Submitted". You\'ll be notified as it moves through review, approval, and release.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.huge),
              AppButton(
                label: 'Track This Request',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: requestId)),
                ),
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
