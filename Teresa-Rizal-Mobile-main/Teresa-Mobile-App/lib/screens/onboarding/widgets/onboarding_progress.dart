import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/soft_widget.dart';
import 'onboarding_parallax_layer.dart';

/// Page progress that responds continuously to the swipe rather than snapping
/// at the page boundary.
///
/// Ported from the Servana client's `WelcomePageIndicator`: each segment's
/// color tracks how close the live scroll position is to that page, so at the
/// half-way point of a drag both dots share the blue. A dot that jumps on
/// `onPageChanged` tells the citizen where they *arrived*; this one tells
/// them where they *are*.
///
/// Three circles. The active one is a filled disc; the others stay circles
/// in a lighter gray. Width does not grow — a wider segment reads as a
/// capsule, and the sealed comps are dots. The segments themselves are
/// excluded from semantics — three unlabelled containers read aloud is worse
/// than silence — and the group announces its position once.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.controller,
    required this.page,
    required this.count,
    required this.reduceMotion,
  });

  final PageController controller;

  /// The settled page, used for the announcement. The visual uses the live
  /// position instead.
  final int page;
  final int count;
  final bool reduceMotion;

  static const double _diameter = 8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${page + 1} of $count',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final progress = reduceMotion
                ? page.toDouble()
                : OnboardingParallaxLayer.progressOf(controller);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < count; i++) _segment(i, progress)],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(int i, double progress) {
    // 1.0 on this page, 0.0 a full page away.
    final active = (1.0 - (progress - i).abs()).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.slate300, SoftColors.blue, active),
        shape: BoxShape.circle,
      ),
    );
  }
}
