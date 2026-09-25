// Regression coverage for a real bug: several auth-adjacent buttons used
// `Navigator.pushAndRemoveUntil(MaterialPageRoute(...), (route) => false)`,
// which removes *every* route including the app's root route — the one
// that hosts `_AuthGate` (main.dart), the single place that reactively
// swaps between LoginScreen/RootShell based on CitizenSessionService.
// Once that root route is gone, any *later* login()/logout() has nothing
// left listening, so the app gets stuck on whatever screen was showing —
// this is what made the Nicanor/Perlita demo accounts appear to "stop
// opening" when reached via Guest -> Sign In, a restricted-feature
// notice's Sign In button, or a fresh registration's "Continue to App".
// These tests drive those exact paths end-to-end through the real app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

/// Dokyu and Tulong open from the Services sheet.
Future<void> _openService(WidgetTester tester, String label) async {
  await _tapVisible(tester, find.byKey(const ValueKey('nav-center-action')));
  await _tapVisible(tester, find.byKey(ValueKey('services-sheet-$label')));
}

/// Home shows the promotional HomeWelcomeBanner pop-up once per RootShell
/// instance, right after Home first loads — dismiss it before any further
/// interaction, the same way a real user would, otherwise the modal
/// barrier intercepts the next tap. A fresh sign-in creates a fresh
/// RootShell (and thus a fresh HomeScreen `initState`), so this needs
/// calling again after every new login, not just the first.
Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    // warnIfMissed: false — Icon widgets are painted leaves, not hit-test
    // targets themselves (the enclosing IconButton is), so tapping one
    // reliably prints a benign "would not hit test on the specified
    // widget" warning even though the tap correctly reaches the button.
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'Guest -> drawer "Sign In" -> Nicanor Sarmiento reaches Home, not stuck on LoginScreen',
    (tester) async {
      // Onboarding-complete pre-seeded: these regression cases exercise the
      // normal returning-user flow, not the first-run Onboarding screens —
      // see onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Continue as Guest'));
      await _dismissWelcomeBanner(tester);
      expect(find.textContaining('Welcome, Guest'), findsOneWidget);

      // Open the hamburger drawer and tap "Sign In" — this is the exact
      // path that used to orphan _AuthGate. The Guest home hero has its
      // own "Sign In" button too, so target the drawer's copy rather
      // than find.text('Sign In'), which would match both.
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('menu-sheet')),
          matching: find.text('Sign in'),
        ),
      );

      // Must land back on the real LoginScreen (still under _AuthGate),
      // not a dead end.
      expect(find.text('Welcome back'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const Key('demo-unverified')));

      // The critical assertion: login() must have actually navigated us
      // into the app. Before the fix, this button press had no visible
      // effect because _AuthGate was no longer in the tree to react to it.
      expect(find.text('Welcome back'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guest -> Dokyu restricted notice -> "Sign In" -> Perlita Quiambao reaches Home with full access',
    (tester) async {
      // Onboarding-complete pre-seeded: these regression cases exercise the
      // normal returning-user flow, not the first-run Onboarding screens —
      // see onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Continue as Guest'));
      await _dismissWelcomeBanner(tester);
      await _openService(tester, 'Dokyu');
      await _tapVisible(tester, find.text('Barangay Clearance'));
      await _tapVisible(tester, find.text('Start request'));
      expect(find.text('Create account'), findsOneWidget);

      await _tapVisible(tester, find.text('Sign in'));
      expect(find.text('Welcome back'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const Key('demo-verified')));
      await _dismissWelcomeBanner(tester);
      expect(find.text('Welcome back'), findsNothing);
      expect(tester.takeException(), isNull);

      // Now that we're actually in as Perlita, verified-only content must
      // be reachable — proves this isn't just "some screen changed" but
      // the real authenticated app.
      await _openService(tester, 'Dokyu');
      expect(
        find.text(
          'This feature is available to registered Teresa, Rizal users. Create an account or sign in to continue.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'RegisterScreen "Continue to App" -> Sign Out still returns cleanly to a working LoginScreen',
    (tester) async {
      // Onboarding-complete pre-seeded: these regression cases exercise the
      // normal returning-user flow, not the first-run Onboarding screens —
      // see onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      // Sign in as Nicanor (already has an account), then open
      // RegisterScreen — since an account already exists it jumps straight
      // to the read-only "Verification Status" step, whose "Continue to
      // App" button is exactly the path that used to push a *second*
      // RootShell.withKey() (colliding with the one _AuthGate had already
      // built reactively) or orphan _AuthGate outright.
      await _tapVisible(tester, find.byKey(const Key('demo-unverified')));
      await _dismissWelcomeBanner(tester);
      await _openService(tester, 'Dokyu');
      await _tapVisible(tester, find.text('Barangay Clearance'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Start request'));
      await _tapVisible(tester, find.text('Continue verification'));
      expect(
        find.text('Verification'),
        findsOneWidget,
      ); // RegisterScreen's AppBar title for this path

      // The sign-in toast sits on the bottom edge and covers this footer
      // until its timer fires.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Continue exploring'));
      expect(tester.takeException(), isNull);
      expect(
        find.text('Verification'),
        findsNothing,
      ); // back in the real app, not stuck on the wizard

      // The catalog and detail are pushes over the shell. Pop back to it
      // before using the Home branch.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      var guard = 0;
      while (find.byType(TeresaRizalCurvedNavBar).hitTestable().evaluate().isEmpty &&
          navigator.canPop() &&
          guard < 6) {
        navigator.pop();
        await tester.pumpAndSettle();
        guard++;
      }
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Home'),
        ),
      );

      // The real proof _AuthGate is still alive and reactive: sign out from
      // here and confirm we land on an actual, working LoginScreen — not a
      // dead screen, and no crash from a duplicated/collided RootShell.
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('menu-sheet')),
          matching: find.text('Sign out'),
        ),
      );
      await _tapVisible(
        tester,
        find.widgetWithText(AppButton, 'Sign Out'),
      ); // confirm-dialog button
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );
}
