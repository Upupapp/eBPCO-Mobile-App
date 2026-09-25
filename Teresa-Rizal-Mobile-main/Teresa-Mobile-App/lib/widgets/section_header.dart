import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded is required here: a Row with no flex child sizes each
          // child to its own unbounded natural width, so a long title next
          // to the "View all" action can overflow horizontally instead of
          // respecting the row's actual available width.
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.h3),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.brand600),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brand600),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
