import 'package:flutter/material.dart';

import '../../domain/legal_copy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  bool _showPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_showPrivacy ? 'Privacy Policy' : 'Terms & Conditions')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showPrivacy = false),
                      style: !_showPrivacy ? OutlinedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white) : null,
                      child: const Text('Terms'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showPrivacy = true),
                      style: _showPrivacy ? OutlinedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white) : null,
                      child: const Text('Privacy'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
                children: _showPrivacy
                    ? privacyPolicySections
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: SoftCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.heading, style: AppTypography.h3),
                                    const SizedBox(height: 8),
                                    for (final p in s.paragraphs)
                                      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(p, style: AppTypography.body)),
                                  ],
                                ),
                              ),
                            ))
                        .toList()
                    : [SoftCard(child: Text(termsConditionsText, style: AppTypography.body))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
