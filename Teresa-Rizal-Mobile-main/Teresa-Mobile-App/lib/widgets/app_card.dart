import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';

/// Mirrors `resources/views/components/ui/card.blade.php`: white surface,
/// rounded-2xl (16px), slate-100 border, soft card shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg), this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.line),
        boxShadow: SoftShadows.cardSm,
      ),
      // A transparent Material so descendants have somewhere to paint ink.
      //
      // Without it a non-tappable card gave its children no Material ancestor,
      // and any ListTile inside one rendered with no ripple and no tileColor —
      // Flutter says so out loud ("ListTile background color or ink splashes
      // may be invisible") but only at runtime on a device, which is why the
      // widget suite never saw it. Settings was the visible case: four
      // notification and language controls that changed value with no feedback
      // at all under the finger. Found by the FE 03 device walk.
      //
      // `transparency` paints nothing itself, so the card's own decoration,
      // border and shadow above are unchanged.
      child: Material(type: MaterialType.transparency, child: child),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: InkWell(borderRadius: BorderRadius.circular(SoftRadius.lg), onTap: onTap, child: content),
    );
  }
}
