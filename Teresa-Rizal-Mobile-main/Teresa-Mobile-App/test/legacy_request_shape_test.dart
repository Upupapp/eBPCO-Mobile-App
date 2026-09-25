// A request written before a field existed must survive, and must not move the
// crash somewhere else.
//
// `ServiceRequest.fromJson` cast `statusHistory` and `attachments` with a bare
// `as List` and no default — the only unguarded list casts left in any model.
// `flaggedRequirements` and `formFields` on the same factory already defaulted,
// as does every list in `Announcement` and `ResidentProfile`. So a record
// persisted before either field existed threw, and because nothing awaits the
// restore that throw originally stranded the app; after entry-tolerant decoding
// it cost the whole record instead. Neither is a reasonable price for a field
// whose absence just means "none recorded".
//
// The second half of this file is the part worth keeping. Defaulting
// `statusHistory` to `[]` is only safe if nothing assumes it is non-empty, and
// three places did: `canAdvance`, `nextMilestone` and the timeline's
// `isRejected` all called `.last`, which throws `StateError` on an empty list.
// Fixing the decode alone would have relocated the crash from restore into the
// UI rather than removing it.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/request_milestone_timeline.dart';

/// A persisted request, built from the real model so a new required field
/// breaks this at compile time rather than silently weakening it.
Map<String, dynamic> _persisted({List<String> dropFields = const []}) {
  final json = ServiceRequest(
    id: 'legacy-shape-fixture',
    referenceNumber: 'DR-2026-000007',
    applicantId: 'ESP-RES-0000-0000',
    applicantName: 'Test Fixture',
    typeName: 'Barangay Clearance',
    category: ServiceCategory.dokyu,
    office: 'Barangay Hall',
    purpose: 'Legacy shape fixture',
    submittedAt: DateTime(2026, 3, 1),
    status: 'Submitted',
    statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 3, 1), actor: 'Citizen')],
    attachments: const [],
    expectedDays: '1-2 working days',
  ).toJson();
  for (final field in dropFields) {
    json.remove(field);
  }
  return json;
}

Future<void> _settle(WidgetTester tester, bool Function() isLoaded) async {
  var attempts = 0;
  while (!isLoaded()) {
    if (attempts++ > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  group('a record written before a list field existed still decodes', () {
    test('a missing attachments list defaults to empty', () {
      final request = ServiceRequest.fromJson(_persisted(dropFields: ['attachments']));

      expect(request.attachments, isEmpty);
      expect(request.referenceNumber, 'DR-2026-000007');
    });

    test('a missing statusHistory defaults to empty', () {
      final request = ServiceRequest.fromJson(_persisted(dropFields: ['statusHistory']));

      expect(request.statusHistory, isEmpty);
      // The record's own status is a separate field and is untouched — the
      // history is unknown, not the status.
      expect(request.status, 'Submitted');
    });

    test('both missing at once still decodes', () {
      final request = ServiceRequest.fromJson(_persisted(dropFields: ['statusHistory', 'attachments']));

      expect(request.statusHistory, isEmpty);
      expect(request.attachments, isEmpty);
      expect(request.typeName, 'Barangay Clearance');
    });

    testWidgets('such a record is restored rather than skipped', (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([_persisted(dropFields: ['statusHistory', 'attachments'])]),
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded);

      // Entry-tolerant decoding meant this record was skipped rather than
      // fatal; defaulting the fields means it is not lost at all.
      expect(requests.all, hasLength(1));
      expect(requests.all.single.referenceNumber, 'DR-2026-000007');
    });
  });

  group('an empty history does not move the crash into the UI', () {
    testWidgets('the demo advance controls treat no history as not advanceable', (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([_persisted(dropFields: ['statusHistory'])]),
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded);

      // Both of these called `.last` on the history and threw StateError.
      expect(requests.canAdvance('legacy-shape-fixture'), isFalse);
      expect(requests.nextMilestone('legacy-shape-fixture'), isNull);
    });

    testWidgets('the timeline renders an empty history without throwing', (tester) async {
      final request = ServiceRequest.fromJson(_persisted(dropFields: ['statusHistory']));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RequestMilestoneTimeline(request: request, accent: AppColors.brand600),
            ),
          ),
        ),
      );
      await tester.pump();

      // `isRejected` read `statusHistory.last.status`. No recorded history is
      // not a rejection, and must not be an exception either.
      expect(tester.takeException(), isNull);
    });
  });
}
