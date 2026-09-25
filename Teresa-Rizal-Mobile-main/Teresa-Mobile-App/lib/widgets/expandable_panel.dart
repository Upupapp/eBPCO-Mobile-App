import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// A single collapsible card — the FAQ/Privacy-Policy accordion item shared
/// by Help & Support and the Privacy Policy screen so long-form policy and
/// help content reads as scannable chunks instead of one continuous wall
/// of text.
class ExpandablePanel extends StatefulWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final bool initiallyExpanded;
  final GlobalKey? anchorKey;

  const ExpandablePanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.initiallyExpanded = false,
    this.anchorKey,
  });

  @override
  State<ExpandablePanel> createState() => _ExpandablePanelState();
}

class _ExpandablePanelState extends State<ExpandablePanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: widget.anchorKey,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (widget.iconColor ?? AppColors.brand500).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(widget.icon, size: 17, color: widget.iconColor ?? AppColors.brand600),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(child: Text(widget.title, style: AppTypography.cardTitle)),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate400),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: widget.child,
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple dot-bulleted list using the app's standard body text style —
/// the repeated "short list of plain-language items" shape used throughout
/// both the Privacy Policy and Help & Support content.
class BulletList extends StatelessWidget {
  final List<String> items;
  const BulletList(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: AppSpacing.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.slate400, shape: BoxShape.circle),
                    child: SizedBox(width: 4, height: 4),
                  ),
                ),
                Expanded(child: Text(item, style: AppTypography.body)),
              ],
            ),
          ),
      ],
    );
  }
}
