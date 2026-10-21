import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'soft_card.dart';

/// One answer of a single-choice question, as a card: an icon, the answer,
/// a line on what it means, and a radio mark. Sign-up's applicant type and
/// the wizard's "Applying as" use it.
class SoftChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SoftChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SoftRadius.md);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? SoftColors.primaryWash : SoftColors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: selected ? SoftColors.primary : SoftColors.line, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                SoftIconTile(icon: icon, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SoftType.tileTitle.copyWith(fontSize: 15.5)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: SoftType.tileSub),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? SoftColors.primary : SoftColors.chevron,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
