import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../onboarding_page_data.dart';
import 'onboarding_parallax_layer.dart';

/// Where the shared civic orb sits on one settled page.
///
/// [scale] multiplies [layoutWidthFraction]. That fraction is the old hero
/// box (~40% of width). Page 1 at rest is scale 0.55, about 22% of width.
/// Pages 2 and 3 settle smaller, about 12–16% of width. Mid-swipe the scale
/// rises to [travelPeakScale] and then eases back down.
@immutable
class OnboardingOrbPose {
  const OnboardingOrbPose({
    required this.fx,
    required this.fy,
    required this.scale,
    required this.yaw,
    required this.pitch,
    required this.opacity,
  });

  /// Horizontal center, 0 = left edge, 1 = right edge.
  final double fx;

  /// Vertical center, 0 = top edge, 1 = bottom edge.
  final double fy;

  /// Multiplier on [layoutWidthFraction].
  final double scale;

  /// Yaw in radians. Page 2 turns slightly as it travels.
  final double yaw;

  /// Pitch in radians. Page 3 tips back.
  final double pitch;

  final double opacity;

  /// The retired hero box. Scale 1.0 would fill this; the lock keeps the
  /// painted orb well below it.
  static const double layoutWidthFraction = 0.40;

  static const double travelPeakScale = 0.72;

  /// Centers sit on the curved seam, not up in the photograph.
  /// Page 1 rests in the middle of the smile. Pages 2 and 3 sit quieter,
  /// mid-right and upper-left, at the same lip.
  static const page1 = OnboardingOrbPose(
    fx: 0.50,
    // On the page-1 lip (sheet center 0.537 → y≈453 at 390×844), not above
    // it. A higher orb left its lower edge covering white near y=461.
    fy: 0.537,
    scale: 0.55,
    yaw: 0,
    pitch: 0,
    opacity: 1,
  );

  static const page2 = OnboardingOrbPose(
    fx: 0.80,
    fy: 0.505,
    scale: 0.35,
    yaw: 18 * math.pi / 180,
    pitch: 0,
    opacity: 0.90,
  );

  static const page3 = OnboardingOrbPose(
    fx: 0.16,
    fy: 0.485,
    scale: 0.34,
    yaw: 0,
    pitch: -8 * math.pi / 180,
    opacity: 0.88,
  );

  static const poses = <OnboardingOrbPose>[page1, page2, page3];

  /// Continuous pose for a pager progress in `0 .. poses.length - 1`.
  ///
  /// Position, yaw, and pitch move linearly. Scale adds a sine bump so the
  /// midpoint of each swipe is [travelPeakScale], then settles again.
  static OnboardingOrbPose lerp(double progress) {
    final last = poses.length - 1;
    final p = progress.clamp(0.0, last.toDouble());
    final i = p.floor().clamp(0, last);
    final t = (p - i).clamp(0.0, 1.0);
    final a = poses[i];
    final b = poses[math.min(i + 1, last)];
    if (t == 0) return a;
    final linearScale = a.scale + (b.scale - a.scale) * t;
    final mid = (a.scale + b.scale) / 2;
    final scale = linearScale + (travelPeakScale - mid) * math.sin(math.pi * t);
    return OnboardingOrbPose(
      fx: a.fx + (b.fx - a.fx) * t,
      fy: a.fy + (b.fy - a.fy) * t,
      scale: scale,
      yaw: a.yaw + (b.yaw - a.yaw) * t,
      pitch: a.pitch + (b.pitch - a.pitch) * t,
      opacity: a.opacity + (b.opacity - a.opacity) * t,
    );
  }

  /// Painted width as a fraction of the screen.
  double get widthFraction => layoutWidthFraction * scale;
}

/// One orb for the whole pager. It is the shared element: the same asset
/// interpolates position, scale, and rotation instead of being swapped per
/// page. [Hero] keeps that identity if a later route also carries the tag.
class OnboardingOrb extends StatelessWidget {
  const OnboardingOrb({
    super.key,
    required this.controller,
    required this.page,
    required this.reduceMotion,
  });

  final PageController controller;
  final int page;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final progress = reduceMotion
              ? page.toDouble()
              : OnboardingParallaxLayer.progressOf(controller);
          final pose = OnboardingOrbPose.lerp(progress);
          final side = MediaQuery.sizeOf(context).width * pose.widthFraction;
          return Align(
            alignment: Alignment(pose.fx * 2 - 1, pose.fy * 2 - 1),
            child: Transform(
              key: const Key('onboarding_orb'),
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(pose.pitch)
                ..rotateY(pose.yaw),
              child: Opacity(
                opacity: pose.opacity.clamp(0.85, 1.0),
                child: Hero(
                  tag: 'welcome-civic-orb',
                  child: Image.asset(
                    onboardingOrbAsset,
                    width: side,
                    height: side,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
