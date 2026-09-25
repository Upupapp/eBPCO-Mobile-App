// A request must never be re-filed under a service it did not belong to.
//
// `ServiceRequest.fromJson` used to fall back to `ServiceCategory.dokyu` for a
// category this build no longer recognises, so a citizen's Tulong (assistance)
// or Sakuna (incident) application silently became a document request — wrong
// tab, wrong catalogue, wrong flow, with nothing indicating anything was wrong.
//
// The fallback is now `ServiceCategory.unknown`. The record is kept, because
// its reference number, dates, status history and attachments are all still
// true and the citizen cannot reconstruct them; it is simply not claimed by any
// service it may not belong to.
//
// Note the second, quieter version of the same bug that this also closes: the
// request card derived its chip from `category == dokyu ? 'Dokyu' : 'Tulong'`,
// which labels *anything* non-Dokyu as Tulong. Fixing only the decode would
// have moved the false statement rather than removed it.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/requests_service.dart';

Map<String, dynamic> _persistedRequest({required String category}) => ServiceRequest(
      id: 'fixture-unknown-category',
      referenceNumber: 'AR-2026-000042',
      applicantId: 'ESP-RES-0000-0000',
      applicantName: 'Test Fixture',
      typeName: 'Medical Assistance',
      category: ServiceCategory.tulong,
      office: 'MSWDO',
      purpose: 'Category fallback fixture',
      submittedAt: DateTime(2026, 3, 1),
      status: 'Submitted',
      statusHistory: const [],
      attachments: const [],
      expectedDays: '3-5 working days',
    ).toJson()
      ..['category'] = category;

Future<void> _settle(WidgetTester tester, bool Function() isLoaded) async {
  var attempts = 0;
  while (!isLoaded()) {
    if (attempts++ > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  group('an unreadable category decodes to unknown, not to a real service', () {
    test('a renamed ServiceCategory falls back to unknown', () {
      final request = ServiceRequest.fromJson(_persistedRequest(category: 'tulongV2'));

      expect(request.category, ServiceCategory.unknown);
      // Everything else about the record is intact — only the category was
      // unreadable, and that is the only thing withheld.
      expect(request.referenceNumber, 'AR-2026-000042');
      expect(request.typeName, 'Medical Assistance');
      expect(request.office, 'MSWDO');
    });

    test('it does not fall back to dokyu', () {
      // The specific regression: an assistance application presented as a
      // document request is a false statement about what the citizen filed.
      expect(
        ServiceRequest.fromJson(_persistedRequest(category: 'assistance')).category,
        isNot(ServiceCategory.dokyu),
      );
    });

    test('a readable category is unaffected', () {
      expect(ServiceRequest.fromJson(_persistedRequest(category: 'dokyu')).category, ServiceCategory.dokyu);
      expect(ServiceRequest.fromJson(_persistedRequest(category: 'tulong')).category, ServiceCategory.tulong);
      expect(
        ServiceRequest.fromJson(_persistedRequest(category: 'sakunaIncident')).category,
        ServiceCategory.sakunaIncident,
      );
    });
  });

  group('an unknown category is labelled honestly, not as Tulong', () {
    test('the shared label says Unrecognised', () {
      expect(ServiceCategory.unknown.label, 'Unrecognised');
      // Guards the ternary this replaced: everything non-Dokyu used to read
      // as Tulong.
      expect(ServiceCategory.unknown.label, isNot('Tulong'));
      expect(ServiceCategory.unknown.label, isNot('Dokyu'));
    });

    test('the readable categories keep their own names', () {
      expect(ServiceCategory.dokyu.label, 'Dokyu');
      expect(ServiceCategory.tulong.label, 'Tulong');
      expect(ServiceCategory.sakunaIncident.label, 'Sakuna');
    });
  });

  group('an unknown request is claimed by no service', () {
    testWidgets('it is counted under neither Dokyu nor Tulong', (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([_persistedRequest(category: 'tulongV2')]),
      });

      final requests = RequestsService(seedDemoData: false);
      await _settle(tester, () => requests.loaded);

      // Kept, because the record is real...
      expect(requests.all, hasLength(1));
      expect(requests.all.single.referenceNumber, 'AR-2026-000042');
      // ...but never counted as a service it may not belong to.
      expect(requests.byCategory(ServiceCategory.dokyu), isEmpty);
      expect(requests.byCategory(ServiceCategory.tulong), isEmpty);
      expect(requests.byCategory(ServiceCategory.sakunaIncident), isEmpty);
    });
  });
}
