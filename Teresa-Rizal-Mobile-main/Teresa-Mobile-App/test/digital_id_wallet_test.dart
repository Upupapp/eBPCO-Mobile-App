// Digital ID is one resident card for a verified holder. Household members
// do not get a card. The registration-uploaded ID stays off this screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/resident_id.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';

Future<CitizenSessionService> _signedInAs(WidgetTester tester, dynamic account) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
  return session;
}

Future<void> _pumpWallet(WidgetTester tester, CitizenSessionService session) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<CitizenSessionService>.value(
      value: session,
      child: const MaterialApp(home: DigitalIdScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Verified Perlita — resident Digital ID', () {
    testWidgets('shows the sample resident id and not the old credential stack', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.verified);
      expect(find.text('Resident Digital ID'), findsOneWidget);
      expect(find.text(ResidentId.verifiedSample), findsWidgets);
      expect(find.text('SAMPLE'), findsOneWidget);
      expect(find.text('Your Digital ID is locked'), findsNothing);
      expect(find.text('Barangay Resident ID'), findsNothing);
      expect(find.text('1 of 2'), findsNothing);
      expect(find.text('PWD ID'), findsNothing);
      expect(find.text('Submitted Government ID'), findsNothing);
      expect(find.text('Postal ID (PHLPost)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no RenderFlex overflow on a narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await tester.pumpWidget(
        ChangeNotifierProvider<CitizenSessionService>.value(
          value: session,
          child: const MaterialApp(home: DigitalIdScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Unverified accounts — card stays locked', () {
    testWidgets('Nicanor sees the locked state', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.first);
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.unverified);
      expect(find.text('Your Digital ID is locked'), findsOneWidget);
      expect(find.text(ResidentId.verifiedSample), findsNothing);
      expect(find.text('Barangay Resident ID'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('duplicate Perlita registration also sees the locked state', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.duplicateVerifiedDemoAccount);
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.unverified);
      expect(find.text('Your Digital ID is locked'), findsOneWidget);
      expect(find.text(ResidentId.verifiedSample), findsNothing);
    });
  });
}
