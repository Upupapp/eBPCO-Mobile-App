import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/legal_copy.dart';
import '../../domain/lgu_contact.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';

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

    return SoftPageScaffold(
      title: 'Help & Support',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Frequently asked questions and contact information.', style: SoftType.body.copyWith(fontSize: 15)),
          const SizedBox(height: 16),
          const SoftSectionHeader(title: 'FAQs'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, item) in _faqs.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: SoftColors.line),
                  InkWell(
                    onTap: () => setState(() => _open = _open == item.q ? null : item.q),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.q, style: SoftType.tileTitle)),
                              AnimatedRotation(
                                turns: _open == item.q ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.expand_more_rounded, color: SoftColors.muted),
                              ),
                            ],
                          ),
                          if (_open == item.q) ...[
                            const SizedBox(height: 8),
                            Text(item.a, style: SoftType.body),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SoftSectionHeader(title: 'Contact'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftIconTile(icon: Icons.place_outlined, size: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Text(municipalHallAddress, style: SoftType.body.copyWith(color: SoftColors.ink))),
                  ],
                ),
                for (final office in offices) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: SoftColors.line)),
                  Text(office.name, style: SoftType.tileTitle.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(office.handles, style: SoftType.tileSub),
                  const SizedBox(height: 8),
                  if (office.mobile != null) Text('Mobile: ${office.mobile}', style: SoftType.body.copyWith(color: SoftColors.ink)),
                  GestureDetector(
                    onTap: () => _copyEmail(office.email),
                    child: Text('Email: ${office.email}', style: SoftType.body.copyWith(color: SoftColors.primary)),
                  ),
                ],
                const SizedBox(height: 14),
                Text(inquiryTurnaround, style: SoftType.body),
                const SizedBox(height: 14),
                SoftPillButton(
                  label: 'Email the ${municipalEngineer.shortName}',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () => _copyEmail(municipalEngineer.email),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
