import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// A titled group of form fields inside a rounded card — the repeated
/// "Basic Information / Contact Information / Address / ..." grouping
/// used across the Resident Profile screens (Personal/Family/Household),
/// kept as one widget so their spacing/typography can't drift apart.
class FormSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const FormSection({super.key, required this.title, this.description, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(description!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35)),
          ],
          const SizedBox(height: AppSpacing.lg),
          // 18 (rather than the previous 14) gives adjacent fields — and
          // their labels/helper text — comfortable breathing room instead
          // of feeling compressed; especially relevant since some
          // Teresa, Rizal users are older adults who need clearly separated
          // touch targets and reading zones.
          for (int i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 18), children[i]],
        ],
      ),
    );
  }
}
