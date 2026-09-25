import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'nav_item_data.dart';
import 'teresa_rizal_nav_motion.dart';

/// One branch cell. The label stays visible. The active icon lives on the
/// bar's single traveling bubble, so this cell hides its icon while selected.
class TeresaRizalNavItem extends StatelessWidget {
  final NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const TeresaRizalNavItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SoftColors.blue : SoftColors.muted;
    return Expanded(
      child: Semantics(
        label: item.label,
        button: true,
        selected: isActive,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height:
                TeresaRizalNavMotion.barHeight +
                TeresaRizalNavMotion.bubbleLift,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: TeresaRizalNavMotion.bubbleTop,
                  left: 0,
                  right: 0,
                  height: TeresaRizalNavMotion.bubbleDiameter,
                  child: Center(
                    child: isActive
                        ? const SizedBox.shrink()
                        : Icon(
                            item.outlineIcon,
                            color: color,
                            size: TeresaRizalNavMotion.iconSize,
                          ),
                  ),
                ),
                Positioned(
                  left: 2,
                  right: 2,
                  bottom: 8,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: SoftType.nav.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeresaRizalActiveBubble extends StatelessWidget {
  final NavItemData item;
  final bool reduced;

  const TeresaRizalActiveBubble({
    super.key,
    required this.item,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SoftColors.blue,
        shape: BoxShape.circle,
        boxShadow: SoftShadows.aperture,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: reduced
              ? TeresaRizalNavMotion.reducedDuration
              : TeresaRizalNavMotion.selection,
          switchInCurve: TeresaRizalNavMotion.selectionCurve,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Icon(
            item.filledIcon,
            key: ValueKey(item.label),
            color: SoftColors.white,
            size: TeresaRizalNavMotion.iconSize,
          ),
        ),
      ),
    );
  }
}
