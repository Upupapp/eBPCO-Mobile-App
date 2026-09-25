import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

/// The design reference's modular card: white, 22px radius, the soft
/// 28px-blur shadow and a hairline border ([SoftRadius.lg],
/// [SoftShadows.card], [SoftColors.lineSoft]). [tone] tints the surface
/// for callouts (the reference's cream/wash cards).
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool shadow;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = SoftRadius.lg,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // A tinted callout sits flat on the wash (the reference's cream/wash
    // cards carry no shadow); a white card floats.
    final plain = color == null || color == SoftColors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow && plain ? SoftShadows.card : null,
      ),
      child: Material(
        color: color ?? SoftColors.white,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: plain ? Border.all(color: SoftColors.lineSoft) : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A rounded-square icon tile on the soft tint — the reference's list-row
/// and services-sheet leading icon.
class SoftIconTile extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  const SoftIconTile({
    super.key,
    required this.icon,
    this.background = SoftColors.primarySoft,
    this.foreground = SoftColors.primary,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(SoftRadius.sm)),
      child: Icon(icon, color: foreground, size: size * 0.45),
    );
  }
}
