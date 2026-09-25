// Verifies the new Certified Copy of Marriage Certificate Dokyu service: it
// appears in the catalog under Office of the Municipal Civil Registrar right next to the
// pre-existing Application for Marriage License item, opens the
// data-driven wizard with the right (lean, lookup-only) step count, and a
// full fill-through run reaches the same request-submission gate every
// other Dokyu service uses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

Future<void> _pumpMarriageCopyWizard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_marriage_certificate_copy');
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
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
}

void main() {
  test('shares an office with Application for Marriage License in the catalog data', () {
    final license = MockCatalog.documentTypes.firstWhere((i) => i.name == 'Application for Marriage License');
    final copy = MockCatalog.documentTypes.firstWhere((i) => i.name == 'Certified Copy of Marriage Certificate');
    expect(copy.office, license.office);
  });

  testWidgets('opens a lean, lookup-only wizard — not the full certificate as a form', (tester) async {
    await _pumpMarriageCopyWizard(tester);

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    // Applicant Info -> Marriage Record Information -> Requirements ->
    // Review -> Payment (this service has a real ₱155.00 fee — see the
    // Mobile-only final request-flow correction pass) = 5 steps, not a
    // giant multi-step replica of the certificate's full
    // Husband/Wife/parents/witnesses/registrar layout.
    expect(find.text('Step 1 of 5'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Marriage Record Information'), findsWidgets);
    expect(find.text("Husband's Full Name"), findsOneWidget);
    expect(find.text("Wife's Full Name"), findsOneWidget);
    expect(find.text('Date of Marriage'), findsOneWidget);
    expect(find.text('Place of Marriage'), findsOneWidget);
    expect(find.text('Registry Number'), findsOneWidget);
    expect(find.text('Number of Copies'), findsOneWidget);
    // None of the certificate's own admin/official fields ever appear.
    expect(find.textContaining('Solemnizing'), findsNothing);
    expect(find.textContaining('Civil Registrar'), findsNothing);
    expect(find.textContaining('Witness'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo prefill (Perlita), editability, and full fill-through to the attachment gate', (tester) async {
    await _pumpMarriageCopyWizard(tester);

    await tester.tap(find.text('Continue')); // Applicant Info (prefilled) -> Marriage Record Information
    await tester.pumpAndSettle();

    // All 4 required fields are already prefilled for Perlita (see
    // CatalogItem.demoDefaults on dokyu_marriage_certificate_copy) — no
    // "Please complete" block on a fresh Continue, unlike before this
    // service had demo prefill. Reframed as a request for her PARENTS'
    // marriage certificate (she's Single, so "her own marriage" would be
    // inconsistent) — Anselmo & Lourdes Quiambao, married before her birth.
    expect(find.text('Anselmo Quiambao'), findsOneWidget);
    expect(find.text('Lourdes Quiambao'), findsOneWidget);
    expect(find.text('May 10, 1999'), findsOneWidget); // dateOfMarriage, parsed from the ISO demoDefault
    expect(find.text('Teresa, Rizal'), findsOneWidget);

    // Still a normal editable value, not locked — change the date through
    // the real date picker (switched to keyboard-entry for a
    // deterministic result).
    await tester.tap(find.text('May 10, 1999'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '06/12/2010');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('May 10, 1999'), findsNothing);
    expect(find.text('Jun 12, 2010'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Requirements & Attachments — Purpose is already prefilled too
    // (demoPurpose); attachments are still left for the resident to
    // upload live, so Dokyu's per-requirement gate still applies.
    expect(find.textContaining('Requirements'), findsWidgets);
    expect(find.textContaining('For submission as proof of civil status'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please attach'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
