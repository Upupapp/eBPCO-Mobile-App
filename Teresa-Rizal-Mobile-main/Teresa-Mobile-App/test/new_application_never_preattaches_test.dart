// Correction pass: "PREFILLED FORM DATA = YES, PRE-UPLOADED REQUIREMENT
// FILES = NO." A brand-new Dokyu/Tulong application must never open with a
// requirement already showing as Uploaded — not even when Perlita's Master
// File already has a matching document (that must only ever be OFFERED via
// "Existing document found" / "Use Existing Document", never auto-selected).
// Audits both entry points (the multi-step ServiceRequestWizardScreen and
// the single-step NewRequestScreen), both modules (Dokyu/Tulong), and
// confirms an already-submitted request's real historical attachments are
// completely unaffected.
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

Future<RequestsService> _readyRequests(WidgetTester tester, {bool seedDemoData = false}) async {
  final requests = RequestsService(seedDemoData: seedDemoData);
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
  Future<void> pumpWizard(
    WidgetTester tester, {
    required CatalogItem item,
    required ServiceCategory category,
    required MasterFileService masterFile,
    required RequestsService requests,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAsVerifiedDemo(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(
          home: ServiceRequestWizardScreen(category: category, item: item, accent: AppColors.brand600),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSinglePage(
    WidgetTester tester, {
    required CatalogItem item,
    required ServiceCategory category,
    required MasterFileService masterFile,
    required RequestsService requests,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAsVerifiedDemo(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
        ],
        child: MaterialApp(
          home: NewRequestScreen(category: category, item: item, accent: AppColors.brand600),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('New application: requirements always start unattached (wizard forms)', () {
    testWidgets('Barangay Clearance — no Master File data at all: both requirements show Upload buttons only', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      final requests = await _readyRequests(tester);
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
      await pumpWizard(tester, item: item, category: ServiceCategory.dokyu, masterFile: mf, requests: requests);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Clearance Details
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements
      await tester.pumpAndSettle();

      expect(find.text('Upload One (1) valid government-issued ID'), findsOneWidget);
      expect(find.text('Upload Proof of residency'), findsOneWidget);
      expect(find.text('Existing document found'), findsNothing);
      expect(find.textContaining('Uploaded'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Barangay Clearance — Perlita already HAS a matching Master File document for both requirements: still offered, never auto-attached',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'valid_government_id',
          label: 'One (1) valid government-issued ID',
          attachment: _fakeAttachment('valid_id_from_earlier_service.pdf'),
          origin: 'Personal Information',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'proof_of_residency',
          label: 'Proof of residency',
          attachment: _fakeAttachment('residency_from_earlier_service.pdf'),
          origin: 'Personal Information',
        );
        final requests = await _readyRequests(tester);
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
        await pumpWizard(tester, item: item, category: ServiceCategory.dokyu, masterFile: mf, requests: requests);

        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Offered, not attached — no "Uploaded" tile anywhere on this step.
        // The Master File filename does appear once, as part of the
        // "Existing document found" offer card itself (not as an attached
        // tile) — that's the whole point of the offer.
        expect(find.text('Existing document found'), findsNWidgets(2));
        expect(find.text('Use Existing Document'), findsNWidgets(2));
        expect(find.textContaining('Uploaded'), findsNothing);
        expect(find.text('valid_id_from_earlier_service.pdf'), findsOneWidget);

        // Submitting right now must still be blocked — nothing is attached.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please attach: One (1) valid government-issued ID, Proof of residency.'),
          findsOneWidget,
        );

        // The resident can now explicitly choose Use Existing Document —
        // only then does it attach.
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Uploaded'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Educational Assistance (Tulong) — no Master File data: all 3 requirements show Upload buttons only', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      final requests = await _readyRequests(tester);
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_educational');
      await pumpWizard(tester, item: item, category: ServiceCategory.tulong, masterFile: mf, requests: requests);

      // Applicant Info -> Student Info -> Family Background -> Additional
      // Information -> Requirements: 4 Continue taps from step 0.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Upload Certificate of Enrollment'), findsOneWidget);
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
      expect(find.textContaining('Uploaded'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('New application: requirements always start unattached (single-step forms)', () {
    testWidgets('Cedula (Dokyu, no formSpec) — no Master File data: Upload buttons only', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      final requests = await _readyRequests(tester);
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_cedula');
      await pumpSinglePage(tester, item: item, category: ServiceCategory.dokyu, masterFile: mf, requests: requests);

      expect(find.text('Upload One (1) valid government-issued ID'), findsOneWidget);
      expect(find.textContaining('Uploaded'), findsNothing);
      expect(find.text('Existing document found'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Medical Assistance (Tulong, no formSpec) — Master File has a matching doc: offered, not attached', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('old_id.pdf'),
        origin: 'Dokyu',
        serviceName: 'Cedula (Community Tax Certificate)',
      );
      final requests = await _readyRequests(tester);
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_medical');
      await pumpSinglePage(tester, item: item, category: ServiceCategory.tulong, masterFile: mf, requests: requests);

      expect(find.text('Existing document found'), findsOneWidget);
      expect(find.text('Use Existing Document'), findsOneWidget);
      expect(find.textContaining('Uploaded'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Already-submitted requests are never affected by this behavior', () {
    testWidgets('a historical request with real attachments still displays them exactly as submitted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final submitted = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: [
          _fakeAttachment('my_real_id.pdf'),
          _fakeAttachment('my_real_residency_proof.pdf'),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: requests,
          child: MaterialApp(home: RequestDetailScreen(requestId: submitted.id)),
        ),
      );
      await tester.pumpAndSettle();

      // Long milestone timeline pushes the Attachments section outside the
      // initial render/cache extent even at a realistic phone viewport —
      // same reasoning as request_milestone_simulation_test.dart's own
      // _scrollToAndTap helper.
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      );
      await tester.pumpAndSettle();

      expect(find.text('my_real_id.pdf'), findsOneWidget);
      expect(find.text('my_real_residency_proof.pdf'), findsOneWidget);
      expect(find.text('Attachments (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
