import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../utils/fade_page_route.dart';
import '../onboarding/onboarding_screen.dart';

/// The every-launch opening animation — distinct from the one-time
/// [OnboardingScreen] flow. Same dark navy background + soft brand-blue
/// glow LoginScreen already uses behind its own seal/wordmark, so the very
/// first frame a user sees already
/// feels like "this app" rather than a generic splash. A single
/// [AnimationController] fades/scales the seal in first, then fades the
/// "Teresa, Rizal Mobile" wordmark in underneath it — simple opacity + a very
/// subtle scale, no spinning/bouncing/particles, using only Flutter's
/// built-in animation classes (no new package).
///
/// Total time on screen — animation plus a short hold so the finished
/// branding is actually visible before handing off — lands around 1.9s,
/// within the "don't make users wait" target.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // The full ~1.9s on-screen time — fade-in plus a still hold at the end
  // so the finished branding is actually visible before handing off — all
  // lives on one AnimationController/Ticker rather than a separate
  // Future.delayed hold tacked on afterwards. A raw Timer isn't tied to
  // the frame scheduler, so widget-test `pumpAndSettle()` (which only
  // waits out scheduled frames/tickers, not arbitrary timers) would
  // consider the app "settled" and return while that timer was still
  // pending, permanently stranding every test that pumps the app on this
  // screen. Folding the hold into the controller's own duration keeps it
  // tied to the ticker pumpAndSettle already knows how to wait for.
  static const _animationDuration = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.46, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeOutCubic),
      ),
    );
    // Starts once the logo is most of the way in, rather than waiting for
    // it to fully finish — reads as one connected sequence instead of two
    // separate beats. Finishes at 0.76, leaving the last ~24% of the
    // duration as a still hold with the finished branding fully visible.
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.76, curve: Curves.easeOut),
    );
    _run();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    await _controller.forward();
    if (!mounted) return;

    // Defence in depth: `_run()` is started from initState and never awaited,
    // so anything that escapes here strands the citizen on the splash with no
    // way forward. OnboardingService.isComplete() is itself guarded; this keeps
    // the invariant true for whatever else lands in this method later.
    var onboardingDone = false;
    try {
      onboardingDone = await OnboardingService.isComplete();
    } catch (_) {
      // Show onboarding rather than not navigating at all.
    }
    if (!mounted) return;

    // pushReplacement (never push) — the branding fades into whichever
    // screen comes next while keeping exactly one route on the stack, so
    // that screen becomes the new *root* route. See AuthGate's doc
    // comment in main.dart for why that invariant matters.
    Navigator.of(context).pushReplacement(fadePageRoute(onboardingDone ? const AuthGate() : const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      // SafeArea + an explicit Center (rather than relying on Stack's own
      // alignment to fill/center within whatever constraints happen to
      // reach it) — guarantees the whole branding group sits in the
      // visually-true middle of the usable screen on every device/notch/
      // browser viewport, without any hardcoded position. Nothing below
      // this point (animation, curves, durations, sizes, colors) changed —
      // only how the group as a whole is positioned.
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Soft glow behind the seal — the same device LoginScreen's
                  // own hero uses.
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppColors.brand500.withValues(alpha: 0.28), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                            ),
                            child: ClipOval(
                              // Source seal is 500x500; displayed at 112
                              // logical px here, so cap decode to that (x
                              // DPR) instead of the full source resolution.
                              child: Image.asset(
                                teresaRizalSealAsset,
                                fit: BoxFit.cover,
                                cacheWidth: (112 * MediaQuery.devicePixelRatioOf(context)).round(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Opacity(
                        opacity: _titleOpacity.value,
                        child: const Text(
                          'Teresa, Rizal Mobile',
                          style: TextStyle(
                            fontFamily: AppTypography.display,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
