// Signing out must actually erase the citizen's data from the device.
//
// `CitizenSessionService.logout()` cleared two of the app's ten preference
// keys: the session and the guest flag. Everything else stayed — the resident
// profile (birthdate, address, household, family, and the base64 profile
// photo), the whole request history, uploaded Master File documents, and the
// notification bookkeeping. All of it in plaintext XML on Android.
//
// That is not an abstract concern for this app. It is a municipal service used
// on shared and family handsets, and on a barangay-hall device the next person
// to sign in inherits a phone still holding the previous citizen's records.
// They would not *see* them — every service keys by account id — but "not
// rendered" is not "erased".
//
// These tests assert against **what is left in SharedPreferences**, not against
// the code path. Trusting the code path is how the gap existed in the first
// place: `logout()` looked like it cleaned up, and did, for its own two keys.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/services/sign_out.dart';

const _accountId = 'ESP-TEST-SIGNOUT';

CitizenAccount _account() => CitizenAccount(
      id: _accountId,
      firstName: 'Test',
      lastName: 'Resident',
      email: 'test@example.com',
      mobile: '0900 000 0000',
      barangay: 'Poblacion',
      purok: 'Purok 1',
      address: 'Purok 1, Brgy. Poblacion',
      birthdate: '1970-01-01',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 100,
      status: 'Approved',
    );

ServiceRequest _request() => ServiceRequest(
      id: 'req-signout-fixture',
      referenceNumber: 'ESP-2026-999999',
      applicantId: _accountId,
      applicantName: 'Test Resident',
      typeName: 'Barangay Clearance',
      category: ServiceCategory.dokyu,
      office: 'Barangay Hall',
      purpose: 'Sign-out erasure fixture',
      submittedAt: DateTime(2026, 3, 1),
      status: 'Submitted',
      statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 3, 1), actor: 'Citizen')],
      attachments: const [],
      expectedDays: '1-2 working days',
    );

Future<void> _settle(WidgetTester tester, bool Function() ready, String what) async {
  var attempts = 0;
  while (!ready()) {
    attempts++;
    if (attempts > 100) throw StateError('$what never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  group('Signing out erases the account from the device', () {
    late CitizenSessionService session;
    late RequestsService requests;
    late ResidentProfileService profiles;
    late MasterFileService masterFile;
    late NotificationsService notifications;

    Future<void> setUpSignedIn(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        // A device that already holds this citizen's data, as a real one would.
        'teresa_rizal_service_requests': jsonEncode([_request().toJson()]),
        'teresa_rizal_read_notification_ids': jsonEncode(['notif-1', 'notif-2']),
        'teresa_rizal_duplicate_alert_resolutions': jsonEncode({'scenario-a': 'kept'}),
        'teresa_rizal_onboarding_complete': true,
      });

      session = CitizenSessionService();
      requests = RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: false);
      profiles = ResidentProfileService();
      masterFile = MasterFileService();
      notifications = NotificationsService();

      await _settle(tester, () => !session.loading, 'CitizenSessionService');
      await _settle(tester, () => requests.loaded, 'RequestsService');
      await _settle(tester, () => profiles.loaded, 'ResidentProfileService');
      await _settle(tester, () => masterFile.loaded, 'MasterFileService');
      await _settle(tester, () => notifications.loaded, 'NotificationsService');

      await session.login(_account());
    }

    Future<void> signOut() => SignOut.signOut(
          session,
          requests: requests,
          profiles: profiles,
          masterFile: masterFile,
          notifications: notifications,
        );

    testWidgets('the request history is gone from disk, not just from the screen', (tester) async {
      await setUpSignedIn(tester);
      expect(requests.all, hasLength(1), reason: 'fixture should be loaded before we test erasure');

      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      expect(requests.all, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString('teresa_rizal_service_requests');
      expect(
        raw == null || !raw.contains(_accountId),
        isTrue,
        reason: 'the stored bytes still name the signed-out citizen: $raw',
      );
    });

    testWidgets('notification bookkeeping is cleared', (tester) async {
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('teresa_rizal_read_notification_ids'), isNull);
      expect(prefs.getString('teresa_rizal_duplicate_alert_resolutions'), isNull);
      expect(prefs.getString('teresa_rizal_unverified_duplicate_kept_account'), isNull);
    });

    testWidgets('the session and guest flag are cleared too', (tester) async {
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      expect(session.isSignedIn, isFalse);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('teresa_rizal_citizen_session'), isNull);
      expect(prefs.getBool('teresa_rizal_guest_mode'), isNull);
    });

    testWidgets('onboarding completion survives — it is device state, not personal data', (tester) async {
      // Erasing this would re-show the three-screen welcome flow to whoever
      // picks the handset up next. That is noise, not privacy.
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool('teresa_rizal_onboarding_complete'), isTrue);
    });

    testWidgets('signing out with no account signed in does not throw', (tester) async {
      SharedPreferences.setMockInitialValues({});
      session = CitizenSessionService();
      requests = RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: false);
      profiles = ResidentProfileService();
      masterFile = MasterFileService();
      notifications = NotificationsService();
      await _settle(tester, () => !session.loading, 'CitizenSessionService');
      await _settle(tester, () => requests.loaded, 'RequestsService');
      await _settle(tester, () => profiles.loaded, 'ResidentProfileService');
      await _settle(tester, () => masterFile.loaded, 'MasterFileService');
      await _settle(tester, () => notifications.loaded, 'NotificationsService');

      await expectLater(signOut(), completes);
    });
  });
}
