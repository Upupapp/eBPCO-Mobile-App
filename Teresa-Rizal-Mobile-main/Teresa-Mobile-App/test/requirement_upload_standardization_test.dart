// Coverage for the Dokyu + Tulong requirement-upload standardization pass:
// every requirement gets its own per-requirement upload card (never one
// generic bucket) on BOTH the formSpec-driven wizard (ServiceRequestWizardScreen)
// and the older single-step screen (NewRequestScreen), a staff/office
// process requirement is shown without an upload control, and the full
// submit -> reference number -> Track This Request -> exact request detail
// flow keeps working with requirement-to-attachment mapping intact.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
import 'package:teresa_rizal/screens/shared/receipt_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';

Attachment _fakeAttachment(String fileName) => Attachment(
  id: 'att-$fileName',
  fileName: fileName,
  category: AttachmentCategory.pdf,
  sizeBytes: 12345,
  bytes: Uint8List(0),
  addedAt: DateTime(2026, 1, 1),
  documentTypeLabel: fileName,
);

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

Future<RequestsService> _readyRequests(WidgetTester tester) async {
  final requests = RequestsService(seedDemoData: false);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<MasterFileService> _readyMasterFile(WidgetTester tester) async {
  final mf = MasterFileService();
  var attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return mf;
}

void main() {
  group('Staff/office process requirements never get an upload control', () {
    testWidgets(
      'Certificate of Indigency (Dokyu, wizard): the MSWDO interview line has no upload button, the other two do',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        final session = await _signedInAsVerifiedDemo(tester);
        final requests = await _readyRequests(tester);
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_indigency');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CitizenSessionService>.value(value: session),
              ChangeNotifierProvider<RequestsService>.value(value: requests),
              ChangeNotifierProvider(create: (_) => ResidentProfileService()),
              ChangeNotifierProvider<MasterFileService>.value(value: mf),
              ChangeNotifierProvider(create: (_) => NotificationsService()),
            ],
            child: MaterialApp(
              home: ServiceRequestWizardScreen(category: ServiceCategory.dokyu, item: item, accent: AppColors.brand600),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Applicant Info -> Indigency Details -> Requirements.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        // Purpose is a required select on this step, already prefilled for
        // the verified demo resident (Perlita) via CatalogItem.demoDefaults
        // — this test's own focus is the Requirements step, not this
        // unrelated field, so it's left as-is rather than re-picked.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        expect(find.text('One (1) valid government-issued ID'), findsOneWidget);
        expect(find.text('Barangay Certification of Indigency'), findsOneWidget);
        expect(
          find.text('Brief interview / case assessment with the Municipal Social Welfare and Development Office'),
          findsOneWidget,
        );
        // Only the two genuine documents get an upload button.
        expect(find.text('Upload One (1) valid government-issued ID'), findsOneWidget);
        expect(find.text('Upload Barangay Certification of Indigency'), findsOneWidget);
        expect(
          find.text('Upload Brief interview / case assessment with the Municipal Social Welfare and Development Office'),
          findsNothing,
        );
        // The staff-process note is shown instead.
        expect(find.text('Handled by our staff during processing — no document to upload here.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Financial Assistance (AICS) (Tulong, single-step screen): the MSWDO case-study line has no upload button',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        final session = await _signedInAsVerifiedDemo(tester);
        final requests = await _readyRequests(tester);
        final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_financial');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CitizenSessionService>.value(value: session),
              ChangeNotifierProvider<RequestsService>.value(value: requests),
              ChangeNotifierProvider(create: (_) => ResidentProfileService()),
              ChangeNotifierProvider<MasterFileService>.value(value: mf),
              ChangeNotifierProvider(create: (_) => NotificationsService()),
            ],
            child: MaterialApp(
              home: NewRequestScreen(category: ServiceCategory.tulong, item: item, accent: AppColors.purple700),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('One (1) valid government-issued ID'), findsOneWidget);
        expect(find.text('Barangay Certificate of Indigency'), findsOneWidget);
        expect(
          find.text('Brief interview / social case study with the Municipal Social Welfare and Development Office'),
          findsOneWidget,
        );
        expect(find.text('Upload One (1) valid government-issued ID'), findsOneWidget);
        expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
        expect(
          find.text('Upload Brief interview / social case study with the Municipal Social Welfare and Development Office'),
          findsNothing,
        );
        expect(find.text('Handled by our staff during processing — no document to upload here.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Dokyu end-to-end: Barangay Clearance (item-by-item attach -> submit -> Track This Request)', () {
    testWidgets(
      'attaching ID only leaves Proof of Residency missing; attaching both completes; submit preserves per-requirement mapping; Track This Request opens the exact new request',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        // Seed both matching Master File documents up front so the test can
        // drive real "Use Existing Document" taps instead of the
        // unavailable real image/file picker — same technique already
        // established in dokyu_requirement_uploads_test.dart.
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'valid_government_id',
          label: 'One (1) valid government-issued ID',
          attachment: _fakeAttachment('valid_id.pdf'),
          origin: 'Dokyu',
          serviceName: 'Barangay Clearance',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'proof_of_residency',
          label: 'Proof of residency',
          attachment: _fakeAttachment('residency_proof.pdf'),
          origin: 'Dokyu',
          serviceName: 'Barangay Clearance',
        );

        final session = await _signedInAsVerifiedDemo(tester);
        final requests = await _readyRequests(tester);
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CitizenSessionService>.value(value: session),
              ChangeNotifierProvider<RequestsService>.value(value: requests),
              ChangeNotifierProvider(create: (_) => ResidentProfileService()),
              ChangeNotifierProvider<MasterFileService>.value(value: mf),
              ChangeNotifierProvider(create: (_) => NotificationsService()),
            ],
            child: MaterialApp(
              home: ServiceRequestWizardScreen(category: ServiceCategory.dokyu, item: item, accent: AppColors.brand600),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Applicant Info -> Continue.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        // Clearance Details: Date of Birth already prefilled from her
        // Resident Profile; Purpose is already prefilled too (Perlita's own
        // demoDefaults default to Proof of Residency, matching Web Admin's
        // own submitted request for her) — swap it for a different option
        // to prove it's still a normal editable value.
        await tester.tap(find.text('Proof of Residency'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Local Employment').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Requirements step — both show "Existing document found" offers.
        expect(find.text('Existing document found'), findsNWidgets(2));

        // Attach the ID only.
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Employment requirement');
        // Continue is blocked by the still-missing second requirement —
        // this stays on the Requirements step (never actually leaves it),
        // so this checks the exact missing-requirement message, not a
        // generic "attach at least one" one.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Please attach your Proof of residency.'), findsOneWidget);
        expect(find.text('Existing document found'), findsOneWidget); // only the remaining one

        // Now attach the second requirement too — still on the same step.
        await tester.ensureVisible(find.text('Use Existing Document'));
        await tester.tap(find.text('Use Existing Document'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
        await tester.pumpAndSettle();

        // Barangay Clearance has a real configured fee, so Review leads to
        // a Payment Method step before submission (see the Mobile-only
        // final request-flow correction pass).
        await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Payment Method
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pay at Municipal Office'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Confirm Payment'));
        await tester.pumpAndSettle();

        // Every Dokyu request now lands on the receipt screen first (a
        // receipt is generated at submission time, paid or free — see
        // RequestsService.submit), not the older generic Request Submitted
        // screen.
        expect(find.byType(ReceiptScreen), findsOneWidget);
        final submitted = requests.all.single;
        expect(submitted.typeName, 'Barangay Clearance');
        expect(submitted.attachments.length, 2);
        // Requirement-to-attachment mapping survives submission — each
        // attachment still carries which requirement it satisfied.
        expect(
          submitted.attachments.map((a) => a.documentTypeLabel).toSet(),
          {'One (1) valid government-issued ID', 'Proof of residency'},
        );

        // "Done" navigates straight to the exact newly created request's
        // own tracker — reusing the existing Request Detail/Track Request
        // screen, never a duplicate system.
        await tester.tap(find.widgetWithText(AppButton, 'Done'));
        await tester.pumpAndSettle();

        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Tulong services without a formSpec also use per-requirement uploaders now', () {
    testWidgets('Medical Assistance (AICS) shows 4 separate uploaders, never the old flat picker', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final requests = await _readyRequests(tester);
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_medical');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider<MasterFileService>.value(value: mf),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(
            home: NewRequestScreen(category: ServiceCategory.tulong, item: item, accent: AppColors.purple700),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in [
        'One (1) valid government-issued ID',
        "Medical Abstract or Doctor's prescription",
        'Hospital bill or Statement of Account',
        'Barangay Certificate of Indigency',
      ]) {
        expect(find.text(label), findsOneWidget);
        expect(find.text('Upload $label'), findsOneWidget);
      }
      expect(find.text('Add photo or document'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
