import 'package:flutter/material.dart';

import '../../domain/legal_copy.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_page.dart';

class LegalScreen extends StatefulWidget {
  final bool showPrivacy;
  const LegalScreen({super.key, this.showPrivacy = false});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late bool _showPrivacy = widget.showPrivacy;

  @override
  Widget build(BuildContext context) {
    return SoftPageScaffold(
      title: _showPrivacy ? 'Privacy Policy' : 'Terms & Conditions',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SoftColors.white,
                borderRadius: BorderRadius.circular(SoftRadius.pill),
                border: Border.all(color: SoftColors.line),
              ),
              child: Row(
                children: [
                  Expanded(child: _Segment(label: 'Terms', selected: !_showPrivacy, onTap: () => setState(() => _showPrivacy = false))),
                  Expanded(child: _Segment(label: 'Privacy', selected: _showPrivacy, onTap: () => setState(() => _showPrivacy = true))),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: _showPrivacy
                  ? [
                      for (final s in privacyPolicySections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SoftCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.heading, style: SoftType.section.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                for (final p in s.paragraphs)
                                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(p, style: SoftType.body.copyWith(color: SoftColors.ink))),
                              ],
                            ),
                          ),
                        ),
                    ]
                  : [SoftCard(child: Text(termsConditionsText, style: SoftType.body.copyWith(color: SoftColors.ink)))],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SoftColors.primary : SoftColors.clear,
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          boxShadow: selected ? SoftShadows.primary : null,
        ),
        child: Text(label, style: SoftType.button.copyWith(color: selected ? SoftColors.white : SoftColors.muted)),
      ),
    );
  }
}
