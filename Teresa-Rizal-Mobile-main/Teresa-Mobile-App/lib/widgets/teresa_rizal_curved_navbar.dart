import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'nav_item_data.dart';
import 'teresa_rizal_nav_item.dart';
import 'teresa_rizal_nav_motion.dart';
import 'teresa_rizal_services_action.dart';

/// Soft-widget pill with Servana slot behavior: four branch tabs and a
/// raised Services control in the center. The class name stays so the
/// shell and the nav tests still have one widget to drive.
///
/// The aperture is one [IgnorePointer] bubble owned by the bar. It travels
/// only across branch slots. Services never takes [activeIndex].
class TeresaRizalCurvedNavBar extends StatelessWidget {
  final List<NavItemData> items;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterPressed;

  const TeresaRizalCurvedNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onCenterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = TeresaRizalNavMotion.reduced(context);
    final branch = activeIndex < 0 || activeIndex >= items.length
        ? 0
        : activeIndex;
    final active = items[branch];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TeresaRizalNavMotion.sideInset,
          0,
          TeresaRizalNavMotion.sideInset,
          TeresaRizalNavMotion.bottomInset,
        ),
        child: SizedBox(
          height:
              TeresaRizalNavMotion.barHeight + TeresaRizalNavMotion.bubbleLift,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final left = TeresaRizalNavMotion.bubbleLeft(
                width: constraints.maxWidth,
                branchIndex: branch,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: TeresaRizalNavMotion.bubbleLift,
                    left: 0,
                    right: 0,
                    height: TeresaRizalNavMotion.barHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          TeresaRizalNavMotion.surfaceRadius,
                        ),
                        boxShadow: SoftShadows.nav,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          TeresaRizalNavMotion.surfaceRadius,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: DecoratedBox(
                            key: const ValueKey('nav-bar-shape'),
                            decoration: BoxDecoration(
                              color: SoftColors.navFill,
                              borderRadius: BorderRadius.circular(
                                TeresaRizalNavMotion.surfaceRadius,
                              ),
                              border: Border.all(color: SoftColors.line),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i == 2)
                          Expanded(
                            child: TeresaRizalServicesAction(
                              onPressed: onCenterPressed,
                            ),
                          ),
                        TeresaRizalNavItem(
                          item: items[i],
                          isActive: i == branch,
                          onTap: () => onTabSelected(i),
                        ),
                      ],
                    ],
                  ),
                  AnimatedPositioned(
                    key: const ValueKey('nav-floating-indicator'),
                    duration: TeresaRizalNavMotion.selectionFor(context),
                    curve: TeresaRizalNavMotion.selectionCurve,
                    left: left,
                    top: TeresaRizalNavMotion.bubbleTop,
                    width: TeresaRizalNavMotion.bubbleDiameter,
                    height: TeresaRizalNavMotion.bubbleDiameter,
                    child: IgnorePointer(
                      child: TeresaRizalActiveBubble(
                        item: active,
                        reduced: reduced,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
