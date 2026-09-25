import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

const double _cardRadius = AppRadius.lg;

/// The one repeated "modular card" shape every screen composes with —
/// rounded corners, soft diffused shadow, generous internal padding. This
/// is the structural piece of the design reference's "soft-widget shell"
/// this app keeps (per the owner's "design/look only" instruction), built
/// fresh against eBPCO's own token set rather than importing the
/// reference's much larger, feature-specific `soft_widget.dart`.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
