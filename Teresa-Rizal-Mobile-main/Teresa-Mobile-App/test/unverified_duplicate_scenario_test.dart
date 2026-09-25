// Functional coverage for the Unverified + Unverified duplicate-registration
// demo — independent of the existing Verified-Perlita duplicate scenario
// (see duplicate_account_simulation_test.dart). FRONTEND SIMULATION ONLY.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _signInByEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), 'demo');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.tap(find.text('Sign in'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

Future<void> _openBell(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.notifications_outlined).first);
  await tester.pumpAndSettle();
}

/// The inbox filter row is its own horizontal scroller. Targets live in
/// the vertical list under it.
Finder get _inboxList => find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axis == Axis.vertical,
);

void main() {
  testWidgets(
    'Sign In offers both Account A and Account B demo logins, sharing the same underlying identity',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      expect(find.text('Unverified'), findsOneWidget);
      expect(find.text('Demo: Unverified Duplicate — Account A'), findsNothing);
      expect(find.text('Demo: Unverified Duplicate — Account B'), findsNothing);

      final a = MockCatalog.unverifiedDuplicateAccountA;
      final b = MockCatalog.unverifiedDuplicateAccountB;
      expect(a.id, isNot(b.id));
      expect(a.status, isNot('Approved'));
      expect(b.status, isNot('Approved'));
      // Same identity (what makes this look like a genuine duplicate).
      expect(a.firstName, b.firstName);
      expect(a.lastName, b.lastName);
      expect(a.birthdate, b.birthdate);
      expect(a.address, b.address);
    },
  );

  testWidgets(
    'Account A sees the duplicate-registration warning and remains restricted from Dokyu',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await _signInByEmail(
        tester,
        MockCatalog.unverifiedDuplicateAccountA.email,
      );
      await _dismissWelcomeBanner(tester);

      await _openBell(tester);
      await tester.scrollUntilVisible(
        find.text('Possible Duplicate Registration Detected'),
        200,
        scrollable: _inboxList,
      );
      expect(
        find.text('Possible Duplicate Registration Detected'),
        findsOneWidget,
      );
      expect(
        find.textContaining('appear to contain matching resident information'),
        findsOneWidget,
      );

      // Still restricted from Dokyu — the generic AccessGuard path (not the
      // "confirmed duplicate" popup, which is specific to the *other*
      // scenario's own known account id).
      Navigator.of(
        tester.element(find.text('Possible Duplicate Registration Detected')),
      ).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-center-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('services-sheet-Dokyu')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Use Your Verified Account'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Resolution screen shows both accounts; keeping Account A marks it Continue Verification and B Cancelled, '
    'neither becomes Verified',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await _signInByEmail(
        tester,
        MockCatalog.unverifiedDuplicateAccountA.email,
      );
      await _dismissWelcomeBanner(tester);

      await _openBell(tester);
      await tester.scrollUntilVisible(
        find.text('Possible Duplicate Registration Detected'),
        200,
        scrollable: _inboxList,
      );
      await tester.tap(find.text('Possible Duplicate Registration Detected'));
      await tester.pumpAndSettle();

      expect(find.text('Choose the Account You Want to Keep'), findsOneWidget);
      expect(find.text('Account A'), findsOneWidget);
      expect(find.text('Account B'), findsOneWidget);
      // Masked, not raw — the real addresses/emails are not shown verbatim.
      expect(
        find.textContaining('anacleto.dimaculangan@example.com'),
        findsNothing,
      );

      await tester.tap(find.text('Keep This Account').first);
      await tester.pumpAndSettle();
      expect(find.text('Keep This Registration?'), findsOneWidget);
      await tester.tap(find.text('Yes, Keep This Account'));
      await tester.pumpAndSettle();

      expect(find.text('Unverified — Continue Verification'), findsOneWidget);
      expect(
        find.text('Duplicate Registration — Verification Cancelled'),
        findsOneWidget,
      );

      // Neither account's underlying status actually changed to Approved —
      // "keep" is not the same as "Verified".
      expect(MockCatalog.unverifiedDuplicateAccountA.status, isNot('Approved'));
      expect(MockCatalog.unverifiedDuplicateAccountB.status, isNot('Approved'));

      expect(tester.takeException(), isNull);
    },
  );
}
