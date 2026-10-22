import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'soft_card.dart';

/// One answer of a single-choice question, as a card: an icon, the answer,
/// a line on what it means, and a radio mark. Sign-up's applicant type and
/// the wizard's "Applying as" use it. Without [onTap] the answer is not open:
/// shown faded, and [subtitle] should say why.
class SoftChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

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
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
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
                // Faded when not open; the line saying why stays readable.
                Opacity(opacity: enabled ? 1 : 0.45, child: SoftIconTile(icon: icon, size: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SoftType.tileTitle.copyWith(fontSize: 15.5, color: enabled ? null : SoftColors.muted),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: SoftType.tileSub),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  enabled
                      ? (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded)
                      : Icons.block_rounded,
                  color: selected && enabled ? SoftColors.primary : SoftColors.chevron,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
