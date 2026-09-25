import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_haptics.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../auth/login_screen.dart';

/// First-run flag — a non-secret UI preference, so SharedPreferences rather
/// than the keystore the auth tokens live in.
class OnboardingPrefs {
  OnboardingPrefs._();
  static const _key = 'ebpco_onboarding_done';

  static Future<bool> isDone() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return true; // Never block sign-in on a storage hiccup.
    }
  }

  static Future<void> markDone() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }
}

class _Slide {
  final String image;
  final String line1;
  final String accent;
  final String body;
  final List<(IconData, String)> chips;
  const _Slide({required this.image, required this.line1, required this.accent, required this.body, required this.chips});
}

/// The citizen portal's own onboarding copy (`onboarding.page.ts`, three
/// slides, dark line + Castilla-red accent line), laid out in the design
/// reference's welcome structure. Illustrations are eBPCO's own brand art
/// (eBPCO-Web/assets/images), not the reference app's photographs.
const _slides = [
  _Slide(
    image: 'assets/images/onboarding_1.png',
    line1: 'Apply for permits',
    accent: 'from your device.',
    body: 'Submit new, renewal, and amendment permit applications through a simple process.',
    chips: [(Icons.description_outlined, 'New'), (Icons.autorenew_rounded, 'Renewal'), (Icons.edit_note_rounded, 'Amendment')],
  ),
  _Slide(
    image: 'assets/images/onboarding_2.png',
    line1: 'Submit and manage',
    accent: 'requirements.',
    body: 'Review required documents and prepare your permit application in one place.',
    chips: [(Icons.upload_file_rounded, 'Upload'), (Icons.checklist_rounded, 'Checklist'), (Icons.save_outlined, 'Save draft')],
  ),
  _Slide(
    image: 'assets/images/onboarding_3.png',
    line1: 'Track your',
    accent: 'application.',
    body: 'Monitor evaluations, payments, approval, and permit release status.',
    chips: [(Icons.search_rounded, 'Status'), (Icons.payments_outlined, 'Payments'), (Icons.notifications_none_rounded, 'Updates')],
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    AppHaptics.medium();
    await OnboardingPrefs.markDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    AppHaptics.selection();
    _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: SoftColors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  SizedBox(width: 108, child: SoftPillButton(label: 'Skip', kind: SoftPillKind.outline, onPressed: _finish)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: i == _index ? SoftColors.primary : SoftColors.line,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: SoftPillButton(
                      label: _isLast ? 'Get started' : 'Next',
                      icon: _isLast ? null : Icons.chevron_right_rounded,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = constraints.maxHeight * 0.52;
        return Column(
          children: [
            SizedBox(
              height: heroHeight + 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    bottom: 36,
                    child: ClipPath(
                      clipper: _ArcBottomClipper(),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [SoftColors.primarySoft, SoftColors.primaryWash],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 36, 24, 44),
                            child: Image.asset(slide.image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 16,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        width: 58,
                        height: 58,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle, boxShadow: SoftShadows.seal),
                        child: Image.asset('assets/images/ebpco_seal.png'),
                      ),
                    ),
                  ),
                  const Positioned(left: 0, right: 0, bottom: 0, child: Center(child: _Orb())),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
                child: Column(
                  children: [
                    Text('Municipality of Castilla, Sorsogon', textAlign: TextAlign.center, style: SoftType.eyebrow.copyWith(fontSize: 15)),
                    const SizedBox(height: 10),
                    Text(slide.line1, textAlign: TextAlign.center, style: SoftType.hero.copyWith(fontSize: 34)),
                    Text(slide.accent, textAlign: TextAlign.center, style: SoftType.hero.copyWith(fontSize: 34, color: SoftColors.primary)),
                    const SizedBox(height: 12),
                    Text(slide.body, textAlign: TextAlign.center, style: SoftType.body.copyWith(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final c in slide.chips) _Chip(icon: c.$1, label: c.$2)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        border: Border.all(color: SoftColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: SoftColors.ink),
          const SizedBox(width: 6),
          Text(label, style: SoftType.chip.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

/// The reference's glowing welcome orb, drawn in red with its gold ring —
/// painted rather than reusing the reference's blue orb image.
class _Orb extends StatelessWidget {
  const _Orb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SoftColors.gold, width: 2.5),
        gradient: const RadialGradient(
          center: Alignment(-0.1, -0.2),
          radius: 0.75,
          colors: [SoftColors.white, SoftColors.primarySoft, SoftColors.primary, SoftColors.primaryDeep],
          stops: [0, 0.18, 0.6, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66C81E2C), blurRadius: 24, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x33CC9A2E), blurRadius: 6),
        ],
      ),
    );
  }
}

/// A rectangle whose bottom edge bows downward — the reference's hero arc.
class _ArcBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final shoulder = size.height * 0.80;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, shoulder)
      ..quadraticBezierTo(size.width / 2, size.height * 1.2, 0, shoulder)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
