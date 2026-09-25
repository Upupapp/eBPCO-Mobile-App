// Functional verification of the every-launch SplashScreen and the one-time
// first-run OnboardingScreen flow, driven through the real app entry point
// (TeresaRizalMobileApp) with real taps and real drags — not just code review.
//
// **What changed here, and why.** Until 2026-08-30 each assertion in this file
// named a PNG: the three welcome pages were flattened composites, so the only
// thing a test could check was "the right image is on screen". That is a test
// of the asset pipeline, not of onboarding — it would have passed just as
// happily while the artwork advertised "Business Permit — Approved", an
// outcome this app cannot produce.
//
// The pages are native now — a full-bleed photograph under a navy scrim, on
// the Servana client's welcome pattern — so these assert what a citizen
// actually gets:
// the approved headline, the controls, where each control leads, and that
// completion is persisted. `onboarding_redesign_test.dart` covers the parts
// that are about *how* it is presented — parallax, reduced motion, responsive
// sizes, semantics and copy accuracy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_page_data.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_screen.dart';

/// The default test viewport (800x600) is shorter than a real phone and cuts
/// off the login screen's demo-account cards below the fold. Use a realistic
/// phone size instead — same helper as the other functional suites.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Swipes across the PHOTOGRAPH, in steps, and settles.
///
/// Both details are load-bearing, and each was measured:
///
///  * **On the photograph.** The copy and buttons sit in a bottom block that is
///    a `Scrollable`, and a Scrollable hit-tests opaquely — a drag started over
///    the headline never reaches the pager at all. Measured: 240px of drag at
///    y=422 moved `position.pixels` by exactly 0.0, while the same drag at
///    y=150 moved it 240px.
///  * **In steps.** The first move of a gesture is spent winning the gesture
///    arena, so a single large `moveBy` scrolls nothing. Measured: one 110px
///    move scrolls 0px; six 20px moves scroll 100px.
///
/// A test written without either detail passes against a screen where swiping
/// does not work.
Future<void> _swipe(WidgetTester tester, {required double by}) async {
  final photo = tester.getTopLeft(find.byType(PageView));
  final gesture = await tester.startGesture(
    Offset(photo.dx + 195, photo.dy + 200),
  );
  const steps = 8;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(by / steps, 0));
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder get _skip => find.byKey(const Key('onboarding_skip'));
Finder get _next => find.byKey(const Key('onboarding_next'));
Finder get _getStarted => find.byKey(const Key('onboarding_get_started'));

/// Asserts the given page is the one on screen, by its approved headline and
/// the brand line every page carries.
void _expectPage(int index) {
  expect(find.text(onboardingScenes[index].headline), findsOneWidget);
  expect(find.text(onboardingBrandName), findsOneWidget);
}

void main() {
  testWidgets(
    'First launch: opening animation leads into all three welcome screens, then Sign In',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const TeresaRizalMobileApp());
      // One un-settled pump first: confirms the opening animation frame itself
      // (blue background, seal, wordmark) actually renders before it gets
      // fast-forwarded away by pumpAndSettle below.
      await tester.pump();
      expect(find.text('Teresa, Rizal Mobile'), findsOneWidget);

      await tester.pumpAndSettle();

      // Page 1 — brand, headline, Skip, Next.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      _expectPage(0);
      expect(_skip, findsOneWidget);
      expect(_next, findsOneWidget);
      expect(_getStarted, findsNothing);

      await tester.tap(_next);
      await tester.pumpAndSettle();

      // Page 2 — including the access caveat, which is the one thing on these
      // three screens that limits rather than promises.
      _expectPage(1);
      expect(find.text(onboardingScenes[1].note!), findsOneWidget);
      expect(_skip, findsOneWidget);
      expect(_next, findsOneWidget);

      await tester.tap(_next);
      await tester.pumpAndSettle();

      // Page 3 — Skip stays. The sealed welcome comps keep the ghost pill
      // beside Get Started; it still completes onboarding.
      _expectPage(2);
      expect(_skip, findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(_getStarted, findsOneWidget);
      expect(_next, findsNothing);

      await tester.tap(_getStarted);
      await tester.pumpAndSettle();

      // Lands on the existing Sign In screen with its existing options intact —
      // not a new or alternate auth screen.
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Completion was actually persisted, not just navigated past.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('teresa_rizal_onboarding_complete'), isTrue);
    },
  );

  testWidgets(
    'First launch: Skip on screen 1 also completes onboarding and reaches Sign In',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      _expectPage(0);
      await tester.tap(_skip);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('teresa_rizal_onboarding_complete'), isTrue);
    },
  );

  testWidgets(
    'Returning user: opening animation still plays, but welcome screens never reappear',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);

      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pump();
      // The opening animation still runs every launch, regardless of onboarding
      // state.
      expect(find.text('Teresa, Rizal Mobile'), findsOneWidget);

      await tester.pumpAndSettle();

      // Straight to the normal entry point — no welcome screens.
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text(onboardingBrandName), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    },
  );

  testWidgets(
    'Swiping navigates both ways, and a half-finished drag throws nothing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();
      _expectPage(0);

      // Forward.
      await _swipe(tester, by: -320);
      _expectPage(1);
      expect(find.text(onboardingScenes[0].headline), findsNothing);

      // Back.
      await _swipe(tester, by: 320);
      _expectPage(0);

      // A drag released mid-way must settle somewhere valid rather than throw.
      final photo = tester.getTopLeft(find.byType(PageView));
      final gesture = await tester.startGesture(
        Offset(photo.dx + 195, photo.dy + 200),
      );
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(-22, 0));
        await tester.pump();
      }
      expect(tester.takeException(), isNull, reason: 'a partial drag threw');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'settling after a partial drag threw',
      );

      // Whichever page it settled on, onboarding is still usable — the point is
      // that a released half-swipe never strands the citizen.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text(onboardingBrandName), findsOneWidget);
    },
  );

  testWidgets('Skip stays on the last page and still completes onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);

    await tester.pumpWidget(const TeresaRizalMobileApp());
    await tester.pumpAndSettle();

    await _swipe(tester, by: -320);
    expect(_skip, findsOneWidget, reason: 'Skip belongs on page 2');

    await _swipe(tester, by: -320);
    // Reached by swipe rather than by the Next button. The sealed comps
    // keep Skip beside Get Started, and it still leaves for Sign In.
    expect(_skip, findsOneWidget);
    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
