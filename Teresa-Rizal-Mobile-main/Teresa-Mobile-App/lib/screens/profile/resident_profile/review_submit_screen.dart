import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_status_chip.dart';
import 'family_information_screen.dart';
import 'household_information_screen.dart';
import 'personal_information_screen.dart';
import 'submission_confirmation_screen.dart';

/// Final step — a read-only summary of all three sections with per-section
/// Edit links, gated on all three being SectionStatus.complete. Submitting
/// simulates the mobile -> Web Admin "Pending Validation" handoff locally.
class ReviewSubmitScreen extends StatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  bool _submitting = false;

  Future<void> _submit(String accountId) async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await context.read<ResidentProfileService>().submit(accountId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SubmissionConfirmationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account!;
    final profile = context.watch<ResidentProfileService>().profileFor(account);

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Submit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Check your information before submitting it to Teresa, Rizal LGU for verification.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SummaryCard(
              title: 'Personal Information',
              status: profile.personalStatus,
              onEdit: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
              rows: [
                profile.personal.fullName.trim().isEmpty ? '—' : profile.personal.fullName,
                if (profile.personal.barangay.isNotEmpty) 'Brgy. ${profile.personal.barangay}',
              ],
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              title: 'Family',
              status: profile.familyStatus,
              onEdit: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyInformationScreen())),
              rows: [
                profile.familyName.trim().isEmpty ? '—' : profile.familyName,
                'Head of Family: ${profile.headIndividual.fullName.isEmpty ? account.fullName : profile.headIndividual.fullName}',
                '${profile.allFamilyIndividuals.length} Member${profile.allFamilyIndividuals.length == 1 ? '' : 's'}',
              ],
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              title: 'Household',
              status: profile.householdStatus,
              onEdit: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HouseholdInformationScreen())),
              rows: [
                if (profile.household.barangay.isNotEmpty) 'Brgy. ${profile.household.barangay}',
                if (profile.household.sitioPurok.isNotEmpty) 'Sitio ${profile.household.sitioPurok}',
                '${profile.householdFamilyCount} Famil${profile.householdFamilyCount == 1 ? 'y' : 'ies'}',
                '${profile.householdResidentCount} Resident${profile.householdResidentCount == 1 ? '' : 's'}',
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.slate500),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Supporting Documents',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${profile.documentCount} Attached',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (!profile.readyToSubmit)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber700),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Complete Personal, Family, and Household Information before submitting.',
                        style: TextStyle(fontSize: 12, color: AppColors.amber700, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            AppButton(
              label: 'Submit for LGU Verification',
              icon: Icons.send_rounded,
              fullWidth: true,
              size: AppButtonSize.lg,
              loading: _submitting,
              onPressed: profile.readyToSubmit ? () => _submit(account.id) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final SectionStatus status;
  final VoidCallback onEdit;
  final List<String> rows;

  const _SummaryCard({required this.title, required this.status, required this.onEdit, required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Flexible (not a bare child): a non-flex sibling of Spacer()
              // is still measured at its unconstrained natural width during
              // Flex's first layout pass, so the chip's own internal
              // Flexible text does nothing here unless the chip itself is
              // also a flex participant.
              Flexible(child: SectionStatusChip(status: status)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                r,
                style: const TextStyle(fontSize: 13.5, color: AppColors.slate700, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
