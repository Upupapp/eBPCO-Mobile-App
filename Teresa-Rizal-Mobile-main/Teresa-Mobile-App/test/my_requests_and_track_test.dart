// Coverage for: the new "My Requests" hamburger screen, the Dokyu
// (unlimited) vs Tulong (status-based reapplication) repeat-request rules,
// and the "Track This Request" fix (it must open the exact
// just-submitted request, never a stale/wrong one).
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/my_requests_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/request_submitted_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/utils/tulong_eligibility.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/segmented_tabs.dart';

Future<RequestsService> _loaded(WidgetTester tester, {bool seedDemoData = false}) async {
  SharedPreferences.setMockInitialValues({});
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

const _verifiedDemoId = 'ESP-RES-2024-9002';
const _verifiedDemoName = 'Perlita Quiambao';

Future<ServiceRequest> _submitDokyu(RequestsService requests, {String typeName = 'Barangay Clearance'}) {
  return requests.submit(
    applicantId: _verifiedDemoId,
    applicantName: _verifiedDemoName,
    typeName: typeName,
    category: ServiceCategory.dokyu,
    office: 'Barangay Hall',
    purpose: 'Test purpose',
    expectedDays: '1-2 working days',
    attachments: const [],
  );
}

Future<ServiceRequest> _submitTulong(RequestsService requests, {String typeName = 'Medical Assistance (AICS)'}) {
  return requests.submit(
    applicantId: _verifiedDemoId,
    applicantName: _verifiedDemoName,
    typeName: typeName,
    category: ServiceCategory.tulong,
    office: 'Municipal Social Welfare and Development Office',
    purpose: 'Test purpose',
    expectedDays: '3-5 working days',
    attachments: const [],
  );
}

void main() {
  group('Dokyu repeat-request rule — unlimited', () {
    testWidgets('the same Dokyu service can be requested any number of times, each with its own reference number', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final r1 = await _submitDokyu(requests);
      final r2 = await _submitDokyu(requests);
      final r3 = await _submitDokyu(requests);
      final r4 = await _submitDokyu(requests);

      final refs = {r1.referenceNumber, r2.referenceNumber, r3.referenceNumber, r4.referenceNumber};
      expect(refs.length, 4); // every reference number is unique
      expect(requests.all.where((r) => r.typeName == 'Barangay Clearance').length, 4);
      // Older requests are preserved independently, never overwritten.
      expect(requests.all.any((r) => r.id == r1.id), isTrue);
      expect(requests.all.any((r) => r.id == r2.id), isTrue);
    });
  });

  group('Tulong reapplication rule — status-based, per assistance type', () {
    ServiceRequest tulongRequest({
      required String id,
      required String status,
      String typeName = 'Medical Assistance (AICS)',
      String applicantId = _verifiedDemoId,
    }) {
      return ServiceRequest(
        id: id,
        referenceNumber: 'AR-2026-$id',
        applicantId: applicantId,
        applicantName: _verifiedDemoName,
        typeName: typeName,
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test',
        submittedAt: DateTime(2026, 1, 1),
        status: status,
        statusHistory: [StatusHistoryEntry(status: status, at: DateTime(2026, 1, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
    }

    testWidgets('Case A — no previous application for this assistance is eligible', (tester) async {
      final requests = await _loaded(tester);
      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
      expect(result.blockingRequest, isNull);
    });

    for (final activeStatus in [
      'Submitted',
      'Pending Review',
      'Under Verification',
      'Assigned',
      'Processing',
      'Waiting Requirements',
      'Approved',
    ]) {
      testWidgets('Case B/C — a "$activeStatus" application for this assistance blocks a new one', (tester) async {
        SharedPreferences.setMockInitialValues({
          'teresa_rizal_service_requests': jsonEncode([tulongRequest(id: 'r1', status: activeStatus).toJson()]),
        });
        final requests = RequestsService(seedDemoData: false);
        var attempts = 0;
        while (!requests.loaded) {
          attempts++;
          if (attempts > 100) throw StateError('RequestsService never finished loading.');
          await tester.pump(const Duration(milliseconds: 1));
        }
        final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
        expect(result.isEligible, isFalse);
        expect(result.blockingRequest?.id, 'r1');
      });
    }

    testWidgets('Case C — Completed/Released also block a new application', (tester) async {
      for (final status in ['Ready for Release', 'Released', 'Completed']) {
        SharedPreferences.setMockInitialValues({
          'teresa_rizal_service_requests': jsonEncode([tulongRequest(id: 'r1', status: status).toJson()]),
        });
        final requests = RequestsService(seedDemoData: false);
        var attempts = 0;
        while (!requests.loaded) {
          attempts++;
          if (attempts > 100) throw StateError('RequestsService never finished loading.');
          await tester.pump(const Duration(milliseconds: 1));
        }
        final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
        expect(result.isEligible, isFalse, reason: 'status=$status');
        expect(result.status, TulongEligibility.blockedReceived, reason: 'status=$status');
      }
    });

    testWidgets('Case D — a Rejected application allows reapplying to the same assistance', (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([tulongRequest(id: 'r1', status: 'Rejected').toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);

      // Reapplying creates a brand-new request/reference number and never
      // touches the rejected one, which must remain in history.
      final reapplied = await _submitTulong(requests);
      expect(requests.all.any((r) => r.id == 'r1' && r.status == 'Rejected'), isTrue);
      expect(reapplied.id, isNot('r1'));
    });

    testWidgets('a Cancelled application also allows reapplying', (tester) async {
      final requests = await _loaded(tester);
      final r1 = await _submitTulong(requests);
      await requests.cancel(r1.id);
      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
    });

    testWidgets('the restriction is per assistance type — an active Medical Assistance never blocks Educational Assistance', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([tulongRequest(id: 'r1', status: 'Pending Review').toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)').isEligible, isFalse);
      expect(tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Educational Assistance').isEligible, isTrue);
    });

    testWidgets('eligibility is scoped per resident — another account with an active application is separate', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([
          tulongRequest(id: 'r1', status: 'Pending Review', applicantId: 'ESP-RES-2024-9001').toJson(),
        ]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: 'Medical Assistance (AICS)').isEligible, isTrue);
      expect(
        tulongEligibilityFor(requests, applicantId: 'ESP-RES-2024-9001', typeName: 'Medical Assistance (AICS)').isEligible,
        isFalse,
      );
    });
  });

  group('My Requests screen', () {
    Future<void> pumpMyRequests(WidgetTester tester, RequestsService requests, CitizenSessionService session) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ],
          child: const MaterialApp(home: MyRequestsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows Dokyu + Tulong together under All, and each filter narrows correctly', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsVerifiedDemo(tester);

      await _submitDokyu(requests, typeName: 'Barangay Clearance');
      await _submitTulong(requests, typeName: 'Medical Assistance (AICS)');

      await pumpMyRequests(tester, requests, session);

      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Medical Assistance (AICS)'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(SegmentedTabs), matching: find.text('Dokyu')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Medical Assistance (AICS)'), findsNothing);

      await tester.tap(find.descendant(of: find.byType(SegmentedTabs), matching: find.text('Tulong')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay Clearance'), findsNothing);
      expect(find.text('Medical Assistance (AICS)'), findsOneWidget);
    });

    testWidgets('sorts newest submission first, using deterministic pre-seeded timestamps', (tester) async {
      // Real back-to-back submit() calls can land within the same
      // OS-clock tick on Windows, making DateTime.now()-based ordering
      // flaky — pre-seed two requests with explicit, unambiguous
      // submittedAt values instead of relying on real-time gaps between
      // calls.
      final older = ServiceRequest(
        id: 'req-older',
        referenceNumber: 'DR-2026-0001',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Test',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 1, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '1-2 working days',
      );
      final newer = ServiceRequest(
        id: 'req-newer',
        referenceNumber: 'AR-2026-0001',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test',
        submittedAt: DateTime(2026, 6, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 6, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([older.toJson(), newer.toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpMyRequests(tester, requests, session);

      final firstCardText = tester
          .widgetList<Text>(find.descendant(of: find.byType(ListView), matching: find.byType(Text)))
          .elementAt(1) // index 0 is the category badge; index 1 is the service name
          .data;
      expect(firstCardText, 'Medical Assistance (AICS)'); // the newer (June) request renders first
    });

    testWidgets('tapping a request card opens the existing RequestDetailScreen for that exact request', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final submitted = await _submitDokyu(requests);

      await pumpMyRequests(tester, requests, session);
      await tester.tap(find.text('Barangay Clearance'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, submitted.id);
      expect(find.text(submitted.referenceNumber), findsOneWidget);
    });

    testWidgets('account scoping — Nicanor does not see Perlita\'s requests, and vice versa', (tester) async {
      final requests = await _loaded(tester);
      await _submitDokyu(requests); // Perlita's
      await requests.submit(
        applicantId: 'ESP-RES-2024-9001',
        applicantName: 'Nicanor Sarmiento',
        typeName: 'Certificate of Residency',
        category: ServiceCategory.dokyu,
        office: 'Civil Registrar',
        purpose: 'Test purpose',
        expectedDays: '1-2 working days',
        attachments: const [],
      );

      final pendingDemoSession = CitizenSessionService();
      var attempts = 0;
      while (pendingDemoSession.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await pendingDemoSession.login(MockCatalog.demoAccounts.first); // Nicanor

      await pumpMyRequests(tester, requests, pendingDemoSession);
      expect(find.text('Certificate of Residency'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsNothing); // Perlita's own request never leaks in
    });

    testWidgets('empty state shows when the signed-in resident has no requests yet', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      await pumpMyRequests(tester, requests, session);
      expect(find.text('No requests yet'), findsOneWidget);
    });
  });

  group('Track This Request', () {
    testWidgets(
      'tapping Track This Request opens the exact just-submitted request, not a different/older one, with no navigation error',
      (tester) async {
        final requests = await _loaded(tester);
        final older = await _submitDokyu(requests, typeName: 'Barangay Clearance');
        // A real (not fake-clock) gap — submit()'s id is derived from
        // DateTime.now().microsecondsSinceEpoch, which two back-to-back
        // calls can otherwise collide on.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        final justSubmitted = await _submitDokyu(requests, typeName: 'Certificate of Residency');
        expect(justSubmitted.id, isNot(older.id));

        await tester.pumpWidget(
          ChangeNotifierProvider<RequestsService>.value(
            value: requests,
            child: MaterialApp(
              home: RequestSubmittedScreen(
                referenceNumber: justSubmitted.referenceNumber,
                typeName: justSubmitted.typeName,
                accent: AppColors.brand600,
                requestId: justSubmitted.id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Track This Request'));
        await tester.pumpAndSettle();

        // No "deactivated widget's ancestor" (or any other) exception —
        // this is the exact failure mode the fix removes.
        expect(tester.takeException(), isNull);
        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, justSubmitted.id);
        // The type name is both the page subtitle and the card title.
        expect(find.text('Certificate of Residency'), findsWidgets);
        // Proves it did NOT open the older seeded/other request.
        expect(find.text(older.referenceNumber), findsNothing);
      },
    );
  });

  group('Tulong blocked-application dialog', () {
    // Exercises showTulongBlockedDialog directly — the exact same helper
    // ServiceCatalogScreen (early detection), NewRequestScreen, and
    // ServiceRequestWizardScreen all now call once tulongEligibilityFor
    // reports a block.
    Future<void> pumpGate(
      WidgetTester tester,
      RequestsService requests,
      CitizenSessionService session, {
      required String typeName,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = tulongEligibilityFor(requests, applicantId: _verifiedDemoId, typeName: typeName);
                      if (result.isEligible) return;
                      final viewRequest = await showTulongBlockedDialog(context, result);
                      if (viewRequest && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
                        );
                      }
                    },
                    child: const Text('Attempt Submit'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an active application shows "Active Application Exists" with View Existing Request / Close', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final active = await _submitTulong(requests); // status: Submitted — active

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Active Application Exists'), findsOneWidget);
      expect(find.text('You already have an active application for this assistance.'), findsOneWidget);
      expect(find.text('View Existing Request'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('View Existing Request'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, active.id);
    });

    testWidgets('an already-received assistance shows "Assistance Already Received" with View Previous Request / Close', (
      tester,
    ) async {
      final approved = ServiceRequest(
        id: 'req-approved',
        referenceNumber: 'AR-2026-0001',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Approved',
        statusHistory: [StatusHistoryEntry(status: 'Approved', at: DateTime(2026, 1, 1), actor: 'MSWDO Staff')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([approved.toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Assistance Already Received'), findsOneWidget);
      expect(
        find.text(
          'You have already received this assistance and cannot submit another application for the same '
          'assistance at this time.',
        ),
        findsOneWidget,
      );
      expect(find.text('View Previous Request'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Assistance Already Received'), findsNothing);
      expect(find.byType(RequestDetailScreen), findsNothing);
    });

    testWidgets('does not gate a rejected-only history — Attempt Submit proceeds with no dialog', (tester) async {
      final rejected = ServiceRequest(
        id: 'req-rejected',
        referenceNumber: 'AR-2026-0002',
        applicantId: _verifiedDemoId,
        applicantName: _verifiedDemoName,
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Rejected',
        statusHistory: [StatusHistoryEntry(status: 'Rejected', at: DateTime(2026, 1, 1), actor: 'MSWDO Staff')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([rejected.toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Active Application Exists'), findsNothing);
      expect(find.text('Assistance Already Received'), findsNothing);
    });
  });
}
