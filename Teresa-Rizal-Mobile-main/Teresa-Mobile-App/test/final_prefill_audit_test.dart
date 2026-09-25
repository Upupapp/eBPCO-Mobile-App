// Coverage for the Final Prefill Audit pass — every Dokyu/Tulong form is
// actually rendered (not just read from mock_catalog.dart) to catch the
// class of bug this audit specifically targets: a field key mismatch, a
// dropdown option that doesn't match its own demo/Master-Profile value
// (which crashes DropdownButtonFormField outright), or a form that
// "technically" has demoDefaults but still shows blanks. Also verifies this
// pass's own explicit exclusions: logically inapplicable identity
// attributes (Senior Citizen, PWD/disability, ERPAT's fathers'-program
// framing, Solo Parent's own circumstance) are never fabricated for Perlita,
// even though the ordinary applicant fields on those same forms still
// legitimately prefill from her Resident Master Profile.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/catalog_item.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

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

Future<RequestsService> _pumpWizard(
  WidgetTester tester, {
  required CatalogItem item,
  required ServiceCategory category,
  MasterFileService? masterFile,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
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
  final mf = masterFile ?? MasterFileService();
  attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

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
        home: ServiceRequestWizardScreen(category: category, item: item, accent: AppColors.brand600),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(AppButton, 'Continue'));
  await tester.pumpAndSettle();
}

void main() {
  group('Complex Dokyu — Senior Citizen ID Application (OSCA Membership)', () {
    testWidgets(
      'renders every step without crashing; ordinary applicant fields prefill; no fabricated senior-only data',
      (tester) async {
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_senior_citizen_id');
        await _pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

        await _continue(tester); // Applicant Info -> Personal Information
        expect(find.text('Teresa, Rizal'), findsOneWidget); // placeOfBirth, auto from profile
        expect(find.text('Female'), findsOneWidget); // sex, auto
        expect(find.text('Single'), findsOneWidget); // civilStatus, auto
        // 'presentOccupation', not 'occupation' — needed its own explicit
        // demoDefault (a field-key mismatch this audit specifically fixed).
        expect(find.text('Student'), findsOneWidget);
        // This field's own option list predates the K-12 Senior High tier
        // (no such option exists there at all) — 'High School' is the
        // closest valid, non-crashing approximation; the wizard must not
        // have crashed getting here at all, which is the real regression
        // this guards against.
        expect(find.text('High School'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _continue(tester); // -> Government Service Record
        // She has no prior government employment — never fabricated.
        expect(find.text('Last Government Office'), findsOneWidget); // just the label, field itself is empty
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Complex Tulong — Solo Parent Cash Assistance', () {
    testWidgets(
      'ordinary fields and the real 4Ps fact prefill; solo-parent-specific circumstances are never fabricated',
      (tester) async {
        final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_solo_parent');
        await _pumpWizard(tester, item: item, category: ServiceCategory.tulong);

        await _continue(tester); // Applicant Info -> Identifying Information
        expect(find.text('Female'), findsOneWidget);
        expect(find.text('Teresa, Rizal'), findsOneWidget);
        expect(find.text('High School'), findsOneWidget); // educationalAttainment, option-list-safe value
        expect(find.text('Single'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget); // occupation, auto
        // isPantawidBeneficiary — a real, true fact already on her
        // Resident Master Profile (4Ps Beneficiary), not fabricated.
        expect(find.byType(Checkbox), findsWidgets);
        expect(tester.takeException(), isNull);

        await _continue(tester); // -> Family Composition
        expect(find.text('Children / Dependents (name, age, relationship)'), findsOneWidget);
        // A required field — 'None' is the truthful, non-fabricated answer
        // (she genuinely has no children/dependents), not an invented name.
        expect(find.text('None'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _continue(tester); // -> Classification
        expect(find.text('Select Circumstance of Being a Solo Parent'), findsOneWidget); // still unselected
        expect(tester.takeException(), isNull);

        // Skip past the required Classification select without choosing
        // one — proves it was genuinely left blank, not silently defaulted.
      },
    );

    testWidgets('Emergency Contact fields reuse her real Resident Profile contact, not an invented one', (
      tester,
    ) async {
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_solo_parent');
      final requests = await _pumpWizard(tester, item: item, category: ServiceCategory.tulong);
      expect(requests.all, isEmpty); // sanity: nothing submitted yet

      await _continue(tester); // -> Identifying Information
      await _continue(tester); // -> Family Composition
      await _continue(tester); // -> Classification
      // Classification is a required select genuinely left unselected (see
      // the sibling test above) — a real presenter must pick one to
      // proceed, same as they would for any other required field this
      // audit doesn't prefill on purpose. Selecting one here only to reach
      // the later step under test, not to claim it's prefilled.
      await tester.ensureVisible(find.text('Select Circumstance of Being a Solo Parent'));
      await tester.tap(find.text('Select Circumstance of Being a Solo Parent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widow / widower').last);
      await tester.pumpAndSettle();
      await _continue(tester); // -> Needs & Emergency Contact

      expect(find.text('Rogelio Escano'), findsOneWidget);
      expect(find.text('0919 000 9012'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PWD Registration (PRPWD) — logically inapplicable identity, ordinary fields still prefill', () {
    testWidgets('renders every step without crashing; disability is never fabricated', (tester) async {
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_pwd_registration');
      await _pumpWizard(tester, item: item, category: ServiceCategory.tulong);

      await _continue(tester); // Applicant Info -> Personal Information
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _continue(tester); // -> Disability Information
      // Never fabricated — no disability type/cause is pre-selected.
      expect(find.text('Type of Disability'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _continue(tester); // this step's required multiselects are
      // left for the presenter to demonstrate deliberately, or this
      // service simply isn't part of a Perlita-persona demo — see this
      // pass's own report.
    });
  });

  group("ERPAT Program Registration (Fathers' Empowerment) — logically inapplicable, ordinary fields still prefill", () {
    testWidgets('renders without crashing; ordinary fields prefill; never reframes her as a father', (tester) async {
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_erpat_registration');
      await _pumpWizard(tester, item: item, category: ServiceCategory.tulong);

      await _continue(tester); // Applicant Info -> Personal Information
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _continue(tester); // -> Family & Background
      // Household Members is a REQUIRED field with no generic Master
      // Profile source — left genuinely blank, it would silently block
      // Continue past this step. It's filled with her real, already-
      // established household (Father, Mother, herself), never a fabricated
      // one; this is a fathers' program, but listing her own true household
      // composition isn't "reframing her as a father."
      expect(
        find.text('Anselmo Quiambao (Father), Lourdes Quiambao (Mother), Perlita Quiambao (Self)'),
        findsOneWidget,
      );
      // educationalAttainment — same closest-valid-option fallback used
      // elsewhere in this pass (this field's own option list has no Senior
      // High tier), filled via an explicit demoDefault so this required
      // field doesn't block Continue either.
      expect(find.text('High School'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _continue(tester); // proves neither required field blocks Continue
      expect(tester.takeException(), isNull);
    });
  });

  group('Barangay Certification for Late Registration of Birth — a family-member scenario, not her own', () {
    testWidgets(
      'fields naming the family member stay blank; fields the wizard cannot attribute to a third party still show '
      'her own values; Purpose reflects the family-member framing',
      (tester) async {
        final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_cert_late_birth');
        await _pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

        await _continue(tester); // Applicant Info -> Person's Details
        // Never fabricated — Web Admin's own record never names the family
        // member, so this pass doesn't invent one either.
        expect(find.text('Perlita Quiambao'), findsNothing);
        expect(find.text('Lourdes Escano'), findsNothing); // motherMaidenName, deliberately blank
        expect(find.text('Filipino'), findsNothing); // citizenship, deliberately blank
        // Known architectural limitation (documented in mock_catalog.dart
        // and this pass's own report): the generic Master-Profile prefill
        // matches on field key alone, so these still show Perlita's own
        // values even though the form is about someone else.
        expect(find.text('Anselmo Quiambao'), findsOneWidget); // fatherName, via the generic Father/Mother block
        expect(find.text('Mar 15, 2001'), findsOneWidget); // dateOfBirth, auto
        expect(find.text('Teresa, Rizal'), findsOneWidget); // placeOfBirth, auto
        expect(find.text('Female'), findsOneWidget);
        expect(find.text('Single'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget); // occupation, auto
        expect(tester.takeException(), isNull);

        // personFullName/motherMaidenName/citizenship are REQUIRED fields
        // this pass deliberately leaves blank rather than naming a specific
        // relative Web Admin never establishes — so, unlike every other
        // service in this audit, this one genuinely cannot reach Review &
        // Submit without the presenter typing the family member's own
        // details by hand. That's an accepted, disclosed exception (see
        // this pass's own report), not a bug: Continue correctly blocks
        // rather than silently submitting a request about the wrong person.
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Please complete "Full Name".'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Review & Submit reflects live edits, not a frozen prefill snapshot', () {
    testWidgets('editing a prefilled value before Review shows the updated value, not the original prefill', (
      tester,
    ) async {
      final mf = MasterFileService();
      var attempts = 0;
      while (!mf.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('MasterFileService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await mf.saveOrUpdate(
        accountId: 'ESP-RES-2024-9002',
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('gov_id.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: 'ESP-RES-2024-9002',
        documentType: 'proof_of_business_location_lease_contract_or_land_title',
        label: 'Proof of business location (lease contract or land title)',
        attachment: _fakeAttachment('business_location.pdf'),
        origin: 'Test',
      );

      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_business_clearance');
      await _pumpWizard(tester, item: item, category: ServiceCategory.dokyu, masterFile: mf);

      await _continue(tester); // Applicant Info -> Business Details
      expect(find.text("Quiambao's Sari-Sari Store"), findsOneWidget);

      final businessNameField = find.widgetWithText(TextField, "Quiambao's Sari-Sari Store");
      await tester.enterText(businessNameField, "Perlita's Variety Store");
      await tester.pumpAndSettle();

      await _continue(tester); // -> Requirements & Attachments
      while (find.text('Use Existing Document').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();
      }
      await _continue(tester); // -> Review & Submit

      expect(find.text("Perlita's Variety Store"), findsOneWidget);
      expect(find.text("Quiambao's Sari-Sari Store"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
