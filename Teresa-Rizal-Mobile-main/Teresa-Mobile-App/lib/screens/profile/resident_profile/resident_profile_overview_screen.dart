import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/section_status_chip.dart';
import '../g6/household_info_screen.dart';
import '../g6/household_screen.dart';
import 'personal_information_screen.dart';
import 'review_submit_screen.dart';

/// Resident Profile hub — the mobile-side entry point that maps to the Web
/// Admin's Constituents module. Guides the citizen through Personal ->
/// Family -> Household -> Review & Submit, letting them jump straight to
/// any section to continue editing rather than forcing a linear restart.
class ResidentProfileOverviewScreen extends StatelessWidget {
  const ResidentProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account!;
    final profile = context.watch<ResidentProfileService>().profileFor(account);

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Complete your information so Teresa, Rizal LGU can maintain an accurate resident and household record.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProgressCard(profile: profile),
            if (profile.status == VerificationStatus.needsCorrection) ...[
              const SizedBox(height: AppSpacing.lg),
              _CorrectionBanner(
                message: profile.correctionMessage ?? 'Some information needs to be updated.',
                onUpdate: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
              ),
            ],
            if (profile.status == VerificationStatus.pendingVerification) ...[
              const SizedBox(height: AppSpacing.lg),
              _DemoVerificationPanel(accountId: account.id),
            ],
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'Sections',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SectionCard(
              icon: Icons.badge_outlined,
              title: 'Personal Information',
              description: 'Your basic, contact, and address details.',
              status: profile.personalStatus,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.diversity_3_outlined,
              title: 'Family Information',
              description: 'Tell us about your family members living with you.',
              status: profile.familyStatus,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const G6HouseholdScreen())),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.home_work_outlined,
              title: 'Household Information',
              description: 'Your residence, utilities, and who you live with.',
              status: profile.householdStatus,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const G6HouseholdInfoScreen())),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.fact_check_outlined,
              title: 'Review & Submit',
              description: profile.readyToSubmit
                  ? 'Everything looks good — review and submit for verification.'
                  : 'Complete all sections above to submit.',
              status: null,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewSubmitScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ResidentProfile profile;
  const _ProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final pct = profile.overallCompletionPercent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$pct% Complete',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (profile.status != VerificationStatus.draft && profile.status != VerificationStatus.incomplete) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  profile.status.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand500),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.status.citizenMessage,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final SectionStatus? status;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 21, color: AppColors.brand600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (status != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SectionStatusChip(status: status!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }
}

class _CorrectionBanner extends StatelessWidget {
  final String message;
  final VoidCallback onUpdate;
  const _CorrectionBanner({required this.message, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose500.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: AppColors.rose600),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Needs Correction',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.rose700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 12.5, color: AppColors.rose700, height: 1.4)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Update Information',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.sm,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

/// DEMO-ONLY: lets the citizen preview what an LGU verifier acting on the
/// Web Admin's Pending Validation queue would do — mirrors
/// RequestDetailScreen's `_DemoAdminPanel` pattern used elsewhere in this
/// app for the same "no backend yet" reason.
class _DemoVerificationPanel extends StatefulWidget {
  final String accountId;
  const _DemoVerificationPanel({required this.accountId});

  @override
  State<_DemoVerificationPanel> createState() => _DemoVerificationPanelState();
}

class _DemoVerificationPanelState extends State<_DemoVerificationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: AppColors.amber500),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Demo: Simulate LGU Verification',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.amber700),
                  ),
                ),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.slate400),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No real Web Admin connection exists yet — this previews how an LGU verifier\'s decision would appear on your profile.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Mark Verified',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () async {
                      await context.read<ResidentProfileService>().simulateVerify(widget.accountId);
                      if (context.mounted) AppDialogs.toast(context, 'Resident profile verified (simulated).');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Needs Correction',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () async {
                      await context.read<ResidentProfileService>().simulateNeedsCorrection(
                        widget.accountId,
                        'Please provide your complete Sitio / Purok.',
                      );
                      if (context.mounted) {
                        AppDialogs.toast(context, 'Marked as needing correction (simulated).', success: false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
