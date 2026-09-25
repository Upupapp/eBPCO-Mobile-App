// Smoke test: the app boots to the citizen login screen when no session
// is stored (SharedPreferences is empty by default in the test harness).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';

void main() {
  testWidgets('App boots to the citizen login screen', (
    WidgetTester tester,
  ) async {
    // Onboarding-complete pre-seeded: this suite exercises the normal
    // returning-user flow (Login/Guest-Home), not the first-run Onboarding
    // screens — see onboarding_flow_test.dart for that.
    SharedPreferences.setMockInitialValues({
      'teresa_rizal_onboarding_complete': true,
    });
    await tester.pumpWidget(const TeresaRizalMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Sign in'),
      findsNothing,
    ); // AppButton isn't a Material ElevatedButton
    expect(find.text('Sign in'), findsOneWidget);
  });
}
