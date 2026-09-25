// Coverage for the Senior Citizen ID Application (OSCA Membership)
// reclassification: it now lives in Dokyu (documentTypes), not Tulong
// (assistanceTypes) — a catalog/module move, not a rebuild. Form fields,
// requirements, per-requirement upload cards, submission, and Track This
// Request all carry over unchanged; a device that already persisted a
// genuine Senior Citizen ID request under the old Tulong category gets it
// safely re-categorized on load, without losing anything.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/service_request.dart';
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
import 'package:teresa_rizal/utils/requirement_document_type.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';
const _seniorCitizenIdName = 'Senior Citizen ID Application (OSCA Membership)';

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
  group('Catalog reclassification — moved, not duplicated', () {
    test('Senior Citizen ID appears exactly once, under Dokyu, never under Tulong', () {
      final inDokyu = MockCatalog.documentTypes.where((i) => i.name == _seniorCitizenIdName).toList();
      final inTulong = MockCatalog.assistanceTypes.where((i) => i.name == _seniorCitizenIdName).toList();

      expect(inDokyu.length, 1);
      expect(inTulong, isEmpty);
      expect(inDokyu.single.key, 'dokyu_senior_citizen_id');
    });

    test('the moved item keeps its exact original office, fee, days, requirements, and form fields', () {
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_senior_citizen_id');

      expect(item.office, 'Office for Senior Citizens Affairs');
      expect(item.fee, 'Free');
      expect(item.days, '3-5 working days');
      expect(item.requirements, [
        'PSA Birth Certificate or valid ID showing birthdate',
        '2 recent 1x1 ID photos',
        'Barangay Certification',
      ]);
      expect(item.formSpec, isNotNull);
      expect(item.formSpec!.steps.map((s) => s.label), ['Personal Information', 'Government Service Record']);
    });

    test('other Tulong programs are untouched', () {
      for (final name in [
        'Medical Assistance (AICS)',
        'Burial Assistance (AICS)',
        'Educational Assistance',
        'Financial Assistance (AICS)',
        'Social Pension (Indigent Senior Citizen)',
      ]) {
        expect(MockCatalog.assistanceTypes.any((i) => i.name == name), isTrue, reason: '$name should still be Tulong');
      }
    });

    test('other Dokyu services are untouched', () {
      expect(MockCatalog.documentTypes.any((i) => i.key == 'dokyu_barangay_clearance'), isTrue);
      expect(MockCatalog.documentTypes.any((i) => i.key == 'dokyu_first_time_jobseeker'), isTrue);
      expect(MockCatalog.documentTypes.any((i) => i.key == 'dokyu_marriage_license'), isTrue);
    });
  });

  group('Dokyu end-to-end: open -> fill -> upload individually -> submit -> Track This Request', () {
    testWidgets(
      'shows 3 separate requirement-specific upload cards (not the old generic uploader) and submits as Dokyu',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: documentTypeFor('PSA Birth Certificate or valid ID showing birthdate'),
          label: 'PSA Birth Certificate or valid ID showing birthdate',
          attachment: _fakeAttachment('psa_birth_cert.pdf'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: documentTypeFor('2 recent 1x1 ID photos'),
          label: '2 recent 1x1 ID photos',
          attachment: _fakeAttachment('id_photos.jpg'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'barangay_certification',
          label: 'Barangay Certification',
          attachment: _fakeAttachment('brgy_cert.pdf'),
          origin: 'Test',
        );

        final session = await _signedInAsVerifiedDemo(tester);
        final requests = await _readyRequests(tester);
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_senior_citizen_id');

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
        // Personal Information step — Date of Birth/Sex/Civil Status are
        // locked/prefilled from her Resident Profile (see the wizard's own
        // _masterEligibleKeys treatment). Educational Attainment is the one
        // exception: her real profile value ('Senior High School') isn't in
        // this field's own option list (predates the K-12 tier), so the
        // master-eligible guard safely skips locking it — it stays a
        // normal, editable select, filled via an explicit demoDefault
        // ('High School', the closest valid, non-crashing approximation)
        // so Continue is never blocked here either.
        expect(find.text('High School'), findsOneWidget);
        expect(find.text('Select Educational Attainment'), findsNothing);
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        // Government Service Record step — every field optional.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Requirements step — exactly 3 separate, requirement-specific
        // upload cards, never the old generic "Add photo or document".
        expect(find.text('PSA Birth Certificate or valid ID showing birthdate'), findsOneWidget);
        expect(find.text('2 recent 1x1 ID photos'), findsOneWidget);
        expect(find.text('Barangay Certification'), findsOneWidget);
        expect(find.text('Existing document found'), findsNWidgets(3));
        expect(find.text('Add photo or document'), findsNothing);

        while (find.text('Use Existing Document').evaluate().isNotEmpty) {
          await tester.ensureVisible(find.text('Use Existing Document').first);
          await tester.tap(find.text('Use Existing Document').first);
          await tester.pumpAndSettle();
        }

        await tester.enterText(find.byType(TextField).first, 'Applying for OSCA membership');
        await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
        await tester.pumpAndSettle();

        // Every Dokyu request now lands on the receipt screen first — a
        // receipt is generated at submission time, paid or free — never
        // the older generic Request Submitted screen (see
        // RequestsService.submit). Senior Citizen ID is Free, so it gets a
        // no-amount formality receipt, not a payment step.
        expect(find.byType(ReceiptScreen), findsOneWidget);
        final submitted = requests.all.single;
        expect(submitted.typeName, _seniorCitizenIdName);
        // The whole point of this move — a *new* application is now
        // categorized Dokyu.
        expect(submitted.category, ServiceCategory.dokyu);
        expect(submitted.attachments.length, 3);

        await tester.tap(find.widgetWithText(AppButton, 'Done'));
        await tester.pumpAndSettle();

        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Migration: an existing Tulong-categorized Senior Citizen ID request', () {
    testWidgets('is corrected to Dokyu on load, with every other field preserved exactly', (tester) async {
      final staleRequest = ServiceRequest(
        id: 'req-1700000000001',
        referenceNumber: 'AR-2026-0007',
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: _seniorCitizenIdName,
        category: ServiceCategory.tulong,
        office: 'Office for Senior Citizens Affairs',
        purpose: 'Applying for OSCA membership',
        submittedAt: DateTime(2026, 2, 1),
        status: 'Approved',
        statusHistory: [
          StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 2, 1), actor: 'Citizen'),
          StatusHistoryEntry(status: 'Approved', at: DateTime(2026, 2, 3), actor: 'Office for Senior Citizens Affairs Staff'),
        ],
        attachments: [
          Attachment(
            id: 'att-1',
            fileName: 'psa_birth_cert.pdf',
            category: AttachmentCategory.pdf,
            sizeBytes: 4096,
            addedAt: DateTime(2026, 2, 1),
            documentTypeLabel: 'PSA Birth Certificate or valid ID showing birthdate',
          ),
        ],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([staleRequest.toJson()]),
      });

      final requests = await _readyRequests(tester);
      final migrated = requests.all.firstWhere((r) => r.id == 'req-1700000000001');

      expect(migrated.category, ServiceCategory.dokyu);
      // Nothing else changed.
      expect(migrated.referenceNumber, 'AR-2026-0007');
      expect(migrated.status, 'Approved');
      expect(migrated.statusHistory.length, 2);
      expect(migrated.attachments.length, 1);
      expect(migrated.attachments.single.fileName, 'psa_birth_cert.pdf');
      expect(migrated.applicantName, 'Perlita Quiambao');

      // Now correctly retrievable under Dokyu, not Tulong.
      expect(requests.byCategory(ServiceCategory.dokyu).any((r) => r.id == 'req-1700000000001'), isTrue);
      expect(requests.byCategory(ServiceCategory.tulong).any((r) => r.id == 'req-1700000000001'), isFalse);

      // Re-persisted, not just corrected in memory.
      final prefs = await SharedPreferences.getInstance();
      final resaved = jsonDecode(prefs.getString('teresa_rizal_service_requests')!) as List;
      final resavedRequest = resaved.first as Map<String, dynamic>;
      expect(resavedRequest['category'], ServiceCategory.dokyu.name);
    });

    testWidgets('a Tulong request with a different typeName is never touched', (tester) async {
      final unrelated = ServiceRequest(
        id: 'req-1700000000002',
        referenceNumber: 'AR-2026-0008',
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Hospital bill assistance',
        submittedAt: DateTime(2026, 2, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 2, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([unrelated.toJson()]),
      });

      final requests = await _readyRequests(tester);
      final untouched = requests.all.firstWhere((r) => r.id == 'req-1700000000002');
      expect(untouched.category, ServiceCategory.tulong);
    });

    testWidgets('an already-Dokyu Senior Citizen ID request (submitted after the move) is left alone', (tester) async {
      final alreadyCorrect = ServiceRequest(
        id: 'req-1700000000003',
        referenceNumber: 'DR-2026-0099',
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: _seniorCitizenIdName,
        category: ServiceCategory.dokyu,
        office: 'Office for Senior Citizens Affairs',
        purpose: 'Applying for OSCA membership',
        submittedAt: DateTime(2026, 3, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 3, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_service_requests': jsonEncode([alreadyCorrect.toJson()]),
      });

      final requests = await _readyRequests(tester);
      final result = requests.all.firstWhere((r) => r.id == 'req-1700000000003');
      expect(result.category, ServiceCategory.dokyu);
      expect(result.referenceNumber, 'DR-2026-0099');
    });
  });
}
