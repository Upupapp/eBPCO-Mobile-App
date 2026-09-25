import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/soft_widget.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, gold }

enum AppButtonSize { sm, md, lg }

/// Button variants mirror `resources/views/components/ui/button.blade.php`
/// 1:1 — same 5 variants (primary/secondary/ghost/danger/gold), same 3
/// sizes. Every screen must use this instead of raw ElevatedButton so
/// styling stays centralized (Section 2 of the alignment doc).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconTrailing;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconTrailing = false,
    this.loading = false,
    this.fullWidth = false,
  });

  EdgeInsets get _padding => switch (size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    AppButtonSize.md => const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: AppSpacing.md,
    ),
    AppButtonSize.lg => const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: 15,
    ),
  };

  double get _fontSize =>
      size == AppButtonSize.lg ? 15 : (size == AppButtonSize.sm ? 12.5 : 14);

  _VariantStyle get _colors => switch (variant) {
    AppButtonVariant.primary => _VariantStyle(
      background: SoftColors.blue,
      foreground: SoftColors.white,
      border: null,
    ),
    AppButtonVariant.secondary => _VariantStyle(
      background: SoftColors.white,
      foreground: SoftColors.ink,
      border: SoftColors.line,
    ),
    AppButtonVariant.ghost => _VariantStyle(
      background: SoftColors.clear,
      foreground: SoftColors.muted,
      border: null,
    ),
    AppButtonVariant.danger => _VariantStyle(
      background: AppColors.rose600,
      foreground: Colors.white,
      border: null,
    ),
    AppButtonVariant.gold => _VariantStyle(
      background: AppColors.gold400,
      foreground: AppColors.navy950,
      border: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    // A null handler is not tappable. Keep the loading spinner on the
    // active fill; every other disabled primary uses the soft muted fill
    // with no elevation.
    final disabled = onPressed == null && !loading;
    final background = disabled ? SoftColors.chipWash : c.background;
    final foreground = disabled ? SoftColors.muted : c.foreground;
    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null && !iconTrailing) ...[
          Icon(
            icon,
            size: size == AppButtonSize.lg ? 18 : 16,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              color: foreground,
              fontSize: _fontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!loading && icon != null && iconTrailing) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            icon,
            size: size == AppButtonSize.lg ? 18 : 16,
            color: foreground,
          ),
        ],
      ],
    );

    // Announced as a button, with its label, as one node.
    //
    // `InkWell` contributes a tap action and nothing else, so until 2026-08-30
    // every AppButton in the app reached a screen reader as a piece of text
    // that happened to be tappable — never as a button, and never with its
    // enabled/disabled state. `MergeSemantics` is what puts the flag and the
    // label on the same node rather than two siblings.
    //
    // Fixed here rather than at one call site because it is the same omission
    // everywhere, and a rule enforced in one of many places is the shape of
    // defect this repository keeps finding.
    final showPrimaryShadow = variant == AppButtonVariant.primary && !disabled;
    Widget button = Material(
      color: background,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: loading ? null : onPressed,
        child: Container(
          padding: _padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: c.border != null ? Border.all(color: c.border!) : null,
          ),
          child: child,
        ),
      ),
    );
    if (showPrimaryShadow) {
      button = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
          boxShadow: SoftShadows.primary,
        ),
        child: button,
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !loading && onPressed != null,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          child: button,
        ),
      ),
    );
  }
}

class _VariantStyle {
  final Color background;
  final Color foreground;
  final Color? border;
  _VariantStyle({
    required this.background,
    required this.foreground,
    this.border,
  });
}
