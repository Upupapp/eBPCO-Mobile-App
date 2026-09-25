// Coverage for the seeded Educational Assistance (Tulong) demo request's
// placeholder rejection reason and RequestDetailScreen's "Application
// Rejected" panel: the reason/guidance display, Apply Again opening a
// brand-new application without touching the original rejected request,
// the new application getting its own reference number, and Apply Again
// still respecting the Tulong eligibility rule (see utils/tulong_eligibility.dart)
// when another active application for the same assistance also exists.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';
const _verifiedDemoName = 'Perlita Quiambao';
const _rejectionReason = 'Submitted school enrollment document could not be verified for the current academic '
    'term. Please submit an updated Certificate of Enrollment or Registration issued by the school.';
const _rejectionGuidance = 'Upload an updated school document and submit a new Educational Assistance application.';

Future<RequestsService> _readyRequests(WidgetTester tester, {required bool seedDemoData}) async {
  final requests = RequestsService(seedDemoData: seedDemoData);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<CitizenSessionService> _signedInAsVerifiedDemo(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  return session;
}

Future<void> _pumpDetail(
  WidgetTester tester,
  RequestsService requests,
  CitizenSessionService session,
  String requestId,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
      ],
      child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Seeded Educational Assistance rejection placeholder', () {
    testWidgets('Application Rejected panel shows the exact reason, guidance, and an Apply Again button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester, seedDemoData: true);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, 'demo-tulong-educational');

      expect(find.text('Application Rejected'), findsOneWidget);
      // The same reason also appears inline in the request's own status
      // timeline (the Rejected milestone's own remarks — set to match
      // adminRemarks, the same convention rejectDemo() already uses) — the
      // panel itself is what findsWidgets confirms is present at all.
      expect(find.text(_rejectionReason), findsWidgets);
      expect(find.text('What you can do:'), findsOneWidget);
      expect(find.text(_rejectionGuidance), findsOneWidget);
      expect(find.text('Apply Again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Apply Again opens a brand-new Educational Assistance application, old request untouched', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester, seedDemoData: true);
      final session = await _signedInAsVerifiedDemo(tester);
      final original = requests.all.firstWhere((r) => r.id == 'demo-tulong-educational');
      final originalRef = original.referenceNumber;

      await _pumpDetail(tester, requests, session, 'demo-tulong-educational');
      await tester.ensureVisible(find.text('Apply Again'));
      await tester.tap(find.text('Apply Again'));
      await tester.pumpAndSettle();

      // Educational Assistance is sourced/formSpec'd -> the wizard, not the
      // older single-step screen.
      expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
      expect(find.byType(NewRequestScreen), findsNothing);

      // The original rejected request is completely unchanged.
      final stillThere = requests.all.firstWhere((r) => r.id == 'demo-tulong-educational');
      expect(stillThere.status, 'Rejected');
      expect(stillThere.referenceNumber, originalRef);
      expect(stillThere.adminRemarks, _rejectionReason);
    });

    testWidgets('submitting the reapplication creates a new request with its own reference number', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester, seedDemoData: true);

      final before = requests.all.length;

      // Submit directly through the service (same architecture proven by
      // the wizard's own submit flow) — this test's own focus is the
      // history/reference-number guarantee, not re-driving the whole form.
      final reapplied = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        purpose: 'Tuition and allowance support — updated enrollment document attached',
        expectedDays: '10-15 working days',
        attachments: const [],
      );

      expect(requests.all.length, before + 1);
      expect(reapplied.id, isNot('demo-tulong-educational'));
      final original = requests.all.firstWhere((r) => r.id == 'demo-tulong-educational');
      expect(reapplied.referenceNumber, isNot(original.referenceNumber));
      expect(original.status, 'Rejected'); // preserved in history, unchanged
      expect(reapplied.status, 'Submitted');
    });

    testWidgets('Apply Again still respects the Tulong eligibility rule when another application is active', (
      tester,
    ) async {
      final rejected = ServiceRequest(
        id: 'demo-tulong-educational',
        referenceNumber: 'AR-2026-DEMO06',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        purpose: 'Tuition and allowance support',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Rejected',
        statusHistory: [StatusHistoryEntry(status: 'Rejected', at: DateTime(2026, 1, 1), actor: 'Office of the Municipal Mayor Staff', remarks: _rejectionReason)],
        attachments: const [],
        expectedDays: '10-15 working days',
        adminRemarks: _rejectionReason,
        rejectionGuidance: _rejectionGuidance,
      );
      final active = ServiceRequest(
        id: 'req-active-educational',
        referenceNumber: 'AR-2026-0002',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        purpose: 'Tuition and allowance support — reapplied',
        submittedAt: DateTime(2026, 2, 1),
        status: 'Pending Review',
        statusHistory: [StatusHistoryEntry(status: 'Pending Review', at: DateTime(2026, 2, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '10-15 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([rejected.toJson(), active.toJson()]),
      });
      final requests = await _readyRequests(tester, seedDemoData: false);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, 'demo-tulong-educational');
      await tester.ensureVisible(find.text('Apply Again'));
      await tester.tap(find.text('Apply Again'));
      await tester.pumpAndSettle();

      // Blocked by the OTHER, currently-active application for the same
      // assistance — never reaches the wizard.
      expect(find.text('Active Application Exists'), findsOneWidget);
      expect(find.byType(ServiceRequestWizardScreen), findsNothing);
    });
  });

  group('Application Rejected panel gating', () {
    testWidgets('does not show for a Rejected request with no adminRemarks on file', (tester) async {
      final noReason = ServiceRequest(
        id: 'req-no-reason',
        referenceNumber: 'DR-2026-0001',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Certificate of Indigency',
        category: ServiceCategory.dokyu,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Medical Assistance',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Rejected',
        statusHistory: [StatusHistoryEntry(status: 'Rejected', at: DateTime(2026, 1, 1), actor: 'MSWDO Staff')],
        attachments: const [],
        expectedDays: '2-3 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([noReason.toJson()]),
      });
      final requests = await _readyRequests(tester, seedDemoData: false);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, 'req-no-reason');

      expect(find.text('Application Rejected'), findsNothing);
      expect(find.text('Apply Again'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
