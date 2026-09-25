import 'package:flutter/material.dart';

import '../core/magnetic_navbar_core.dart';
import '../core/nav_item_data.dart';

/// The 5-destination magnetic navbar: Home, Category, Cart, Profile,
/// Settings. Same shared engine as [FourIconNavbar]
/// (`../4-icons/four_icon_navbar.dart`) — only the destinations and their
/// calibrated active-center positions differ.
///
/// The caller still owns selection state:
/// ```dart
/// FiveIconNavbar(
///   currentIndex: _currentIndex,
///   onTap: (i) => setState(() => _currentIndex = i),
/// )
/// ```
class FiveIconNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FiveIconNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const items = [
    NavItemData(
      outlineIcon: Icons.home_outlined,
      filledIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItemData(
      outlineIcon: Icons.grid_view_outlined,
      filledIcon: Icons.grid_view_rounded,
      label: 'Category',
    ),
    NavItemData(
      outlineIcon: Icons.shopping_bag_outlined,
      filledIcon: Icons.shopping_bag_rounded,
      label: 'Cart',
    ),
    NavItemData(
      outlineIcon: Icons.person_outline_rounded,
      filledIcon: Icons.person_rounded,
      label: 'Profile',
    ),
    NavItemData(
      outlineIcon: Icons.settings_outlined,
      filledIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  // Even fifths — (i + 0.5) / 5, the same equal-division calibration method
  // used for the 4-icon preset, just re-derived for five columns. Home and
  // Settings land at 0.1 / 0.9 (a touch closer to the edge than the 4-icon
  // preset's 0.125 / 0.875, since each column is narrower with five of
  // them), which is exactly what the core's edge-blending logic already
  // handles generically — no core changes were needed for this to work.
  static const tabCenterRatios = [0.1, 0.3, 0.5, 0.7, 0.9];

  @override
  Widget build(BuildContext context) {
    return MagneticNavbarCore(
      items: items,
      tabCenterRatios: tabCenterRatios,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
