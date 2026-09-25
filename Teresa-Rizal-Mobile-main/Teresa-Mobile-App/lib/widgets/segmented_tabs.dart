import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';

/// A reusable pill/segmented tab control — same visual language reused for
/// the request Active/Done tabs and the Balita/Events tabs. Segments are
/// equal-width (via Expanded) so switching never shifts layout, and each
/// segment is padded to a comfortable tap target rather than relying on
/// tiny text-only hit areas.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.accent = AppColors.brand600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: SoftColors.blueWash, borderRadius: BorderRadius.circular(SoftRadius.pill)),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                accent: accent,
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? SoftColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            boxShadow: selected
                ? [BoxShadow(color: AppElevation.tabPillShadow, blurRadius: 6, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? accent : SoftColors.muted),
          ),
        ),
      ),
    );
  }
}
