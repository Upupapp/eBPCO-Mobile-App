// Coverage for the profile-photo camera-icon flow (Profile > Personal
// Information): the confirmation gate, the source-selection sheet, the
// 6-month change cooldown (and its exemption for seeded demo portraits —
// each demo account must be able to demonstrate this flow once), and that
// a saved photo actually becomes the account's avatar wherever it's shown.
// Actually invoking the native camera/gallery picker isn't exercised here
// (no platform channel implementation exists in a widget-test environment
// — see AttachmentPicker's own tests for the same boundary); this covers
// everything up to that call, plus the persistence/display layer directly
// via ResidentProfileService.updateProfilePhoto.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/models/resident_profile.dart';
import 'package:teresa_rizal/screens/profile/profile_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/utils/demo_resident_photo.dart';

/// A real, minimal, decodable 1x1 transparent PNG — not just arbitrary
/// bytes — so `MemoryImage` actually decodes cleanly wherever it's painted
/// (several avatar call sites have no `onBackgroundImageError` handler,
/// matching how `demoProfileImageFor`'s own seeded assets are always real
/// images too).
final Uint8List _tinyPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
final String _tinyPngBase64 = base64Encode(_tinyPngBytes);

/// profileImageFor/demoProfileImageFor now wrap every avatar in a
/// `ResizeImage` (decode at avatar size, not full source resolution — see
/// those functions' own doc comments) — unwrap it here so these tests can
/// still assert on the underlying provider.
T _unwrapImage<T extends ImageProvider>(ImageProvider? provider) {
  return provider is ResizeImage ? provider.imageProvider as T : provider as T;
}

/// Pre-seeds `teresa_rizal_resident_profiles` with a freshly-seeded profile
/// for [account], optionally with an existing saved photo / cooldown
/// timestamp — the exact JSON shape ResidentProfileService itself
/// persists, so this is indistinguishable from a real prior session.
Map<String, Object> _seededPrefs(
  CitizenAccount account, {
  bool withSavedPhoto = false,
  DateTime? lastProfilePhotoChangeAt,
}) {
  final profile = ResidentProfile.seedFrom(account);
  if (withSavedPhoto) profile.personal.photoBytesBase64 = _tinyPngBase64;
  profile.lastProfilePhotoChangeAt = lastProfilePhotoChangeAt;
  return <String, Object>{
    'teresa_rizal_resident_profiles': jsonEncode({account.id: profile.toJson()}),
  };
}

Future<CitizenSessionService> _loginSession(WidgetTester tester, CitizenAccount account) async {
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

Future<ResidentProfileService> _pumpPersonalInformation(
  WidgetTester tester,
  CitizenAccount account, {
  Map<String, Object>? seededPrefs,
}) async {
  SharedPreferences.setMockInitialValues(seededPrefs ?? <String, Object>{});
  final session = await _loginSession(tester, account);
  final profileService = ResidentProfileService();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<ResidentProfileService>.value(value: profileService),
      ],
      child: const MaterialApp(home: PersonalInformationScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return profileService;
}

void main() {
  group('profileImageFor (shared resolution used by every avatar call site)', () {
    test('a seeded demo account with no saved photo resolves to its demo portrait', () {
      final perlita = MockCatalog.demoAccounts.last;
      final profile = ResidentProfile.seedFrom(perlita);
      final image = _unwrapImage<AssetImage>(profileImageFor(perlita, profile.personal));
      expect(image.assetName, 'assets/images/Perlita Profile.png');
    });

    test('a saved custom photo takes priority over the seeded demo portrait', () {
      final perlita = MockCatalog.demoAccounts.last;
      final profile = ResidentProfile.seedFrom(perlita)..personal.photoBytesBase64 = _tinyPngBase64;
      final image = _unwrapImage<MemoryImage>(profileImageFor(perlita, profile.personal));
      expect(image.bytes, _tinyPngBytes);
    });

    test('null account resolves to null (initials fallback)', () {
      expect(profileImageFor(null, null), isNull);
    });
  });

  group('ResidentProfile profile-photo cooldown', () {
    test('a freshly seeded profile (including every seeded demo account) is never on cooldown', () {
      for (final account in [
        MockCatalog.demoAccounts.first, // Nicanor
        MockCatalog.demoAccounts.last, // Perlita
        MockCatalog.unverifiedDuplicateAccountA, // Anacleto A
        MockCatalog.unverifiedDuplicateAccountB, // Anacleto B
      ]) {
        final profile = ResidentProfile.seedFrom(account);
        expect(profile.lastProfilePhotoChangeAt, isNull);
        expect(profile.isProfilePhotoOnCooldown, isFalse);
        expect(profile.nextProfilePhotoChangeAllowedAt, isNull);
      }
    });

    test('changed 30 days ago is still on cooldown', () {
      final profile = ResidentProfile.seedFrom(MockCatalog.demoAccounts.last)
        ..lastProfilePhotoChangeAt = DateTime.now().subtract(const Duration(days: 30));
      expect(profile.isProfilePhotoOnCooldown, isTrue);
    });

    test('changed 7 months ago is no longer on cooldown', () {
      final sevenMonthsAgo = DateTime.now().subtract(const Duration(days: 213));
      final profile = ResidentProfile.seedFrom(MockCatalog.demoAccounts.last)
        ..lastProfilePhotoChangeAt = sevenMonthsAgo;
      expect(profile.isProfilePhotoOnCooldown, isFalse);
    });
  });

  group('ResidentProfileService.updateProfilePhoto', () {
    test('saving a photo persists its bytes and starts the cooldown; clearing does not', () async {
      final account = MockCatalog.demoAccounts.last;
      SharedPreferences.setMockInitialValues(_seededPrefs(account));
      final service = ResidentProfileService();
      await Future<void>.delayed(Duration.zero);

      await service.updateProfilePhoto(account.id, photoBytes: _tinyPngBytes, startCooldown: true);
      var personal = service.profileFor(account).personal;
      expect(personal.photoBytesBase64, _tinyPngBase64);
      expect(service.profileFor(account).isProfilePhotoOnCooldown, isTrue);

      // Persisted for real — a fresh service instance reading the same
      // mock SharedPreferences backing store sees the same saved photo.
      final reloaded = ResidentProfileService();
      await Future<void>.delayed(Duration.zero);
      expect(reloaded.profileFor(account).personal.photoBytesBase64, _tinyPngBase64);
      expect(reloaded.profileFor(account).isProfilePhotoOnCooldown, isTrue);

      // Clearing (Remove photo) never starts/extends the cooldown.
      final beforeClear = service.profileFor(account).lastProfilePhotoChangeAt;
      await service.updateProfilePhoto(account.id, photoBytes: null, startCooldown: false);
      personal = service.profileFor(account).personal;
      expect(personal.photoBytesBase64, isNull);
      expect(service.profileFor(account).lastProfilePhotoChangeAt, beforeClear);
    });
  });

  group('Camera icon flow on Personal Information', () {
    testWidgets('a fresh demo account (never changed before): tapping the camera icon shows the confirmation first', (
      tester,
    ) async {
      await _pumpPersonalInformation(tester, MockCatalog.demoAccounts.last);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Change Profile Photo'), findsOneWidget);
      expect(
        find.textContaining('Your profile photo can only be changed once every 6 months.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
      // Neither the camera nor the gallery has been touched yet.
      expect(find.text('Take Photo'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
    });

    testWidgets('Cancel on the confirmation closes it and changes nothing', (tester) async {
      final service = await _pumpPersonalInformation(tester, MockCatalog.demoAccounts.last);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Change Profile Photo'), findsNothing);
      expect(find.text('Personal Information'), findsOneWidget); // still on this screen
      expect(service.profileFor(MockCatalog.demoAccounts.last).personal.photoBytesBase64, isNull);
      expect(service.profileFor(MockCatalog.demoAccounts.last).isProfilePhotoOnCooldown, isFalse);
    });

    testWidgets('Proceed opens the Take Photo / Choose from Gallery / Cancel sheet, without opening a picker', (
      tester,
    ) async {
      await _pumpPersonalInformation(tester, MockCatalog.demoAccounts.last);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Cancel closes the sheet without ever reaching a real picker call.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Take Photo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on cooldown: tapping the camera icon shows "Profile Photo Change Unavailable" directly', (
      tester,
    ) async {
      final account = MockCatalog.demoAccounts.last;
      final changedAt = DateTime.now().subtract(const Duration(days: 10));
      await _pumpPersonalInformation(
        tester,
        account,
        seededPrefs: _seededPrefs(account, withSavedPhoto: true, lastProfilePhotoChangeAt: changedAt),
      );

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Profile Photo Change Unavailable'), findsOneWidget);
      expect(
        find.textContaining('profile photos can only be changed once every 6 months'),
        findsOneWidget,
      );
      final nextAllowed = DateTime(changedAt.year, changedAt.month + 6, changedAt.day);
      expect(
        find.textContaining('You can change your profile photo again on ${DateFormat('MMMM d, y').format(nextAllowed)}'),
        findsOneWidget,
      );
      // The confirmation step, and the source sheet, must never appear.
      expect(find.text('Proceed'), findsNothing);
      expect(find.text('Take Photo'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Photo Change Unavailable'), findsNothing);
    });

    testWidgets('Remove photo clears the saved photo without starting the cooldown', (tester) async {
      final account = MockCatalog.demoAccounts.last;
      final service = await _pumpPersonalInformation(
        tester,
        account,
        seededPrefs: _seededPrefs(account, withSavedPhoto: true),
      );

      expect(find.text('Remove photo'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();

      expect(service.profileFor(account).personal.photoBytesBase64, isNull);
      expect(find.text('Profile photo (optional)'), findsOneWidget);
      expect(service.profileFor(account).isProfilePhotoOnCooldown, isFalse);

      // Camera icon shows the normal confirmation again, not the cooldown
      // notice — removing is not "changing to a new photo".
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Change Profile Photo'), findsOneWidget);
      expect(find.text('Profile Photo Change Unavailable'), findsNothing);
    });
  });

  group('A saved photo becomes the avatar everywhere the account is shown', () {
    testWidgets('Profile screen shows the saved photo, not the seeded demo portrait', (tester) async {
      final account = MockCatalog.demoAccounts.last;
      SharedPreferences.setMockInitialValues(_seededPrefs(account, withSavedPhoto: true));
      final session = await _loginSession(tester, account);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider<RequestsService>(create: (_) => RequestsService(seedDemoData: false)),
            ChangeNotifierProvider<NotificationsService>(create: (_) => NotificationsService()),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      final image = _unwrapImage<MemoryImage>(avatar.backgroundImage);
      expect(image.bytes, _tinyPngBytes);
      expect(tester.takeException(), isNull);
    });

    // Digital ID's own coverage moved to digital_id_wallet_test.dart — the
    // screen was redesigned into a credential wallet (Barangay Resident
    // ID / PWD ID) and no longer shows the resident's own profile photo at
    // all, so there is nothing left to assert here.
  });
}
