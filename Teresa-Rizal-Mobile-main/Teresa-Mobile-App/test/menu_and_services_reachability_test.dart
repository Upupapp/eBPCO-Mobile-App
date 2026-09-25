// Every signed-in menu entry and both Services launchers open their screen.
//
// The device walk (integration_test/app_walk_test.dart) reported these 12
// destinations as NOT REACHED on 2026-09-25 at d2aaf24. That was the walk,
// not the app: it looks for a "Menu" tooltip that the Home avatar does not
// carry, and after Pack E made Notifications a pushed screen it can no
// longer find the Home tab to return to. This suite proves each destination
// opens, in the ordinary widget suite, with no device.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/screens/catalog/catalog_detail_screen.dart';
import 'package:teresa_rizal/screens/catalog/dokyu_catalog_screen.dart';
import 'package:teresa_rizal/screens/catalog/tulong_catalog_screen.dart';
import 'package:teresa_rizal/screens/directory/directory_screen.dart';
import 'package:teresa_rizal/screens/legal/privacy_policy_screen.dart';
import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:teresa_rizal/screens/profile/settings_screen.dart';
import 'package:teresa_rizal/screens/shared/documents_uploaded_screen.dart';
import 'package:teresa_rizal/screens/shared/my_requests_screen.dart';
import 'package:teresa_rizal/screens/shared/transactions_screen.dart';
import 'package:teresa_rizal/screens/support/help_support_screen.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Closes the once-per-session promotional banner if it is showing.
Future<void> _dismissBanner(WidgetTester tester) async {
  final close = find.byIcon(Icons.close);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Signs in as the verified demo resident and lands on Home.
Future<void> _signInVerified(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'teresa_rizal_onboarding_complete': true,
  });
  _setPhoneViewport(tester);
  await tester.pumpWidget(const TeresaRizalMobileApp());
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const Key('demo-verified')));
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await _dismissBanner(tester);
  expect(find.byKey(const ValueKey('home-greeting-avatar')), findsOneWidget);
}

/// Opens the menu from the Home avatar and taps [label] inside the sheet.
Future<void> _openFromMenu(WidgetTester tester, String label) async {
  await _tapVisible(tester, find.byKey(const ValueKey('home-greeting-avatar')));
  final sheet = find.byKey(const ValueKey('menu-sheet'));
  expect(sheet, findsOneWidget, reason: 'the Home avatar opens the menu');
  await _tapVisible(
    tester,
    find.descendant(of: sheet, matching: find.text(label)).first,
  );
}

void main() {
  final menuDestinations = <String, Type>{
    'Resident profile': ResidentProfileOverviewScreen,
    'Digital ID': DigitalIdScreen,
    'Settings': SettingsScreen,
    'My requests': MyRequestsScreen,
    'Transactions': TransactionsScreen,
    'Documents': DocumentsUploadedScreen,
    'Directory': DirectoryScreen,
    'Help & Support': HelpSupportScreen,
    'Privacy': PrivacyPolicyScreen,
  };

  for (final entry in menuDestinations.entries) {
    testWidgets('menu "${entry.key}" opens ${entry.value}', (tester) async {
      await _signInVerified(tester);
      await _openFromMenu(tester, entry.key);
      expect(find.byType(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Services sheet → Dokyu opens the Dokyu catalogue', (tester) async {
    await _signInVerified(tester);
    await _tapVisible(tester, find.byKey(const ValueKey('nav-center-action')));
    await _tapVisible(tester, find.byKey(const ValueKey('services-sheet-Dokyu')));
    expect(find.byType(DokyuCatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Services sheet → Tulong opens the Tulong catalogue', (tester) async {
    await _signInVerified(tester);
    await _tapVisible(tester, find.byKey(const ValueKey('nav-center-action')));
    await _tapVisible(tester, find.byKey(const ValueKey('services-sheet-Tulong')));
    expect(find.byType(TulongCatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Services → Dokyu → a service → Start request leaves the detail', (tester) async {
    await _signInVerified(tester);
    await _tapVisible(tester, find.byKey(const ValueKey('nav-center-action')));
    await _tapVisible(tester, find.byKey(const ValueKey('services-sheet-Dokyu')));
    await _tapVisible(tester, find.text('Barangay Clearance').first);
    expect(find.text('Start request'), findsOneWidget);
    final detailRoutes = find.byType(DokyuDetailScreen).evaluate().length;

    await _tapVisible(tester, find.text('Start request'));

    // Start request must do something: push the wizard or open a gate sheet.
    final wizardOrGate = find.byType(DokyuDetailScreen).evaluate().length != detailRoutes ||
        find.textContaining('Step 1').evaluate().isNotEmpty ||
        find.byType(BottomSheet).evaluate().isNotEmpty ||
        find.byType(Dialog).evaluate().isNotEmpty;
    expect(wizardOrGate, isTrue, reason: 'Start request is not inert');
    expect(tester.takeException(), isNull);
  });
}
