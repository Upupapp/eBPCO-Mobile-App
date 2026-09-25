// Coverage for Dokyu's per-requirement attachment architecture: every
// requirement on a catalog item gets its own uploader (not one generic
// "Add photo or document" for the whole form), uploads stay scoped to
// their own requirement, missing requirements block submission with a
// specific message naming them, and a resident's Master File offers a
// previously uploaded matching document for reuse instead of forcing a
// re-upload — without creating a duplicate Master File entry. Exercised
// against Business Permit (New Application), which has no ServiceFormSpec
// and so renders through the older single-step NewRequestScreen — the
// same per-requirement architecture ServiceRequestWizardScreen's own
// Requirements & Attachments step also now uses (see
// service_request_wizard_test.dart for that path).
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/new_request_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';

Attachment _fakeAttachment(String fileName, {AttachmentCategory category = AttachmentCategory.pdf}) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: category,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: fileName,
  );
}

// Under AutomatedTestWidgetsFlutterBinding's fake clock, a plain
// `Future.delayed` registered outside `tester.pump`/`tester.runAsync` never
// fires on its own — this must drive the wait via `tester.pump`, same as
// every other "wait for a service's async _restore() to finish" helper in
// this suite.
Future<MasterFileService> _readyMasterFile(WidgetTester tester) async {
  // The one and only SharedPreferences.setMockInitialValues call for a test
  // — it replaces the entire mock backing store, so this must run before
  // MasterFileService (or anything else) touches SharedPreferences at all;
  // _pumpBusinessPermit deliberately does not call it again, or a
  // pre-seeded Master File document saved via this service would be wiped
  // out from under it.
  SharedPreferences.setMockInitialValues({});
  final mf = MasterFileService();
  var attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return mf;
}

Future<RequestsService> _pumpBusinessPermit(WidgetTester tester, {required MasterFileService masterFile}) async {
  // The default 800x600 test canvas is too short for 5 requirement cards
  // plus the Submit button — a normal phone viewport keeps everything
  // reachable without needing to scroll before every tap.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Mock SharedPreferences values are already set by _readyMasterFile —
  // see its own comment for why this must not call setMockInitialValues
  // again.
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

  final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_business_new');

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
      ],
      child: MaterialApp(
        home: NewRequestScreen(category: ServiceCategory.dokyu, item: item, accent: AppColors.brand600),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

void main() {
  group('Business Permit — one uploader per requirement', () {
    testWidgets('shows a separate uploader for each of the 5 requirements, no generic single uploader', (
      tester,
    ) async {
      final mf = await _readyMasterFile(tester);
      await _pumpBusinessPermit(tester, masterFile: mf);

      for (final label in [
        'DTI or SEC Registration',
        'Barangay Business Clearance',
        'Locational / Zoning Clearance',
        'Sanitary Permit',
        'Cedula',
      ]) {
        expect(find.text(label), findsOneWidget);
        // Requirement-specific button label, not a generic "Upload
        // Document" — see RequirementUploader's own _UploadPrompt.
        expect(find.text('Upload $label'), findsOneWidget);
      }
      // The old generic single-uploader affordance must be gone for Dokyu.
      // Asserted by its label rather than by widget type: AttachmentPicker was
      // deleted in FE 08 (unreachable from main.dart, its capabilities fully
      // covered by RequirementUploader), so there is no type left to name.
      expect(find.text('Add photo or document'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing requirements block submission and name exactly what is missing', (tester) async {
      final mf = await _readyMasterFile(tester);
      final requests = await _pumpBusinessPermit(tester, masterFile: mf);

      await tester.enterText(find.byType(TextField).first, 'New business registration');
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.tap(find.text('Continue to Payment'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Please attach: DTI or SEC Registration, Barangay Business Clearance, Locational / Zoning Clearance, '
          'Sanitary Permit, Cedula.',
        ),
        findsOneWidget,
      );
      expect(requests.all, isEmpty); // nothing was submitted
    });
  });

  group('Master File reuse', () {
    testWidgets('a matching Master File document offers reuse only under its own requirement', (tester) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'dti_or_sec_registration',
        label: 'DTI or SEC Registration',
        attachment: _fakeAttachment('dti_cert.pdf'),
        origin: 'Dokyu',
      );
      await _pumpBusinessPermit(tester, masterFile: mf);

      expect(find.text('Existing document found'), findsOneWidget);
      expect(find.text('dti_cert.pdf'), findsOneWidget);
      expect(find.text('Use Existing Document'), findsOneWidget);
      expect(find.text('Upload New Document'), findsOneWidget);
      // Every other requirement (no match for their own document type) still
      // shows its own plain, requirement-specific upload prompt.
      for (final label in ['Barangay Business Clearance', 'Locational / Zoning Clearance', 'Sanitary Permit', 'Cedula']) {
        expect(find.text('Upload $label'), findsOneWidget);
      }
    });

    testWidgets('"Use Existing Document" attaches it locally and creates no duplicate Master File entry', (
      tester,
    ) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'dti_or_sec_registration',
        label: 'DTI or SEC Registration',
        attachment: _fakeAttachment('dti_cert.pdf'),
        origin: 'Dokyu',
      );
      await _pumpBusinessPermit(tester, masterFile: mf);

      await tester.ensureVisible(find.text('Use Existing Document'));
      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();

      expect(find.text('Existing document found'), findsNothing);
      expect(find.text('dti_cert.pdf'), findsOneWidget); // now the attached tile's own filename
      expect(find.text('Replace'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      final dtiDocs = mf
          .documentsFor(_verifiedDemoId)
          .where((d) => d.documentType == 'dti_or_sec_registration')
          .toList();
      expect(dtiDocs.length, 1); // reuse never duplicated the Master File entry
      expect(tester.takeException(), isNull);
    });

    testWidgets('reusing one requirement leaves the others still requiring their own attachment', (tester) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'cedula',
        label: 'Cedula',
        attachment: _fakeAttachment('cedula_2026.jpg'),
        origin: 'Dokyu',
      );
      final requests = await _pumpBusinessPermit(tester, masterFile: mf);

      await tester.ensureVisible(find.text('Use Existing Document'));
      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();
      expect(find.text('cedula_2026.jpg'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'New business registration');
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.tap(find.text('Continue to Payment'));
      await tester.pumpAndSettle();

      // Cedula is satisfied (reused) — only the other 4 are still missing.
      expect(
        find.text(
          'Please attach: DTI or SEC Registration, Barangay Business Clearance, Locational / Zoning Clearance, '
          'Sanitary Permit.',
        ),
        findsOneWidget,
      );
      expect(requests.all, isEmpty);
    });

    testWidgets('Remove clears the local attachment without deleting it from the Master File', (tester) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'dti_or_sec_registration',
        label: 'DTI or SEC Registration',
        attachment: _fakeAttachment('dti_cert.pdf'),
        origin: 'Dokyu',
      );
      await _pumpBusinessPermit(tester, masterFile: mf);
      await tester.ensureVisible(find.text('Use Existing Document'));
      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Remove'));
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Back to the (still-available) reuse offer for this one application —
      // the Master File document itself was never touched by Remove.
      expect(find.text('Existing document found'), findsOneWidget);
      expect(mf.documentsFor(_verifiedDemoId).any((d) => d.documentType == 'dti_or_sec_registration'), isTrue);
    });

    testWidgets('"Upload New Document" opens the same source sheet as a first-time upload', (tester) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'dti_or_sec_registration',
        label: 'DTI or SEC Registration',
        attachment: _fakeAttachment('dti_cert.pdf'),
        origin: 'Dokyu',
      );
      await _pumpBusinessPermit(tester, masterFile: mf);

      await tester.ensureVisible(find.text('Upload New Document'));
      await tester.tap(find.text('Upload New Document'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose Image'), findsOneWidget);
      expect(find.text('Choose File / PDF'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
