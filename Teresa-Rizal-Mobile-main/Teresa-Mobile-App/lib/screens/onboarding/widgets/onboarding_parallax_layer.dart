import 'package:flutter/material.dart';

/// Translates [child] horizontally against the swipe, so it reads as sitting
/// behind the glass rather than on it.
///
/// Ported from the Servana client's `WelcomeParallaxLayer`. [factor] is the
/// share of a viewport width the layer travels per page of swipe — 0.05 is
/// atmospheric, 0.15 a photograph, 0.35 mid-ground, 0.55 interface cards.
///
/// [RepaintBoundary] so a translating photograph does not repaint the copy and
/// buttons stacked over it every frame, and the `child` is passed through
/// `AnimatedBuilder` so the subtree is built once rather than on every frame.
class OnboardingParallaxLayer extends StatelessWidget {
  const OnboardingParallaxLayer({
    super.key,
    this.transformKey,
    required this.controller,
    required this.pageIndex,
    required this.factor,
    required this.child,
    this.verticalFactor = 0,
    this.enabled = true,
  });

  /// Placed on the `Transform` itself rather than on this widget, so a test
  /// can read the offset that was actually applied. The Transform is emitted
  /// even when [enabled] is false — carrying a zero offset — so "reduced
  /// motion means exactly zero" is a thing a test can assert rather than infer
  /// from an absence.
  final Key? transformKey;

  final PageController controller;
  final int pageIndex;
  final double factor;
  final double verticalFactor;

  /// False under reduced motion, where the offset is exactly zero rather than
  /// merely small.
  final bool enabled;

  final Widget child;

  /// The controller's live position, safe before the first layout.
  ///
  /// `controller.page` throws when there are no attached positions or no
  /// content dimensions yet — which is the state of the very first build, the
  /// one frame a citizen would otherwise see as a blank flash.
  static double progressOf(PageController controller) {
    final positions = controller.positions;
    final live = positions.length == 1 && positions.first.hasContentDimensions;
    if (!live) return controller.initialPage.toDouble();
    return controller.page ?? controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, stable) {
          if (!enabled) {
            return Transform.translate(
              key: transformKey,
              offset: Offset.zero,
              child: stable,
            );
          }
          final size = MediaQuery.sizeOf(context);
          final delta = (progressOf(controller) - pageIndex).clamp(-1.0, 1.0);
          // Against the swipe: the page has already moved a full viewport, so
          // giving the photograph part of that back makes it lag.
          final dx = delta * size.width * factor;
          // Deeper layers drift very slightly as a page leaves, in either
          // direction — hence the absolute value.
          final dy = verticalFactor > 0
              ? -delta.abs() * size.height * verticalFactor
              : 0.0;
          return Transform.translate(
            key: transformKey,
            offset: Offset(dx, dy),
            child: stable,
          );
        },
      ),
    );
  }
}
