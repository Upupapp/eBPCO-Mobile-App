import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A single removable "filter is active" pill — used in the row shown
/// under Dokyu/Tulong's search bar once any filter facet is set, so it's
/// obvious filtering is on and each facet can be cleared individually
/// without opening the full filter sheet again.
class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color? accent;

  const ActiveFilterChip({super.key, required this.label, required this.onRemove, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.brand600;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              textWidthBasis: TextWidthBasis.longestLine,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Icon(Icons.close_rounded, size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
