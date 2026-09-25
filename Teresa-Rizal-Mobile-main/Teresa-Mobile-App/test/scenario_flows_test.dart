// Functional (not just static) verification of the three scenarios from
// the nav/access-control spec, driven through the real app entry point
// (TeresaRizalMobileApp) with real taps — not just code review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';

/// The default test viewport (800x600) is shorter than a real phone and
/// cuts off the login screen's demo-account cards below the fold, making
/// them untappable without scrolling. Use a realistic phone size instead.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Home shows the promotional HomeWelcomeBanner pop-up once per session,
/// right after it first loads — dismiss it (tap its "Close" button) the
/// same way a real user would before continuing to interact with Home,
/// otherwise the modal barrier intercepts every subsequent tap.
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

/// Dokyu, Tulong, and Emergency open from the Services sheet.
/// A catalog push covers the shell, so later opens pop back to it first.
Future<void> _openService(WidgetTester tester, String label) async {
  final center = find.byKey(const ValueKey('nav-center-action'));
  var guard = 0;
  while (center.hitTestable().evaluate().isEmpty && guard < 6) {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    if (!navigator.canPop()) break;
    navigator.pop();
    await tester.pumpAndSettle();
    guard++;
  }
  await tester.tap(center);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('services-sheet-$label')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Scenario A — Guest: Home -> Balita public -> Dokyu shows restricted notice',
    (tester) async {
      // Onboarding-complete pre-seeded: these scenarios exercise the normal
      // returning-user flow, not the first-run Onboarding screens — see
      // onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      // 1. Open Sign-In.
      expect(find.text('Welcome back'), findsOneWidget);

      // 2. Tap Continue as Guest.
      await tester.ensureVisible(find.text('Continue as Guest'));
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // 3. Enter Home successfully — Guest branch renders, not a crash on
      // `account!`.
      await _dismissWelcomeBanner(tester);
      expect(find.textContaining('Welcome, Guest'), findsOneWidget);
      expect(find.text('Home'), findsWidgets); // bottom nav label

      // 4. Open public Balita content successfully.
      await tester.tap(find.text('Balita'));
      await tester.pumpAndSettle();
      // Scoped to the AppBar — once Balita is the selected nav tab, the
      // navbar's own floating active label also reads "Balita".
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Balita')),
        findsOneWidget,
      );
      expect(find.byType(Scaffold), findsWidgets); // real screen, not a notice
      await _dismissWelcomeBanner(tester); // Balita's own promotional popup

      // 5. Browse Dokyu. Start request is what opens the guest gate.
      await _openService(tester, 'Dokyu');
      expect(find.text('Barangay Clearance'), findsOneWidget);
      await tester.tap(find.text('Barangay Clearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start request'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    },
  );

  testWidgets(
    'Scenario B — Nicanor Sarmiento: registered but unverified, restricted from Dokyu, allowed into Emergency',
    (tester) async {
      // Onboarding-complete pre-seeded: these scenarios exercise the normal
      // returning-user flow, not the first-run Onboarding screens — see
      // onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      // 1. Sign in using the Unverified quick-demo card (Nicanor under the hood).
      expect(find.text('Unverified'), findsOneWidget);
      expect(
        find.text('Signed in · pending review · Emergency only'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('demo-unverified')));
      await tester.tap(find.byKey(const Key('demo-unverified')));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // 2 & 3. Confirm registered-but-unverified is recognized, and status
      // is clearly visible on the profile hub pill.
      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pending Review'), findsWidgets);
      expect(find.text('Verified'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Home'),
        ),
      );
      await tester.pumpAndSettle();

      // 4. Browse Dokyu. Start request opens the unverified gate.
      await _openService(tester, 'Dokyu');
      expect(find.text('Barangay Clearance'), findsOneWidget);
      await tester.tap(find.text('Barangay Clearance'));
      await tester.pumpAndSettle();
      // The sign-in toast sits on the footer until its timer fires.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start request'));
      await tester.tap(find.text('Start request'));
      await tester.pumpAndSettle();
      expect(find.text('Continue verification'), findsOneWidget);
      expect(find.text('Finish verification to apply'), findsOneWidget);
      expect(find.text('Create account'), findsNothing);
      expect(find.text('Sign in'), findsNothing);

      // Emergency is the Sakuna catalog. 911 is callable; MDRRMO is not.
      await _openService(tester, 'Emergency');
      expect(find.text('Report incident'), findsOneWidget);
      expect(find.text('Medical emergency'), findsOneWidget);
      expect(find.text('[TO BE PROVIDED]'), findsWidgets);
    },
  );

  testWidgets(
    'Scenario C — Perlita Quiambao: fully verified, full access, no guest/verification warnings',
    (tester) async {
      // Onboarding-complete pre-seeded: these scenarios exercise the normal
      // returning-user flow, not the first-run Onboarding screens — see
      // onboarding_flow_test.dart for that.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      // 1. Sign in using the Verified resident quick-demo card (Perlita under the hood).
      expect(find.text('Verified resident'), findsOneWidget);
      expect(find.text('Full Dokyu + Tulong · simulation'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('demo-verified')));
      await tester.tap(find.byKey(const Key('demo-verified')));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // 2. Confirm recognized as fully verified.
      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verified'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Home'),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Confirm verified-user features (Dokyu, Tulong) are available —
      // real screens render, not RestrictedFeatureNotice.
      await _openService(tester, 'Dokyu');
      await _dismissWelcomeBanner(tester); // Dokyu's own promotional popup
      expect(
        find.text('Dokyu'),
        findsWidgets,
      ); // AppBar title among other things
      expect(
        find.text('Complete your account verification to access this service.'),
        findsNothing,
      );
      expect(
        find.text(
          'This feature is available to registered Teresa, Rizal users. Create an account or sign in to continue.',
        ),
        findsNothing,
      );

      await _openService(tester, 'Tulong');
      await _dismissWelcomeBanner(tester); // Tulong's own promotional popup
      expect(
        find.text('Tulong'),
        findsWidgets,
      ); // AppBar title — confirms we actually reached Tulong
      expect(
        find.text('Complete your account verification to access this service.'),
        findsNothing,
      );

      // 4. No unnecessary Guest or verification warnings anywhere on Home.
      final center = find.byKey(const ValueKey('nav-center-action'));
      var guard = 0;
      while (center.hitTestable().evaluate().isEmpty && guard < 6) {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        if (!navigator.canPop()) break;
        navigator.pop();
        await tester.pumpAndSettle();
        guard++;
      }
      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Home'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Welcome, Guest'), findsNothing);
      expect(find.textContaining('Magandang araw, Perlita'), findsOneWidget);
    },
  );
}
