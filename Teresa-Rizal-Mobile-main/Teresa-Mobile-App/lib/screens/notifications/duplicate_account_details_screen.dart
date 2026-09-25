import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';

/// Phase 6 — "One Person, One Account" duplicate-account simulation,
/// FRONTEND SIMULATION ONLY (see module doc). Opened from the original
/// Perlita Quiambao account's "Possible Duplicate Account Detected"
/// notification. [scenarioId] ('a' or 'b') lets the same flow be
/// demonstrated twice without resetting the app — see
/// NotificationsService.resolveDuplicateAlert, which persists which
/// choice was made per scenario so revisiting an already-resolved alert
/// shows its outcome instead of re-prompting.
///
/// This screen never claims to actually detect duplicates — the "match"
/// is preconfigured demo data representing what a future integrated
/// identity-matching system could surface, and it never exposes the
/// duplicate account's password, uploaded IDs, or other sensitive data;
/// only enough to let the citizen confirm whether the account is theirs.
class DuplicateAccountDetailsScreen extends StatelessWidget {
  final String scenarioId;
  const DuplicateAccountDetailsScreen({super.key, required this.scenarioId});

  // Deliberately does NOT pop back to the notification list after the
  // confirmation dialog closes — the screen rebuilds in place to show
  // _ResolvedCard instead, so the citizen (and a presenter demoing this
  // flow) can see the outcome was actually recorded rather than the
  // screen just vanishing.
  // The duplicate account is never terminated/deleted by this — it stays
  // reachable, just permanently Unverified (see
  // MockCatalog.duplicateVerifiedDemoAccount's own status comment). This screen
  // only records that the citizen confirmed ownership of both accounts.
  Future<void> _confirmSameOwner(BuildContext context, NotificationsService notifications) async {
    AppHaptics.medium();
    await notifications.resolveDuplicateAlert(scenarioId, 'confirmed');
    if (!context.mounted) return;
    await AppDialogs.info(
      context,
      title: 'Duplicate Account Confirmed',
      message:
          'Thank you for confirming that the other account also belongs to you. You may still access the account, '
          'but it cannot be upgraded to Verified status because Teresa, Rizal follows a one-person, '
          'one-verified-account policy. Please continue using your existing verified account for Dokyu, Tulong, '
          'and other verified resident services.',
    );
  }

  Future<void> _reportNotMe(BuildContext context, NotificationsService notifications) async {
    AppHaptics.warning();
    await notifications.resolveDuplicateAlert(scenarioId, 'reported');
    if (!context.mounted) return;
    await AppDialogs.info(
      context,
      title: 'Report Submitted',
      message: 'Thank you for confirming. The duplicate account has been flagged for administrative investigation.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsService>();
    final resolution = notifications.duplicateResolutionFor(scenarioId);

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Account Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_search_rounded, color: AppColors.amber700, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Duplicate Account Detected',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.amber700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Another account has been detected using information that appears to match your resident '
                    'profile. Please confirm whether you created this account.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'This is a preview of a future duplicate-detection feature — no password, uploaded ID, or other '
              'private information from the other account is shown here.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (resolution == null) ...[
              AppButton(
                label: 'Yes, this is me',
                fullWidth: true,
                onPressed: () => _confirmSameOwner(context, notifications),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'No, this is not me',
                variant: AppButtonVariant.danger,
                fullWidth: true,
                onPressed: () => _reportNotMe(context, notifications),
              ),
            ] else
              _ResolvedCard(resolution: resolution),
          ],
        ),
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  final String resolution;
  const _ResolvedCard({required this.resolution});

  @override
  Widget build(BuildContext context) {
    final confirmed = resolution == 'confirmed';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: confirmed ? AppColors.emerald50 : AppColors.rose50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (confirmed ? AppColors.emerald500 : AppColors.rose500).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                confirmed ? Icons.check_circle_outline_rounded : Icons.flag_outlined,
                color: confirmed ? AppColors.emerald700 : AppColors.rose700,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  confirmed ? 'Resolved: Confirmed — Duplicate Stays Unverified' : 'Resolved: Reported — Duplicate Flagged for Investigation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: confirmed ? AppColors.emerald700 : AppColors.rose700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            confirmed
                ? 'You confirmed this account belongs to you. It can still be used to browse general Teresa, Rizal '
                    'features, but it cannot be upgraded to Verified status — continue using your original, '
                    'verified account for Dokyu, Tulong, and other verified resident services.'
                : 'You reported this account does not belong to you. It has been flagged for administrative '
                    'investigation; no automatic suspension has been applied from this app.',
            style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
