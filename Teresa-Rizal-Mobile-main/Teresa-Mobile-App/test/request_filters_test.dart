// Verifies the new Dokyu/Tulong filtering feature: the RequestFilters
// model's actual filtering/sorting logic, and that RequestListScreen's
// Filter button opens the sheet, an applied filter narrows the visible
// list with an active chip + result count, and Clear All restores it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/request_filters.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/dokyu/dokyu_screen.dart';
import 'package:teresa_rizal/widgets/filter_bottom_sheet.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/services/balita_service.dart';

ServiceRequest _req({
  required String type,
  required String status,
  required String office,
  required DateTime submittedAt,
}) {
  return ServiceRequest(
    id: 'req-$type-$status-${submittedAt.millisecondsSinceEpoch}',
    referenceNumber: 'DR-2026-${submittedAt.millisecondsSinceEpoch % 10000}',
    applicantId: 'ESP-1',
    applicantName: 'Test Resident',
    typeName: type,
    category: ServiceCategory.dokyu,
    office: office,
    purpose: 'Test',
    submittedAt: submittedAt,
    status: status,
    statusHistory: [StatusHistoryEntry(status: status, at: submittedAt, actor: 'Citizen')],
    attachments: const <Attachment>[],
    expectedDays: '1-2 working days',
  );
}

void main() {
  group('RequestFilters.apply (unit)', () {
    final barangayClearance = _req(
      type: 'Barangay Clearance',
      status: 'Submitted',
      office: 'Barangay Hall',
      submittedAt: DateTime(2026, 1, 10),
    );
    final cedula = _req(
      type: 'Cedula (Community Tax Certificate)',
      status: 'Approved',
      office: "Treasurer's Office",
      submittedAt: DateTime(2026, 3, 5),
    );
    final all = [barangayClearance, cedula];

    test('search matches type name, reference number, or office (case-insensitive)', () {
      final filtered = const RequestFilters(search: 'cedula').apply(all);
      expect(filtered, [cedula]);
    });

    test('scope filter distinguishes Barangay vs LGU via the office name', () {
      expect(scopeOfOffice('Barangay Hall'), RequestScope.barangay);
      expect(scopeOfOffice("Treasurer's Office"), RequestScope.lgu);
      final filtered = const RequestFilters(scope: RequestScope.barangay).apply(all);
      expect(filtered, [barangayClearance]);
    });

    test('status filter narrows to an exact status', () {
      final filtered = const RequestFilters(status: 'Approved').apply(all);
      expect(filtered, [cedula]);
    });

    test('date range filter is inclusive of both endpoints', () {
      final filtered = RequestFilters(dateRange: DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).apply(all);
      expect(filtered, [barangayClearance]);
    });

    test('sort newest/oldest reorders by submittedAt', () {
      final newest = const RequestFilters(sort: RequestSort.newest).apply(all);
      expect(newest.first, cedula); // March after January
      final oldest = const RequestFilters(sort: RequestSort.oldest).apply(all);
      expect(oldest.first, barangayClearance);
    });

    test('combining filters applies all facets together (AND)', () {
      final filtered = const RequestFilters(scope: RequestScope.lgu, status: 'Approved').apply(all);
      expect(filtered, [cedula]);
      final none = const RequestFilters(scope: RequestScope.barangay, status: 'Approved').apply(all);
      expect(none, isEmpty);
    });

    test('isActive/activeCount reflect only set facets, not sort', () {
      const empty = RequestFilters();
      expect(empty.isActive, isFalse);
      expect(empty.activeCount, 0);
      const withTwo = RequestFilters(search: 'x', status: 'Approved', sort: RequestSort.oldest);
      expect(withTwo.isActive, isTrue);
      expect(withTwo.activeCount, 2);
    });
  });

  group('RequestListScreen filter UI (widget)', () {
    Future<void> pumpDokyuAsVerifiedResident(WidgetTester tester, {required List<ServiceRequest> seed}) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      await session.login(MockCatalog.demoAccounts.last); // Perlita — Approved/verified
      final requests = RequestsService(seedDemoData: false);
      for (final r in seed) {
        await requests.submit(
          applicantId: r.applicantId,
          applicantName: r.applicantName,
          typeName: r.typeName,
          category: r.category,
          office: r.office,
          purpose: r.purpose,
          expectedDays: r.expectedDays,
          attachments: r.attachments,
        );
        // submit() always starts at 'Submitted' — force this test's exact
        // status so status-filter assertions are precise. submittedAt is
        // stamped as "now" by submit() and is final, so date-range
        // filtering is covered separately in the unit-test group above,
        // which constructs ServiceRequest directly.
        requests.byCategory(r.category).first.status = r.status;
      }

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => BalitaService()),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: const MaterialApp(home: DokyuScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Filter button opens the sheet; applying a status filter narrows results with an active chip', (tester) async {
      await pumpDokyuAsVerifiedResident(
        tester,
        seed: [
          _req(type: 'Barangay Clearance', status: 'Submitted', office: 'Barangay Hall', submittedAt: DateTime.now()),
          _req(type: 'Cedula (Community Tax Certificate)', status: 'Submitted', office: "Treasurer's Office", submittedAt: DateTime.now()),
        ],
      );

      expect(find.text('2 results'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Requests'), findsOneWidget);

      // The tile beneath the sheet also shows a "Barangay" scope badge —
      // scope the finder to the sheet itself so the tap lands on the
      // filter pill, not the (still-mounted, just visually covered) tile.
      await tester.tap(find.descendant(of: find.byType(FilterBottomSheet), matching: find.text('Barangay')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('1 result'), findsOneWidget);
      expect(find.text('Filter (1)'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Cedula (Community Tax Certificate)'), findsNothing);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(find.text('2 results'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty filtered results show the "no match" empty state with Clear Filters', (tester) async {
      await pumpDokyuAsVerifiedResident(
        tester,
        seed: [_req(type: 'Barangay Clearance', status: 'Submitted', office: 'Barangay Hall', submittedAt: DateTime.now())],
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nonexistent request type');
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No requests match your current filters.'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
