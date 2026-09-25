import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import '../theme/app_motion.dart';

/// Servana movement numbers on the soft-widget pill. The aperture travels
/// in 320ms ease-out-cubic. The page arrives in 260ms with an 8px rise and
/// a 0.985→1 scale. Chrome (blur, 94% white, radius 24, blue shadow) stays
/// on the pill; these constants only size the motion.
abstract final class TeresaRizalNavMotion {
  /// Aperture travel across the four branch slots.
  static const Duration selection = Duration(milliseconds: 320);

  static const Curve selectionCurve = Curves.easeOutCubic;

  /// Branch content arrival. Same curve as the aperture.
  static const Duration page = Duration(milliseconds: 260);
  static const Curve pageCurve = Curves.easeOutCubic;
  static const double pageRiseOffset = 8;
  static const double pageStartScale = 0.985;

  /// Center Services press: 1.00 → 0.94 → 1.03 → 1.00.
  static const Duration press = Duration(milliseconds: 90);
  static const Duration pressRelease = Duration(milliseconds: 70);
  static const double pressScale = 0.94;
  static const double releaseScale = 1.03;

  static const Duration badge = Duration(milliseconds: 150);

  /// OS reduce-motion. Selection and page shorten; haptics still fire.
  static const Duration reducedDuration = Duration(milliseconds: 100);

  /// Pill height. The traveling bubble lifts above this.
  static const double barHeight = 72;

  /// Traveling aperture. Teresa blue, larger than the old 32px tab dot
  /// so it can carry the branch icon the way Servana's bubble does.
  static const double bubbleDiameter = 52;

  /// How far the bubble's top sits above the pill.
  static const double bubbleLift = 12;

  /// Top of the bubble inside the nav stack (the lift is below this).
  static const double bubbleTop = 0;

  static const double iconSize = 16;
  static const double activeIconScale = 1;

  /// Raised Services control. Not a fifth tab.
  static const double centerDiameter = 56;

  static const double surfaceRadius = 24;

  static const double sideInset = 14;
  static const double bottomInset = 16;

  static const int branchCount = 4;
  static const int slotCount = 5;

  static Duration selectionFor(BuildContext context) =>
      AppMotion.reducedMotion(context) ? reducedDuration : selection;

  static Duration pageFor(BuildContext context) =>
      AppMotion.reducedMotion(context) ? reducedDuration : page;

  static bool reduced(BuildContext context) => AppMotion.reducedMotion(context);

  /// Visual column for a branch. Slots are Home, Balita, center, Events, Profile.
  static int visualSlotFor(int branchIndex) {
    final branch = branchIndex < 0 || branchIndex >= branchCount
        ? 0
        : branchIndex;
    return branch < 2 ? branch : branch + 1;
  }

  /// Left edge of the traveling bubble. Centre X is clamped so the circle
  /// stays inside the pill's corner radius.
  static double bubbleLeft({required double width, required int branchIndex}) {
    final slot = width / slotCount;
    final radius = bubbleDiameter / 2;
    final minCenter = radius + surfaceRadius * 0.5;
    final maxCenter = math.max(minCenter, width - minCenter);
    final raw = visualSlotFor(branchIndex) * slot + slot / 2;
    final center = raw.clamp(minCenter, maxCenter);
    return center - radius;
  }
}
