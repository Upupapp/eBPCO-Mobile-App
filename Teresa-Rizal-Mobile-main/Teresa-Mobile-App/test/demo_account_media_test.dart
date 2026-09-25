// Coverage for Nicanor Sarmiento's and Anacleto Dimaculangan's profile photo +
// submitted government ID — the same single-source-of-truth architecture
// already used for Perlita (see utils/demo_resident_photo.dart and
// utils/government_id.dart), just extended to two more seeded residents.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/utils/demo_resident_photo.dart';
import 'package:teresa_rizal/utils/government_id.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

/// demoProfileImageFor now wraps every portrait in a `ResizeImage` (decode
/// at avatar size, not the source's full multi-megapixel resolution — see
/// that function's own doc comment) — unwrap it here so these tests can
/// still assert on the underlying asset name.
AssetImage _unwrapAssetImage(ImageProvider? provider) {
  return provider is ResizeImage ? provider.imageProvider as AssetImage : provider as AssetImage;
}

Future<CitizenSessionService> _signedInAs(WidgetTester tester, CitizenAccount account) async {
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

Future<void> _pumpDigitalId(WidgetTester tester, CitizenSessionService session) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<CitizenSessionService>.value(value: session, child: const MaterialApp(home: DigitalIdScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Asset lookups (no widgets — proves the single source of truth resolves correctly)', () {
    test('Nicanor has his own profile photo and government ID, distinct from Perlita and Anacleto', () {
      final nicanor = MockCatalog.demoAccounts.first;
      expect(nicanor.firstName, 'Nicanor');
      final photo = _unwrapAssetImage(demoProfileImageFor(nicanor));
      expect(photo.assetName, pendingDemoProfilePhotoAsset);
      expect(pendingDemoProfilePhotoAsset, 'assets/images/Nicanor Sarmiento.png');

      final id = governmentIdFor(nicanor);
      expect(id, isNotNull);
      expect(id!.assetPath, 'assets/images/NICANOR ID DEMO.png');
      expect(id.accountId, nicanor.id);
    });

    test('Both Anacleto duplicate accounts share the same photo and the same government ID record', () {
      final a = MockCatalog.unverifiedDuplicateAccountA;
      final b = MockCatalog.unverifiedDuplicateAccountB;
      expect(a.id, isNot(b.id)); // distinct accounts internally

      final photoA = _unwrapAssetImage(demoProfileImageFor(a));
      final photoB = _unwrapAssetImage(demoProfileImageFor(b));
      expect(photoA.assetName, duplicateDemoProfilePhotoAsset);
      expect(photoB.assetName, duplicateDemoProfilePhotoAsset);
      expect(duplicateDemoProfilePhotoAsset, 'assets/images/Anacleto Dimaculangan.png');

      final idA = governmentIdFor(a);
      final idB = governmentIdFor(b);
      expect(idA, isNotNull);
      expect(idA!.assetPath, 'assets/images/ANACLETO ID DEMO.png');
      expect(idA, same(idB)); // literally the same record, not two copies
    });

    test('an unrelated account (Perlita) never resolves to Nicanor or Anacleto assets', () {
      final perlita = MockCatalog.demoAccounts.last;
      final photo = _unwrapAssetImage(demoProfileImageFor(perlita));
      expect(photo.assetName, isNot(pendingDemoProfilePhotoAsset));
      expect(photo.assetName, isNot(duplicateDemoProfilePhotoAsset));
      expect(governmentIdFor(perlita)!.assetPath, isNot('assets/images/NICANOR ID DEMO.png'));
    });
  });

  group('Digital ID screen', () {
    // The registration-uploaded ID document is a different concept from the
    // Teresa, Rizal Digital ID and is never shown on this screen — see Profile >
    // Personal Information's own coverage in submitted_government_id_test.dart.
    testWidgets('Nicanor (Unverified): no Teresa, Rizal Digital ID, and no registration ID document either', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.first);
      expect(session.account!.firstName, 'Nicanor');
      expect(session.accessLevel, AccessLevel.unverified);
      expect(session.account!.status, 'Pending Review');

      await _pumpDigitalId(tester, session);

      expect(find.text('Teresa, Rizal Digital ID'), findsNothing);
      expect(find.text('Your Digital ID is locked'), findsOneWidget);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Teresa, Rizal Resident ID'), findsNothing);
      expect(find.byType(AppButton), findsNothing);

      // Nicanor remains Unverified — an uploaded/submitted ID never
      // implies verification on its own.
      expect(session.account!.status, 'Pending Review');
      expect(session.accessLevel, AccessLevel.unverified);
    });

    testWidgets('Anacleto Account A (Unverified duplicate): no registration ID document, no verified Digital ID', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.unverifiedDuplicateAccountA);
      await _pumpDigitalId(tester, session);

      expect(find.text('Teresa, Rizal Digital ID'), findsNothing);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Teresa, Rizal Resident ID'), findsNothing);
      expect(session.account!.status, 'Pending Review');
    });

    testWidgets('Anacleto Account B (Unverified duplicate): no registration ID document, no verified Digital ID', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.unverifiedDuplicateAccountB);
      await _pumpDigitalId(tester, session);

      expect(find.text('Teresa, Rizal Digital ID'), findsNothing);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Teresa, Rizal Resident ID'), findsNothing);
      expect(session.account!.status, 'Pending Review');
    });
  });
}
