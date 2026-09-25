import 'package:flutter/material.dart';
import '../models/resident_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';

/// The Resident Profile status card — used identically on both the Home
/// screen and the Profile screen, reading the same ResidentProfile so the
/// two never show conflicting numbers (Section 12's "one shared source of
/// truth"). Renders one of four states: incomplete/draft, pending
/// verification, needs correction, or verified.
class ResidentProfileStatusCard extends StatelessWidget {
  final ResidentProfile profile;
  final VoidCallback onTap;

  const ResidentProfileStatusCard({super.key, required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return switch (profile.status) {
      VerificationStatus.verified => _buildVerified(),
      VerificationStatus.pendingVerification => _buildPending(),
      VerificationStatus.needsCorrection => _buildNeedsCorrection(),
      VerificationStatus.draft || VerificationStatus.incomplete => _buildIncomplete(),
    };
  }

  Widget _buildIncomplete() {
    final pct = profile.overallCompletionPercent;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(Icons.badge_outlined, AppColors.brand50, AppColors.brand600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Resident Profile',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.slate100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.brand500),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Complete your resident and household information.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: pct == 0 ? 'Complete Resident Profile' : 'Continue Resident Profile',
                  icon: Icons.arrow_forward_rounded,
                  iconTrailing: true,
                  size: AppButtonSize.sm,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPending() {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(Icons.hourglass_top_rounded, AppColors.amber50, AppColors.amber700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resident Profile',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _pill('Pending LGU Verification', AppColors.amber50, AppColors.amber700),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Your submitted information is currently being reviewed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }

  Widget _buildNeedsCorrection() {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(Icons.error_outline_rounded, AppColors.rose50, AppColors.rose600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resident Profile',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _pill('Needs Correction', AppColors.rose50, AppColors.rose600),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.correctionMessage ?? 'Some information needs to be updated.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Update Information',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.danger,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerified() {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(Icons.verified_rounded, AppColors.emerald50, AppColors.emerald700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resident Profile',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _pill('Verified', AppColors.emerald50, AppColors.emerald700),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Your resident profile has been verified by Teresa, Rizal LGU.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color bg, Color fg) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 19, color: fg),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
