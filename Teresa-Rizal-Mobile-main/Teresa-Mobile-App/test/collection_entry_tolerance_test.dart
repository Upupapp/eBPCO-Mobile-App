// One unreadable record must cost that record — not a citizen's whole history.
//
// `PersistenceRecovery.discardUnreadable` is all-or-nothing by design: it
// clears an entire key. That is right for a payload that is not a collection at
// all, and much too blunt for one that is. A citizen's filed requests are the
// part of this app they cannot reconstruct; losing all of them because a single
// record went bad is a worse outcome than the hang the guards already fixed,
// because it is silent and permanent.
//
// These cases sit *inside* the guard rather than beside it: each payload is
// valid JSON, of the right root type, containing one readable record and one
// unreadable one. The service must keep the readable one.
//
// Picking a failure mode for these is harder than it looks, and the reason is
// worth recording. Every persisted enum now carries an `orElse`, so an unknown
// enum value no longer throws. `statusHistory` and `attachments` used to throw
// on a bare `as List`, but both now default to empty — that was the follow-on
// this file's first version relied on, and closing it broke these tests, which
// is the correct outcome and exactly what a real gate should do.
//
// What still throws per record is a required non-null scalar arriving as null,
// and a malformed `submittedAt`, since `DateTime.parse` rejects it. Both are
// live version-skew triggers: a field renamed between builds reads as null.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/announcement.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/persistence_recovery.dart';
import 'package:teresa_rizal/services/requests_service.dart';

/// Pumps until [isLoaded], failing loudly rather than hanging the suite.
Future<void> _settle(WidgetTester tester, bool Function() isLoaded, String what) async {
  var attempts = 0;
  while (!isLoaded()) {
    attempts++;
    if (attempts > 100) {
      throw StateError('$what never finished loading.');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// A persisted request, built from a real [ServiceRequest] rather than a
/// hand-written map, so a new required field on the model breaks this at
/// compile time instead of quietly turning the test into a no-op.
Map<String, dynamic> _persistedRequest(String reference) => ServiceRequest(
      id: 'fixture-$reference',
      referenceNumber: reference,
      applicantId: 'ESP-RES-0000-0000',
      applicantName: 'Test Fixture',
      typeName: 'Barangay Clearance',
      category: ServiceCategory.dokyu,
      office: 'Barangay Hall',
      purpose: 'Entry-tolerance fixture',
      submittedAt: DateTime(2026, 3, 1),
      status: 'Submitted',
      statusHistory: const [],
      attachments: const [],
      expectedDays: '1-2 working days',
    ).toJson();

void main() {
  setUp(PersistenceRecovery.resetForTest);

  group('A single unreadable record does not cost the whole collection', () {
    testWidgets('a request with an unreadable field survives its neighbour', (tester) async {
      final good = _persistedRequest('ESP-2026-000001');
      // A required non-null scalar arriving as null — what a field renamed
      // between builds actually looks like on the way back in.
      final bad = _persistedRequest('ESP-2026-000002')..remove('expectedDays');

      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([bad, good]),
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded, 'RequestsService');

      // The readable request is the whole point: before entry-tolerant
      // decoding, the throw from `bad` reached the service's catch and
      // discarded the entire key, taking `good` with it.
      expect(requests.all.map((r) => r.referenceNumber), contains('ESP-2026-000001'));
      expect(requests.all.map((r) => r.referenceNumber), isNot(contains('ESP-2026-000002')));
    });

    testWidgets('the key survives — this is a skip, not a discard', (tester) async {
      final good = _persistedRequest('ESP-2026-000003');
      // A date this build cannot parse.
      final bad = _persistedRequest('ESP-2026-000004')..['submittedAt'] = 'not-a-date';

      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([bad, good]),
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded, 'RequestsService');

      expect(requests.all, hasLength(1));
      // A skipped entry must not be reported as a discarded key: the two are
      // different events with different costs, and conflating them would hide
      // whole-key data loss behind routine noise.
      expect(
        PersistenceRecovery.discards.where((d) => d.service == 'RequestsService'),
        isEmpty,
        reason: 'skipping one entry is not discarding the key',
      );
    });

    testWidgets('a malformed balita post does not empty the feed', (tester) async {
      final good = Announcement(
        id: 'post-good',
        official: 'Teresa, Rizal LGU',
        author: 'Barangay Hall',
        body: 'All residents are invited to the barangay assembly on Saturday.',
        time: '2h ago',
        likes: 0,
      ).toJson();

      SharedPreferences.setMockInitialValues({
        'teresa_rizal_balita_posts': jsonEncode([
          {'not': 'an announcement'},
          good,
        ]),
      });

      final balita = BalitaService();
      await _settle(tester, () => balita.loaded, 'BalitaService');

      expect(balita.posts.map((p) => p.id), contains('post-good'));
    });

    testWidgets('a payload that is not a collection at all still discards the key', (tester) async {
      // The complement of the cases above, and the reason the service keeps its
      // own catch: entry-tolerance handles a bad *entry*, while a payload of
      // the wrong root type has no entries to be tolerant of and must still
      // fall through to the whole-key discard.
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': '{"unexpected":"object where a list belongs"}',
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded, 'RequestsService');

      expect(requests.all, isEmpty);
      expect(
        PersistenceRecovery.discards.map((d) => d.service),
        contains('RequestsService'),
        reason: 'a wrong-root-type payload is a discard, and must still be recorded as one',
      );
    });
  });
}
