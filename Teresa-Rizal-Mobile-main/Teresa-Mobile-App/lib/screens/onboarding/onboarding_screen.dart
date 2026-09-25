import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../utils/fade_page_route.dart';
import '../../utils/teresa_rizal_seal.dart';
import 'onboarding_page_data.dart';
import 'widgets/onboarding_orb.dart';
import 'widgets/onboarding_parallax_layer.dart';
import 'widgets/onboarding_progress.dart';

/// The three first-run welcome screens, shown once (see [OnboardingService])
/// straight after the every-launch [SplashScreen].
///
/// The photograph is full-bleed. Flutter owns the smile where that photograph
/// becomes the white sheet: a quadratic lip, frosted, not a hard crop. Copy,
/// chips, dots, and Skip / Next / Get Started are drawn here. The real
/// municipal seal sits upper-right over the photo. The civic orb is one
/// shared asset that morphs along the seam.
///
/// The photograph stays the swipe surface. A full-screen scroll view would
/// hit-test opaquely and swallow the pager — measured once already, when
/// `position.pixels` stayed at 0 through a 240px drag. The copy scroller
/// starts below the seam, so a drag on the photograph still reaches the pager.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});

  /// Settled page to open on. The review harness uses this; the app path
  /// leaves it at the first scene.
  final int initialPage;

  /// Top of the white sheet at the left and right edges, as a fraction of
  /// height. The center of the smile sits lower — see [sheetCenterFraction].
  static const sheetEdgeFraction = 0.43;

  /// Top of the opaque white sheet at the middle of the smile.
  ///
  /// Bow is [sheetCenterFraction] − [sheetEdgeFraction] ≈ 0.11H (~90px at
  /// 390×844), inside the 0.08–0.14H lock. Edges of the white ground sit
  /// higher than the center. The sealed page-1 lip is y≈453; 0.537·844
  /// lands on that line (was 0.522, about 12px high, and the orb then
  /// covered white down to ~461).
  static const sheetCenterFraction = 0.537;

  /// Where the brand line starts, just under the dip.
  static const contentTopFraction = 0.535;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialPage,
  );

  /// The settled page. Driven by `onPageChanged`; the per-frame scroll
  /// position is read straight off the controller inside `AnimatedBuilder`s,
  /// so a swipe never calls `setState`.
  late int _page = widget.initialPage;
  bool _finishing = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Decoded at display width, once. Without this the first swipe reaches a
    // page whose photograph has not decoded and shows the Scaffold instead.
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    for (final scene in onboardingScenes) {
      precacheImage(
        backgroundProvider(scene.backgroundAsset, cacheWidth),
        context,
      );
    }
    precacheImage(const AssetImage(onboardingOrbAsset), context);
    precacheImage(const AssetImage(teresaRizalSealAsset), context);
  }

  /// One provider shape for precache and render alike. Two different shapes
  /// populate two different image-cache entries, and the precache silently
  /// buys nothing.
  static ImageProvider backgroundProvider(String asset, int cacheWidth) =>
      ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(asset));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingService.markComplete();
    if (!mounted) return;
    // pushReplacement — AuthGate becomes the new root route, the same
    // invariant SplashScreen's own handoff preserves (see its doc comment).
    Navigator.of(context).pushReplacement(fadePageRoute(const AuthGate()));
  }

  void _next() {
    if (_page >= onboardingScenes.length - 1) {
      AppHaptics.medium();
      _finish();
      return;
    }
    AppHaptics.selection();
    if (MediaQuery.disableAnimationsOf(context)) {
      // Someone who asked the platform for no animation should not wait out a
      // 340 ms slide to reach the next page.
      _pageController.jumpToPage(_page + 1);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    AppHaptics.light();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isLast = _page == onboardingScenes.length - 1;
    final scene = onboardingScenes[_page];
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final cacheWidth = (size.width * MediaQuery.devicePixelRatioOf(context))
        .round();
    // Copy begins just under the dip, clear of the orb that straddles it.
    final gap =
        (size.height * OnboardingScreen.contentTopFraction - padding.top).clamp(
          0.0,
          size.height * 0.62,
        );

    return Scaffold(
      backgroundColor: SoftColors.white,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingScenes.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => OnboardingParallaxLayer(
              transformKey: Key('onboarding_background_$i'),
              controller: _pageController,
              pageIndex: i,
              factor: OnboardingParallax.background,
              verticalFactor: OnboardingParallax.backgroundVertical,
              enabled: !reduceMotion,
              child: Semantics(
                label: onboardingScenes[i].semanticDescription,
                image: true,
                child: SizedBox.expand(
                  child: Image(
                    image: backgroundProvider(
                      onboardingScenes[i].backgroundAsset,
                      cacheWidth,
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: SoftColors.page),
                  ),
                ),
              ),
            ),
          ),

          // Curved frost, then an opaque sheet. IgnorePointer so a drag on
          // the photograph passes through the lip to the pager.
          const Positioned.fill(child: IgnorePointer(child: _CurvedSheet())),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    // Empty photo window. A bare SizedBox does not hit-test,
                    // so a drag here reaches the PageView underneath.
                    SizedBox(height: gap),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            _CopyBlock(
                              key: ValueKey('copy_${scene.id}'),
                              scene: scene,
                              reduceMotion: reduceMotion,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _FeatureChips(
                              scene: scene,
                              controller: _pageController,
                              pageIndex: _page,
                              reduceMotion: reduceMotion,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _BottomBar(
                      isLast: isLast,
                      finishing: _finishing,
                      reduceMotion: reduceMotion,
                      controller: _pageController,
                      page: _page,
                      onSkip: _finishing ? null : _skip,
                      onNext: _finishing ? null : _next,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shared orb, on the seam, above the sheet and out of the hit test.
          Positioned.fill(
            child: OnboardingOrb(
              controller: _pageController,
              page: _page,
              reduceMotion: reduceMotion,
            ),
          ),

          Positioned(
            top: padding.top + AppSpacing.lg,
            right: AppSpacing.lg,
            child: const IgnorePointer(child: _OfficialSeal()),
          ),
        ],
      ),
    );
  }
}

/// Quadratic smile: white at the sides, photo dipping lower in the middle.
Path _smilePath(Size size, double edgeFraction, double centerFraction) {
  final edgeY = size.height * edgeFraction;
  final centerY = size.height * centerFraction;
  final controlY = 2 * centerY - edgeY;
  return Path()
    ..moveTo(0, edgeY)
    ..quadraticBezierTo(size.width / 2, controlY, size.width, edgeY)
    ..lineTo(size.width, size.height + 2)
    ..lineTo(0, size.height + 2)
    ..close();
}

Path _smileLip(Size size, double edgeFraction, double centerFraction) {
  final edgeY = size.height * edgeFraction;
  final centerY = size.height * centerFraction;
  final controlY = 2 * centerY - edgeY;
  return Path()
    ..moveTo(0, edgeY)
    ..quadraticBezierTo(size.width / 2, controlY, size.width, edgeY);
}

/// Frosted smile over the photograph, then an opaque white ground.
///
/// The lip is a stroke blurred along the same quadratic as the fill, so the
/// feather follows the curve. A horizontal gradient would not.
class _CurvedSheet extends StatelessWidget {
  const _CurvedSheet();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _CurvedSheetPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _CurvedSheetPainter extends CustomPainter {
  const _CurvedSheetPainter();

  static const _edge = OnboardingScreen.sheetEdgeFraction;
  static const _center = OnboardingScreen.sheetCenterFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final lip = _smileLip(size, _edge - 0.012, _center - 0.008);
    // Cool wash, then white frost. Sigma ~10–14 logical px is the 16–28px
    // feather at a 390-wide phone.
    canvas.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.butt
        ..color = SoftColors.blueWash
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14),
    );
    canvas.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt
        ..color = SoftColors.white
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
    canvas.drawPath(
      _smilePath(size, _edge, _center),
      Paint()..color = SoftColors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _CurvedSheetPainter oldDelegate) => false;
}

/// Real municipal seal. One instance, upper-right, over the photograph.
class _OfficialSeal extends StatelessWidget {
  const _OfficialSeal();

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: SoftShadows.seal,
      ),
      child: Image.asset(
        teresaRizalSealAsset,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLast,
    required this.finishing,
    required this.reduceMotion,
    required this.controller,
    required this.page,
    required this.onSkip,
    required this.onNext,
  });

  final bool isLast;
  final bool finishing;
  final bool reduceMotion;
  final PageController controller;
  final int page;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    // Sealed comps put the CTA band around y 748–793 at 390×844. A surface
    // with no home-indicator inset still keeps that gap.
    final inset = MediaQuery.paddingOf(context).bottom;
    // Pages 1–2 sit on the sealed 748–795 band. Page 3's Get Started is
    // lower in the comp (~763–809), so that page alone drops 14px.
    final bottom = (inset > 20 ? inset : 48.0) - (isLast ? 14.0 : 0.0);
    final cta = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: isLast
          ? _PrimaryPill(
              key: const Key('onboarding_get_started'),
              label: 'Get Started',
              loading: finishing,
              onPressed: onNext,
            )
          : _PrimaryPill(
              key: const Key('onboarding_next'),
              label: 'Next',
              onPressed: onNext,
            ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _SkipButton(onPressed: onSkip),
              ),
            ),
          ),
          OnboardingProgress(
            key: const Key('onboarding_progress'),
            controller: controller,
            page: page,
            count: onboardingScenes.length,
            reduceMotion: reduceMotion,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: cta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: Material(
          color: SoftColors.white,
          shape: const StadiumBorder(side: BorderSide(color: SoftColors.line)),
          child: InkWell(
            key: const Key('onboarding_skip'),
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Text(
                'Skip',
                style: AppTypography.button.copyWith(color: SoftColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !loading && onPressed != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            boxShadow: SoftShadows.primary,
          ),
          child: Material(
            color: SoftColors.blue,
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              onTap: loading ? null : onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SoftColors.white,
                        ),
                      )
                    else
                      Text(
                        label,
                        style: AppTypography.button.copyWith(
                          color: SoftColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (!loading) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: SoftColors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand, two-tone headline, body, and the page-2 caveat. Centered.
class _CopyBlock extends StatelessWidget {
  const _CopyBlock({
    super.key,
    required this.scene,
    required this.reduceMotion,
  });

  final OnboardingSceneSpec scene;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final lines = scene.headline.split('\n');
    // Hero is w700 on the variable face, and that face was drawing Regular
    // here. InterSemi is a static wght 600 instance of the same Inter file.
    final headline = AppTypography.hero.copyWith(
      fontFamily: 'InterSemi',
      fontWeight: FontWeight.w600,
      height: 1.05,
    );
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            onboardingBrandName,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: SoftColors.muted),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: lines.first,
                style: headline.copyWith(color: SoftColors.ink),
              ),
              if (lines.length > 1) ...[
                const TextSpan(text: '\n'),
                TextSpan(
                  text: lines[1],
                  style: headline.copyWith(color: SoftColors.blue),
                ),
              ],
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          scene.subtext,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: SoftColors.muted,
            height: 1.5,
          ),
        ),
        if (scene.note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            scene.note!,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: SoftColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    if (reduceMotion) return block;
    return _SceneSwitcher(child: block);
  }
}

/// Three capability chips under the copy.
///
/// Not buttons. A chip that navigates would promise a destination these
/// labels do not have.
class _FeatureChips extends StatelessWidget {
  const _FeatureChips({
    required this.scene,
    required this.controller,
    required this.pageIndex,
    required this.reduceMotion,
  });

  final OnboardingSceneSpec scene;
  final PageController controller;
  final int pageIndex;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (var i = 0; i < scene.features.length; i++) {
      if (i > 0) chips.add(const _ChipDot());
      chips.add(_Chip(feature: scene.features[i]));
    }
    // One row, scaled down only when a large text size would overflow the
    // phone. The sealed comps keep all three chips on a single line.
    final row = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: chips),
    );

    return OnboardingParallaxLayer(
      transformKey: const Key('onboarding_chips'),
      controller: controller,
      pageIndex: pageIndex,
      factor: OnboardingParallax.chips,
      enabled: !reduceMotion,
      child: reduceMotion ? row : _SceneSwitcher(child: row),
    );
  }
}

class _ChipDot extends StatelessWidget {
  const _ChipDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(
        color: SoftColors.line,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.feature});

  final OnboardingFeature feature;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: SoftColors.white,
          borderRadius: BorderRadius.circular(SoftRadius.md),
          border: Border.all(color: SoftColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(feature.icon, size: 15, color: SoftColors.ink),
            const SizedBox(width: AppSpacing.xs),
            Text(
              feature.label,
              style: AppTypography.bodySmallMedium.copyWith(
                color: SoftColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fade with a short rise, keyed on the scene so a page change replays
/// it. Finite by construction — an `AnimatedSwitcher` settles and stops, which
/// is what keeps `pumpAndSettle` honest.
class _SceneSwitcher extends StatelessWidget {
  const _SceneSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.07),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
