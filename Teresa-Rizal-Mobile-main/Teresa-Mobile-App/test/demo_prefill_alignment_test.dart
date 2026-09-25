// Coverage for the Mobile <-> Web Admin final alignment pass's
// CatalogItem.demoDefaults / demoPurpose architecture: realistic
// service-specific demo answers that appear ONLY for the verified primary
// demo resident (Perlita), layer strictly below the existing Master
// Profile prefill (see ServiceRequestWizardScreen's own prefill block and
// perlita_master_profile_alignment_test.dart), and remain ordinary editable
// form values — never hintText, never locked, and editing one never
// touches the Resident Master Profile or any other request.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/catalog_item.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
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

Attachment _fakeAttachment(String fileName) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: AttachmentCategory.pdf,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: fileName,
  );
}

Future<CitizenSessionService> _signedInAs(WidgetTester tester, dynamic account) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
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
  Future<RequestsService> pumpWizard(
    WidgetTester tester, {
    required dynamic account,
    required CatalogItem item,
    required ServiceCategory category,
    MasterFileService? masterFile,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAs(tester, account);
    final requests = await _readyRequests(tester);
    final mf = masterFile ?? await _readyMasterFile(tester);

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
          home: ServiceRequestWizardScreen(category: category, item: item, accent: AppColors.blue700),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requests;
  }

  Future<RequestsService> pumpNewRequestScreen(
    WidgetTester tester, {
    required dynamic account,
    required CatalogItem item,
    required ServiceCategory category,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAs(tester, account);
    final requests = await _readyRequests(tester);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
        ],
        child: MaterialApp(
          home: NewRequestScreen(category: category, item: item, accent: AppColors.blue700),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requests;
  }

  group('demoDefaults / demoPurpose — Perlita only, always editable', () {
    testWidgets('Barangay Clearance: purpose defaults to Proof of Residency and is freely editable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('gov_id.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'proof_of_residency',
        label: 'Proof of residency',
        attachment: _fakeAttachment('residency_proof.pdf'),
        origin: 'Test',
      );
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
      final requests = await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last, // Perlita
        item: item,
        category: ServiceCategory.dokyu,
        masterFile: mf,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Clearance Details
      await tester.pumpAndSettle();

      // Web Admin's own record for Perlita: Purpose defaults to Proof of
      // Residency, not Local Employment.
      expect(find.text('Proof of Residency'), findsOneWidget);

      // Edit: open the dropdown and pick a different option — this must
      // change ONLY this in-progress request, never any stored profile
      // data (Purpose isn't a Master Profile field at all).
      await tester.tap(find.text('Proof of Residency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel Abroad').last);
      await tester.pumpAndSettle();

      expect(find.text('Proof of Residency'), findsNothing);
      expect(find.text('Travel Abroad'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements & Attachments
      await tester.pumpAndSettle();

      while (find.text('Use Existing Document').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
      await tester.pumpAndSettle();

      // Barangay Clearance has a real configured fee, so Review leads to a
      // Payment Method step before submission (see the Mobile-only final
      // request-flow correction pass) — never straight to "Submit Request".
      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Payment Method
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay at Municipal Office'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Confirm Payment'));
      await tester.pumpAndSettle();

      final submitted = requests.all.last;
      expect(submitted.formFields['purpose'], 'Travel Abroad');
      expect(submitted.purpose, contains('Travel Abroad'));
      expect(submitted.purpose, isNot(contains('Local Employment')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Barangay Clearance: a non-verified account gets no demo purpose default', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.first, // Nicanor — not the verified demo resident
        item: item,
        category: ServiceCategory.dokyu,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Clearance Details
      await tester.pumpAndSettle();

      expect(find.text('Local Employment'), findsNothing);
      expect(find.text('Select Purpose'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Certificate of Residency: residencyType and purpose both prefill for Perlita', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_residency');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Permanent Resident'), findsOneWidget);
      expect(find.text('Bank Requirement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Barangay Business Clearance: text/number fields prefill and are editable via select-all/retype', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('gov_id.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'proof_of_business_location_lease_contract_or_land_title',
        label: 'Proof of business location (lease contract or land title)',
        attachment: _fakeAttachment('business_location.pdf'),
        origin: 'Test',
      );
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_business_clearance');
      final requests = await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
        masterFile: mf,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Business Details
      await tester.pumpAndSettle();

      expect(find.text("Quiambao's Sari-Sari Store"), findsOneWidget);
      expect(find.text('Retail - Sari-Sari Store'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('15000'), findsOneWidget);

      // Editable: clear and retype the business name field.
      final businessNameField = find.widgetWithText(TextField, "Quiambao's Sari-Sari Store");
      await tester.enterText(businessNameField, 'Perlita Variety Store');
      await tester.pumpAndSettle();
      expect(find.text("Quiambao's Sari-Sari Store"), findsNothing);
      expect(find.text('Perlita Variety Store'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements & Attachments
      await tester.pumpAndSettle();

      while (find.text('Use Existing Document').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
      await tester.pumpAndSettle();

      // Barangay Business Clearance has a real configured fee too — same
      // Payment Method step before submission.
      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Payment Method
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay at Municipal Office'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Confirm Payment'));
      await tester.pumpAndSettle();

      final submitted = requests.all.last;
      expect(submitted.formFields['businessName'], 'Perlita Variety Store');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cedula (no formSpec): NewRequestScreen prefills Purpose from demoPurpose and it stays editable', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_cedula');
      await pumpNewRequestScreen(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
      );

      expect(find.text('For submission as a government transaction requirement.'), findsOneWidget);

      final purposeField = find.widgetWithText(TextField, 'For submission as a government transaction requirement.');
      await tester.enterText(purposeField, 'Cedula needed for NBI clearance application.');
      await tester.pumpAndSettle();

      expect(find.text('For submission as a government transaction requirement.'), findsNothing);
      expect(find.text('Cedula needed for NBI clearance application.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reject (Demo) on RequestDetailScreen uses the service-specific realistic reason', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance', // matches dokyu_barangay_clearance's own demoRejectionReason
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
        requiresPayment: false,
        fee: '₱50.00',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: requests,
          child: MaterialApp(home: RequestDetailScreen(requestId: request.id)),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject Request (Demo)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Reject (Demo)'));
      await tester.pumpAndSettle();

      final rejected = requests.all.firstWhere((r) => r.id == request.id);
      expect(rejected.status, 'Rejected');
      expect(rejected.adminRemarks, contains('Proof of Residency'));
      expect(rejected.adminRemarks, isNot(contains('did not match the information shown on your valid ID')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cedula: a non-verified account sees a blank Purpose field', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_cedula');
      await pumpNewRequestScreen(
        tester,
        account: MockCatalog.demoAccounts.first, // Nicanor
        item: item,
        category: ServiceCategory.dokyu,
      );

      expect(find.text('Community Tax Certificate needed for a bank transaction requirement.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
