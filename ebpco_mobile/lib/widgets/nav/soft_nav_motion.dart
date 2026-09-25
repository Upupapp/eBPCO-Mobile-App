import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// The design reference's nav motion and geometry numbers
/// (`teresa_rizal_nav_motion.dart`), unchanged: the active bubble travels
/// in 320ms ease-out-cubic, pages arrive in 260ms with an 8px rise and a
/// 0.985→1 scale, the center control presses 1.00→0.94→1.03→1.00.
abstract final class SoftNavMotion {
  static const Duration selection = Duration(milliseconds: 320);
  static const Curve selectionCurve = Curves.easeOutCubic;

  static const Duration page = Duration(milliseconds: 260);
  static const Curve pageCurve = Curves.easeOutCubic;
  static const double pageRiseOffset = 8;
  static const double pageStartScale = 0.985;

  static const Duration press = Duration(milliseconds: 90);
  static const Duration pressRelease = Duration(milliseconds: 70);
  static const double pressScale = 0.94;
  static const double releaseScale = 1.03;

  static const Duration reducedDuration = Duration(milliseconds: 100);

  static const double barHeight = 72;
  static const double bubbleDiameter = 52;
  static const double bubbleLift = 12;
  static const double bubbleTop = 0;
  static const double iconSize = 22;

  /// Inactive icons sit this far below the pill's top edge (centre), clear
  /// of the border line rather than on the raised bubble's axis.
  static const double iconCenterBelowBarTop = 26;
  static const double labelBottom = 12;
  static const double centerDiameter = 52;
  static const double surfaceRadius = 24;
  static const double sideInset = 14;
  static const double bottomInset = 12;

  static const int branchCount = 4;
  static const int slotCount = 5;

  /// Total height the nav claims, for content that must clear it.
  static const double totalHeight = barHeight + bubbleLift + bottomInset;

  static Duration selectionFor(BuildContext context) => AppMotion.reducedMotion(context) ? reducedDuration : selection;
  static Duration pageFor(BuildContext context) => AppMotion.reducedMotion(context) ? reducedDuration : page;
  static bool reduced(BuildContext context) => AppMotion.reducedMotion(context);

  /// Visual column for a branch: Home, Applications, [center], Alerts, Profile.
  static int visualSlotFor(int branchIndex) {
    final branch = branchIndex < 0 || branchIndex >= branchCount ? 0 : branchIndex;
    return branch < 2 ? branch : branch + 1;
  }

  /// Left edge of the traveling bubble, clamped inside the pill's corners.
  static double bubbleLeft({required double width, required int branchIndex}) {
    final slot = width / slotCount;
    const radius = bubbleDiameter / 2;
    const minCenter = radius + surfaceRadius * 0.5;
    final maxCenter = math.max(minCenter, width - minCenter);
    final raw = visualSlotFor(branchIndex) * slot + slot / 2;
    final center = raw.clamp(minCenter, maxCenter);
    return center - radius;
  }
}
