// Coverage for the live-demo cleanup: the real app now starts Dokyu/Tulong
// with nothing pre-submitted (RequestsService(seedDemoData: false,
// retireLegacyDemoRequestSeeds: true) in main.dart), and a device that
// already persisted the old seeded requests under an earlier build has them
// safely stripped on next load — never a citizen's own genuinely-submitted
// request, and never anything when the caller still wants the demo fixtures
// (seedDemoData: true, used unchanged by many other test files).
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/utils/tulong_eligibility.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';
const _verifiedDemoName = 'Perlita Quiambao';

/// The exact eight ids RequestsService's own seeding used to create (three
/// Dokyu, three Tulong status-simulation demos, plus two Dokyu already-paid
/// demos) — copied literally here (not imported) so this test independently
/// proves the cleanup targets these specific, known ids rather than relying
/// on the same constant the implementation itself uses. There is no Tulong
/// already-paid demo — Tulong assistance applications never have a payment
/// method or receipt (see the Mobile-only final request-flow correction
/// pass); an earlier build's seed briefly had one
/// ('demo-paid-tulong-pension-onsite'), since removed.
const _legacySeedIds = [
  'demo-dokyu-barangay-clearance',
  'demo-dokyu-business-permit',
  'demo-dokyu-certificate-indigency',
  'demo-tulong-medical',
  'demo-tulong-financial',
  'demo-tulong-educational',
  'demo-paid-dokyu-residency-gcash',
  'demo-paid-dokyu-rpt-maya',
];

ServiceRequest _legacySeedFixture(String id, ServiceCategory category) => ServiceRequest(
  id: id,
  referenceNumber: 'DR-2026-DEMO',
  applicantId: _verifiedDemoId,
  applicantName: _verifiedDemoName,
  typeName: 'Some Legacy Demo Type',
  category: category,
  office: 'Some Office',
  purpose: 'Demo',
  submittedAt: DateTime(2026, 1, 1),
  status: 'Approved',
  statusHistory: [StatusHistoryEntry(status: 'Approved', at: DateTime(2026, 1, 1), actor: 'Demo Simulation')],
  attachments: const [],
  expectedDays: '1-2 working days',
);

ServiceRequest _genuineRequestFixture() => ServiceRequest(
  id: 'req-1700000000000',
  referenceNumber: 'DR-2026-0001',
  applicantId: _verifiedDemoId,
  applicantName: _verifiedDemoName,
  typeName: 'Barangay Clearance',
  category: ServiceCategory.dokyu,
  office: 'Barangay Hall',
  purpose: 'Genuine live-submitted request',
  submittedAt: DateTime(2026, 3, 1),
  status: 'Submitted',
  statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 3, 1), actor: 'Citizen')],
  attachments: const [],
  expectedDays: '1-2 working days',
);

Future<RequestsService> _ready(RequestsService requests, WidgetTester tester) async {
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

void main() {
  group('Real-app construction (seedDemoData: false, retireLegacyDemoRequestSeeds: true)', () {
    testWidgets('a fresh install has zero Dokyu/Tulong requests — no fake pre-submitted demo data', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );

      expect(requests.all, isEmpty);
      expect(requests.byCategory(ServiceCategory.dokyu), isEmpty);
      expect(requests.byCategory(ServiceCategory.tulong), isEmpty);
    });

    testWidgets(
      'a device that already persisted the eight legacy seeded requests has them removed, '
      'but a genuinely-submitted request is preserved untouched',
      (tester) async {
        final legacySeeds = _legacySeedIds
            .map((id) => _legacySeedFixture(id, id.contains('tulong') ? ServiceCategory.tulong : ServiceCategory.dokyu))
            .toList();
        final genuine = _genuineRequestFixture();
        SharedPreferences.setMockInitialValues({
          'teresa_rizal_service_requests': jsonEncode([...legacySeeds, genuine].map((r) => r.toJson()).toList()),
        });

        final requests = await _ready(
          RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
          tester,
        );

        // Every one of the nine legacy seed ids is gone.
        for (final id in _legacySeedIds) {
          expect(requests.all.any((r) => r.id == id), isFalse, reason: '$id should have been removed');
        }
        // The citizen's own genuinely-submitted request is completely
        // untouched — same id, status, and reference number.
        expect(requests.all.length, 1);
        final preserved = requests.all.single;
        expect(preserved.id, genuine.id);
        expect(preserved.referenceNumber, genuine.referenceNumber);
        expect(preserved.status, genuine.status);
      },
    );

    testWidgets('the cleanup is persisted — reloading from the same storage does not resurrect the seeds', (
      tester,
    ) async {
      final legacySeeds = _legacySeedIds.map((id) => _legacySeedFixture(id, ServiceCategory.dokyu)).toList();
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode(legacySeeds.map((r) => r.toJson()).toList()),
      });

      await _ready(RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true), tester);

      // A second instance reading the same (now-cleaned) SharedPreferences
      // store — simulates relaunching the app — still finds nothing.
      final reloaded = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );
      expect(reloaded.all, isEmpty);
    });
  });

  group('seedDemoData: true is unaffected by this cleanup (existing test fixtures still work)', () {
    testWidgets('the demo status-simulation and paid-transaction fixtures still seed normally', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(RequestsService(seedDemoData: true), tester);

      for (final id in _legacySeedIds) {
        expect(requests.all.any((r) => r.id == id), isTrue, reason: '$id should still seed when seedDemoData is true');
      }
    });
  });

  group('Live submission after cleanup', () {
    testWidgets('a newly-submitted request persists normally and appears in all/byCategory', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );
      expect(requests.all, isEmpty);

      final submitted = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
        requiresPayment: true,
        fee: '₱50.00',
      );

      expect(requests.all, hasLength(1));
      expect(requests.byCategory(ServiceCategory.dokyu), hasLength(1));
      expect(submitted.status, 'Submitted');
      expect(submitted.referenceNumber, isNotEmpty);

      // Survives a fresh reload from storage exactly like any real request.
      final reloaded = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );
      expect(reloaded.all, hasLength(1));
      expect(reloaded.all.single.referenceNumber, submitted.referenceNumber);
    });
  });

  group('Tulong eligibility/reapplication rules after seed cleanup', () {
    testWidgets('a fresh account is eligible for every assistance type with no seeded history in the way', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );

      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
    });

    testWidgets('an active live-submitted application blocks a duplicate for the same assistance', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );

      await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Hospital bill assistance',
        expectedDays: '3-5 working days',
        attachments: const [],
      );

      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isFalse);
      expect(result.status, TulongEligibility.blockedActive);
    });

    testWidgets('a rejected live-submitted application allows reapplying for the same assistance', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _ready(
        RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        tester,
      );

      final rejected = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        purpose: 'Tuition support',
        expectedDays: '10-15 working days',
        attachments: const [],
      );
      await requests.rejectDemo(rejected.id, reason: 'Missing enrollment document.');

      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Educational Assistance');
      expect(result.isEligible, isTrue);
    });
  });
}
