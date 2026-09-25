import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/legal_copy.dart';
import '../../domain/lgu_contact.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';

/// Every contact value here comes from `domain/lgu_contact.dart`, itself
/// transcribed from bundled LGU documents on the web portal — never a
/// number, address or mailbox invented for this screen. Mirrors
/// `help-support.page.ts`.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

const _faqs = [
  (
    q: 'How do I apply for a permit?',
    a: 'Go to Permit Services, choose the permit type for your project, review the required documents, then start '
        'the application wizard.',
  ),
  (
    q: 'How long does processing take?',
    a: 'Processing time varies by permit type and depends on document completeness and evaluation by the reviewing '
        'office (OBO, Zoning, or BFP).',
  ),
  (
    q: 'Can I edit my application after submission?',
    a: 'Once submitted, you cannot edit an application directly, but if the reviewing office marks it "Revision '
        'Required," you can resubmit the requested documents.',
  ),
  (
    q: 'What payment methods are accepted?',
    a: 'Onsite payment at the Office of the Municipal Engineer. Bank transfer is not available yet — the '
        'Municipality has not published a deposit account, so do not transfer permit fees to any account you have '
        'not confirmed with the Municipality directly.',
  ),
  (
    q: 'Is my data secure?',
    a: '$privacyPolicyText Your data is never shared with another citizen\'s account. See the Privacy Policy for '
        'the full detail, including what the Municipality has not yet published.',
  ),
];

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String? _open;

  Future<void> _copyEmail(String email) async {
    try {
      await Clipboard.setData(ClipboardData(text: email));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$email copied to your clipboard.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not copy automatically — the address is $email.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const offices = [municipalEngineer, planningAndDevelopment];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Text('Frequently asked questions and contact information.', style: AppTypography.body),
            const SizedBox(height: AppSpacing.lg),
            SoftCard(
              child: Column(
                children: _faqs
                    .map((item) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _open = _open == item.q ? null : item.q),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(item.q, style: AppTypography.bodyMedium),
                              ),
                            ),
                            if (_open == item.q)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(item.a, style: AppTypography.caption),
                              ),
                            const Divider(height: 1, color: AppColors.borderLight),
                          ],
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact', style: AppTypography.h3),
                  const SizedBox(height: 4),
                  Text(municipalHallAddress, style: AppTypography.caption),
                  for (final office in offices) ...[
                    const Divider(height: AppSpacing.xxl, color: AppColors.borderLight),
                    Text(office.name, style: AppTypography.bodyMedium),
                    Text(office.handles, style: AppTypography.caption),
                    const SizedBox(height: 4),
                    if (office.mobile != null) Text('Mobile: ${office.mobile}', style: AppTypography.body),
                    GestureDetector(
                      onTap: () => _copyEmail(office.email),
                      child: Text('Email: ${office.email}', style: AppTypography.body.copyWith(color: AppColors.primary600)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(inquiryTurnaround, style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => _copyEmail(municipalEngineer.email),
                    child: Text('Email the ${municipalEngineer.shortName}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
