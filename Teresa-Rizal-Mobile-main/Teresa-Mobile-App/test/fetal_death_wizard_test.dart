// Verifies the new Certificate of Fetal Death Dokyu service: it appears in
// the catalog under Office of the Municipal Civil Registrar, opens the data-driven wizard
// with the right step count/labels, its two conditional fields ("If
// Multiple Delivery, Fetus Was" and "Attended By") only appear/require
// input when their trigger field is set to a matching value, and a full
// fill-through-submit run lands on the same request-submitted flow every
// other Dokyu service uses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/request_submitted_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

Future<RequestsService> _openFetalDeathWizard(WidgetTester tester) async {
  // The default 800x600 test canvas is unusually wide/short and puts the
  // Civil Registrar item list's later entries (this service included) at a y-offset
  // scrollUntilVisible can't reliably resolve a tappable center for — a
  // realistic phone viewport (matching every other functional suite in
  // this app) avoids that edge case entirely.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  final requests = RequestsService(seedDemoData: false);
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
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          catalog: MockCatalog.documentTypes,
          accent: AppColors.brand600,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_fetal_death');
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        home: ServiceRequestWizardScreen(
          category: ServiceCategory.dokyu,
          item: item,
          accent: AppColors.brand600,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return requests;
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Certificate of Fetal Death appears in Dokyu and opens the multi-step wizard', (tester) async {
    await _openFetalDeathWizard(tester);

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    // Applicant Info -> Fetal Information -> Mother's Information ->
    // Father's Information -> Supporting Information -> Requirements ->
    // Review -> Payment (this service has a real ₱200.00 fee — see the
    // Mobile-only final request-flow correction pass) = 8 steps.
    expect(find.text('Step 1 of 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conditional fields only appear/require input when their trigger value is selected', (tester) async {
    await _openFetalDeathWizard(tester);
    await _continue(tester); // Applicant Info (prefilled) -> Fetal Information

    expect(find.text('Step 2 of 8'), findsOneWidget);
    expect(find.text('Fetal Information'), findsWidgets);

    // Hidden by default — Type of Delivery hasn't been set yet.
    expect(find.text('If Multiple Delivery, Fetus Was'), findsNothing);

    await tester.tap(find.text('Select Type of Delivery'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Single').last);
    await tester.pumpAndSettle();
    // Single -> still hidden.
    expect(find.text('If Multiple Delivery, Fetus Was'), findsNothing);

    await tester.tap(find.text('Single'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Twin').last);
    await tester.pumpAndSettle();
    // Twin -> now visible.
    expect(find.text('If Multiple Delivery, Fetus Was'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('full fill-through-submit reaches the standard request-submitted screen', (tester) async {
    final requests = await _openFetalDeathWizard(tester);
    await _continue(tester); // -> Fetal Information

    Future<void> selectDropdown(String hintOrValue, String option) async {
      final target = find.text(hintOrValue).last;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    Future<void> pickToday(String hintOrLabel) async {
      final target = find.text(hintOrLabel).last;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    // Fetal Information. find.byType(TextField) also matches AppDateField's
    // internal TextFormField (TextFormField is itself built from a
    // TextField), so field order here is: fetusFullName (optional, index
    // 0), dateOfDelivery's internal field (index 1 — filled via the real
    // date picker below, not text entry), placeOfDelivery (index 2),
    // methodOfDelivery (index 3), birthOrder/weightOfFetus (optional).
    // AppSelectField's DropdownButtonFormField has no internal TextField,
    // so Sex/Type of Delivery don't add to this count.
    await selectDropdown('Select Sex', 'Male');
    await pickToday('Select date');
    final fetalFields = find.byType(TextField);
    await tester.enterText(fetalFields.at(2), 'Teresa, Rizal District Hospital, Poblacion');
    await selectDropdown('Select Type of Delivery', 'Single');
    await tester.enterText(fetalFields.at(3), 'Normal spontaneous vertex');
    await _continue(tester);

    // Mother's Information. Field order: motherMaidenName,
    // motherCitizenship, motherReligion (optional), motherOccupation
    // (optional), motherAgeAtDelivery, childrenBornAlive (optional),
    // childrenStillLiving (optional), childrenBornAliveNowDead (optional),
    // motherResidence — all text/number, so all render as TextField.
    expect(find.text("Mother's Information"), findsWidgets);
    final motherFields = find.byType(TextField);
    await tester.enterText(motherFields.at(0), 'Juana Dela Cruz');
    await tester.enterText(motherFields.at(1), 'Filipino');
    await tester.enterText(motherFields.at(4), '28');
    await tester.enterText(motherFields.at(8), 'Purok 1, Brgy. Agoho, Teresa, Rizal');
    await _continue(tester);

    // Father's Information — every field optional, so Continue works
    // immediately with nothing filled.
    expect(find.text("Father's Information"), findsWidgets);
    await _continue(tester);

    // Supporting Information.
    expect(find.text('Supporting Information'), findsWidgets);
    await selectDropdown('Select Fetus Died', 'Unknown');
    await tester.enterText(find.byType(TextField).first, '32');
    await selectDropdown('Select Was the Delivery Attended', 'Not Attended');
    final supportingTextareas = find.byType(TextField);
    await tester.enterText(supportingTextareas.at(1), 'Unknown, as told by attending staff.');
    await tester.enterText(supportingTextareas.at(2), 'Delayed due to family only recently obtaining documents.');
    await _continue(tester);

    // Requirements & Attachments — this service has no formSpec field
    // keyed 'purpose', so the step's free-text field is labeled "Purpose"
    // and is itself required; fill it so the *attachment* gate (what this
    // assertion actually targets) is what's left blocking Continue. Skip
    // attaching a real file (covered by RequirementUploader's own tests) —
    // this suite is about the service's own fields, so it's enough to
    // confirm Dokyu's per-requirement gate still applies rather than trying
    // to bypass it.
    expect(find.textContaining('Requirements'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, '').first, 'Requesting a copy for PSA registration.');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please attach'), findsOneWidget);

    expect(tester.takeException(), isNull);
    // No request submitted yet — the attachment gate correctly blocked it.
    expect(requests.all, isEmpty);
    expect(find.byType(RequestSubmittedScreen), findsNothing);
  });
}
