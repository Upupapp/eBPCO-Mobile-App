// Coverage for the "detect it early" requirement: a resident must never be
// able to fill out an entire Tulong application only to discover at Submit
// that they're not eligible to reapply for that assistance. ServiceCatalogScreen
// checks tulongEligibilityFor before ever pushing the request screen — see
// its own _ItemList._open. A blocked assistance never reaches
// NewRequestScreen/ServiceRequestWizardScreen; a different, eligible
// assistance is completely unaffected.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';
const _verifiedDemoName = 'Perlita Quiambao';

Future<void> _pumpTulongCatalog(WidgetTester tester, {required List<Map<String, dynamic>> seededRequests}) async {
  SharedPreferences.setMockInitialValues({
    if (seededRequests.isNotEmpty) 'teresa_rizal_service_requests': jsonEncode(seededRequests),
  });
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified

  final requests = RequestsService(seedDemoData: false);
  attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(
        home: ServiceCatalogScreen(
          category: ServiceCategory.tulong,
          title: 'Tulong',
          catalog: MockCatalog.assistanceTypes,
          accent: AppColors.purple700,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _activeMedicalAssistance() => ServiceRequest(
      id: 'req-active-medical',
      referenceNumber: 'AR-2026-0001',
      applicantId: _verifiedDemoId,
      applicantName: _verifiedDemoName,
      typeName: 'Medical Assistance (AICS)',
      category: ServiceCategory.tulong,
      office: 'Municipal Social Welfare and Development Office',
      purpose: 'Hospital bill',
      submittedAt: DateTime(2026, 1, 1),
      status: 'Pending Review',
      statusHistory: [StatusHistoryEntry(status: 'Pending Review', at: DateTime(2026, 1, 1), actor: 'Citizen')],
      attachments: const [],
      expectedDays: '3-5 working days',
    ).toJson();

void main() {
  testWidgets('an assistance with an active application is blocked at the catalog screen, before any form opens', (
    tester,
  ) async {
    await _pumpTulongCatalog(tester, seededRequests: [_activeMedicalAssistance()]);

    await tester.tap(find.text('Municipal Social Welfare and Development Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medical Assistance (AICS)'));
    await tester.pumpAndSettle();

    expect(find.text('Active Application Exists'), findsOneWidget);
    expect(find.text('You already have an active application for this assistance.'), findsOneWidget);
    // Neither request screen was ever reached.
    expect(find.byType(NewRequestScreen), findsNothing);
    expect(find.byType(ServiceRequestWizardScreen), findsNothing);

    await tester.tap(find.text('View Existing Request'));
    await tester.pumpAndSettle();
    expect(find.byType(RequestDetailScreen), findsOneWidget);
    expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, 'req-active-medical');
  });

  testWidgets('a different, eligible assistance still opens normally while another is blocked', (tester) async {
    await _pumpTulongCatalog(tester, seededRequests: [_activeMedicalAssistance()]);

    // Educational Assistance is sourced/formSpec'd -> opens the wizard, and
    // has no prior application of its own at all — fully unaffected by
    // Medical Assistance's active block.
    await tester.tap(find.text('Office of the Municipal Mayor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Educational Assistance'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    expect(find.text('Active Application Exists'), findsNothing);
    expect(find.text('Assistance Already Received'), findsNothing);
  });

  testWidgets('with no prior requests at all, a Tulong item opens immediately with no dialog', (tester) async {
    await _pumpTulongCatalog(tester, seededRequests: const []);

    await tester.tap(find.text('Municipal Social Welfare and Development Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medical Assistance (AICS)'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRequestScreen), findsOneWidget);
    expect(find.text('Active Application Exists'), findsNothing);
  });
}
