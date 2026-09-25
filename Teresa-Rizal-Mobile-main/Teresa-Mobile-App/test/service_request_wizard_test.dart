// Verifies the new "Sir Paul's Required Form Experience" wizard
// (ServiceRequestWizardScreen): step labels/count adapt per the sourced
// service (see docs/DOKYU_TULONG_FORM_AUDIT.md), Applicant Info is
// prefilled from the signed-in account, required service-specific fields
// block Continue until filled, and items without a sourced formSpec keep
// using the older single-step NewRequestScreen instead of being forced
// into the new wizard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/onboarding_step_indicator.dart';

Future<void> _pumpDokyuAsVerifiedDemo(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
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
}

void main() {
  testWidgets('a sourced item (Barangay Clearance) opens the multi-step wizard, prefilled and step-adaptive', (tester) async {
    await _pumpDokyuAsVerifiedDemo(tester);

    await tester.tap(find.text('Barangay clearance'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    expect(find.byType(NewRequestScreen), findsNothing);

    // Step count/labels are data-driven from this item's formSpec: Applicant
    // Info -> Clearance Details -> Requirements -> Review -> Payment (this
    // service has a real ₱50.00 fee — see the Mobile-only final request-
    // flow correction pass) = 5 steps, not the fixed 6-step Registration
    // template.
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Applicant Info'), findsWidgets);

    // Applicant Info is prefilled from the signed-in account (Perlita Quiambao).
    expect(find.widgetWithText(TextField, 'Perlita Quiambao'), findsOneWidget);
    expect(find.text('Bagumbayan'), findsOneWidget); // her barangay, prefilled into the select

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Clearance Details (sourced from BRGY.CLEARANCE NEW.docx) —
    // the global birthdate/age rule means there is no manual numeric Age
    // field here at all: only a Date of Birth picker plus a read-only,
    // auto-computed Age display. Perlita' Date of Birth already exists in
    // her Resident Profile, so it's prefilled rather than asking her to
    // re-enter it, and Age is computed from it immediately.
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Clearance Details'), findsWidgets);
    expect(find.text('Mar 15, 2001'), findsOneWidget); // her prefilled birthdate
    expect(find.textContaining('years old'), findsOneWidget);
    expect(find.text('Select your Date of Birth above first'), findsNothing);

    // Purpose is already prefilled for the verified demo resident (Perlita)
    // via CatalogItem.demoDefaults — see the Mobile <-> Web Admin final
    // alignment pass — so Continue is not blocked here at all; Date of
    // Birth was never a separately validated field either.
    expect(find.text('Proof of Residency'), findsOneWidget);
    expect(find.text('Select Purpose'), findsNothing);

    // Changing the Date of Birth through the real date picker (switched to
    // keyboard-entry mode for a deterministic result) immediately
    // recalculates Age — there is no separate "Edit Age" anywhere.
    await tester.tap(find.text('Mar 15, 2001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '12/20/2000');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Mar 15, 2001'), findsNothing);
    expect(find.text('Dec 20, 2000'), findsOneWidget);
    expect(find.textContaining('years old'), findsOneWidget);

    // The prefilled Purpose is a normal editable value, not a locked
    // default — change it via the select dropdown.
    await tester.tap(find.text('Proof of Residency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local Employment').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: Requirements & Attachments — Dokyu's own per-requirement
    // uploaders, one per this item's own requirements (no attachment yet
    // for either), so Continue must identify exactly what's missing rather
    // than a generic "attach at least one" message.
    expect(find.text('Step 3 of 5'), findsOneWidget);
    expect(find.text('One (1) valid government-issued ID'), findsOneWidget);
    expect(find.text('Proof of residency'), findsOneWidget);
    // Requirement-specific button label, not a generic "Upload Document".
    expect(find.text('Upload One (1) valid government-issued ID'), findsOneWidget);
    expect(find.text('Upload Proof of residency'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Please attach: One (1) valid government-issued ID, Proof of residency.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an item with no sourced formSpec (Cedula) still uses the older single-step request screen', (tester) async {
    await _pumpDokyuAsVerifiedDemo(tester);

    await tester.tap(find.text('Cedula (CTC)'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRequestScreen), findsOneWidget);
    expect(find.byType(ServiceRequestWizardScreen), findsNothing);
    expect(find.byType(OnboardingStepIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
