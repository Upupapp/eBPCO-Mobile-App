import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';

/// One selectable payment method option on a Dokyu application's own
/// Payment Method step (ServiceRequestWizardScreen and NewRequestScreen
/// both use it — see the Mobile-only final request-flow correction pass:
/// payment now happens during the application/submission flow itself,
/// before a request exists, never as a later tracking milestone).
/// Rendered inline as a normal step body with a persistent
/// selected/unselected state instead of popping on tap like the older
/// PaymentMethodSheet bottom sheet, since this step needs its own
/// Continue/Confirm Payment button below it rather than resolving the
/// moment one is chosen.
class PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool demo;
  final bool selected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.demo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? iconColor.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? iconColor : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: SoftColors.ink),
                          ),
                        ),
                        if (demo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(999)),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.amber700, letterSpacing: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: SoftColors.muted, height: 1.3)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? iconColor : SoftColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
