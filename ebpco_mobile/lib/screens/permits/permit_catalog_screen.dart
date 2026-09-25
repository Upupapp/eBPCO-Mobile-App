import 'package:flutter/material.dart';

import '../../domain/permit_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import 'application_wizard_screen.dart';

/// Ported grouping from `permit.model.ts`'s `PERMIT_TYPE_GROUPS` — see that
/// file's own comment on why this is the mirror, not a re-derivation.
class PermitCatalogScreen extends StatelessWidget {
  const PermitCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Permit Services')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 40),
          children: [
            Text('Browse permit types and start a new application.', style: AppTypography.body),
            const SizedBox(height: AppSpacing.xl),
            for (final group in permitTypeGroups) ...[
              Text(group.label, style: AppTypography.overline),
              const SizedBox(height: AppSpacing.sm),
              for (final type in group.types)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SoftCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationWizardScreen(permitType: type))),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary600, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(type, style: AppTypography.cardTitle)),
                        const Icon(Icons.chevron_right, color: AppColors.gray400),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}
