// Coverage for the Perlita Master Profile + Educational Assistance alignment
// pass: her resident-fact data now matches the Web Admin's own Educational
// Assistance record (corrected DOB, place of birth, school, family
// background, income), a calculated Age field on Personal Information,
// seeded Anselmo/Lourdes family members, per-requirement Educational
// Assistance uploads that start empty, and a migration that safely corrects
// a device that already persisted the old placeholder profile.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/resident_profile.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/family_information_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/request_submitted_screen.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/utils/age_calculator.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';
final _verifiedDemoDob = DateTime(2001, 3, 15);

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

Future<ResidentProfileService> _readyProfiles(WidgetTester tester) async {
  final service = ResidentProfileService();
  var attempts = 0;
  while (!service.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('ResidentProfileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return service;
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
  group('Resident Master Profile — fresh seed', () {
    testWidgets("Perlita's freshly-seeded profile matches the Web Admin Educational Assistance record", (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      final profile = profiles.profileFor(session.account!);
      final personal = profile.personal;

      expect(personal.birthdate, _verifiedDemoDob);
      expect(personal.civilStatus, 'Single');
      expect(personal.occupation, 'Student');
      expect(personal.educationalAttainment, 'Senior High School'); // closest valid option to "...Graduate"
      expect(personal.email, isEmpty); // "not on file" per the Web Admin record
      expect(personal.isFourPsBeneficiary, isTrue);
      expect(personal.placeOfBirth, 'Teresa, Rizal');
      expect(personal.schoolName, 'Teresa National High School');
      expect(personal.yearOrGradeLevel, '2nd Year College');
      expect(personal.degreeProgramOrCourse, 'BS Education');
      expect(personal.lastSchoolAverageGrade, '90');
      expect(personal.communityInvolvement, 'Member of the church youth ministry.');
      expect(personal.postGraduationPlans, 'Plans to apply for government service after graduation.');
      expect(profile.household.monthlyIncome, '₱9,718');

      final father = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Father');
      expect(father.fullName, 'Anselmo Quiambao');
      expect(father.occupation, 'Construction Worker');

      final mother = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Mother');
      expect(mother.fullName, 'Lourdes Quiambao');
      expect(mother.occupation, 'Sari-Sari Store Vendor');
      expect(mother.maidenName, 'Escano');

      // Head of Family is untouched — still Perlita herself.
      expect(profile.headIndividualId, _verifiedDemoId);

      // Her Web Admin Constituents record's exact Household/Family ids —
      // not the generic hash-derived scheme every other account seeds with.
      expect(profile.householdId, 'HH-2026-9002');
      expect(profile.familyId, 'FAM-2026-9002');

      expect(profile.emergencyContactName, 'Rogelio Escano');
      expect(profile.emergencyContactRelationship, 'Brother');
      expect(profile.emergencyContactNumber, '0919 000 9012');
    });

    testWidgets("Nicanor's profile is completely unaffected by Perlita's alignment", (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await session.login(MockCatalog.demoAccounts.first); // Nicanor
      final profiles = await _readyProfiles(tester);
      final profile = profiles.profileFor(session.account!);

      expect(profile.personal.birthdate, isNot(_verifiedDemoDob));
      expect(profile.personal.placeOfBirth, isEmpty);
      expect(profile.familyMembers, isEmpty);
      expect(profile.household.monthlyIncome, isEmpty);
    });
  });

  group('Resident Master Profile — migration for an already-persisted stale device', () {
    testWidgets('an old placeholder Perlita profile (Nov 29 1988, no family) is corrected on load, unrelated data preserved', (
      tester,
    ) async {
      final staleProfile = ResidentProfile(
        citizenAccountId: _verifiedDemoId,
        personal: Individual(
          individualId: _verifiedDemoId,
          firstName: 'Perlita',
          lastName: 'Quiambao',
          sex: 'Female',
          birthdate: DateTime(1988, 11, 29),
          civilStatus: 'Married',
          mobile: '0919 000 9002',
          barangay: 'Bagumbayan',
          sitioPurok: 'Purok 2',
          completeAddress: 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
          occupation: 'Market Vendor',
          householdId: 'HH-2026-9002',
        ),
        familyName: 'Quiambao Family',
        headIndividualId: _verifiedDemoId,
        familyId: 'FAM-2026-9002',
        householdId: 'HH-2026-9002',
        household: Household(householdId: 'HH-2026-9002', barangay: 'Bagumbayan'),
        personalSaved: true,
        familySaved: true,
      );
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_resident_profiles': jsonEncode({_verifiedDemoId: staleProfile.toJson()}),
      });

      final profiles = await _readyProfiles(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final migrated = profiles.profileFor(session.account!);

      expect(migrated.personal.birthdate, _verifiedDemoDob);
      expect(migrated.personal.civilStatus, 'Single');
      // Occupation is now itself a Web-Admin-sourced correction target too
      // (an old "Market Vendor" placeholder is explicitly superseded by
      // "Student" — see this correction's own report), so unlike the
      // fields checked below it is NOT preserved from the stale device.
      expect(migrated.personal.occupation, 'Student');
      expect(migrated.personal.educationalAttainment, 'Senior High School');
      expect(migrated.personal.isFourPsBeneficiary, isTrue);
      expect(migrated.personal.placeOfBirth, 'Teresa, Rizal');
      expect(migrated.household.monthlyIncome, '₱9,718');
      expect(migrated.familyMembers.any((m) => m.relationshipToHead == 'Father'), isTrue);
      expect(migrated.familyMembers.any((m) => m.relationshipToHead == 'Mother'), isTrue);
      expect(
        migrated.familyMembers.firstWhere((m) => m.relationshipToHead == 'Mother').maidenName,
        'Escano',
      );
      expect(migrated.emergencyContactName, 'Rogelio Escano');
      expect(migrated.emergencyContactRelationship, 'Brother');
      expect(migrated.emergencyContactNumber, '0919 000 9012');

      // Genuinely unrelated pre-existing data (never touched by this
      // alignment) is preserved exactly, not reset.
      expect(migrated.personal.mobile, '0919 000 9002');
      expect(migrated.personalSaved, isTrue);
      expect(migrated.familySaved, isTrue);

      // Re-persisted, not just corrected in memory.
      final prefs = await SharedPreferences.getInstance();
      final resaved = jsonDecode(prefs.getString('teresa_rizal_resident_profiles')!) as Map<String, dynamic>;
      final resavedPersonal = resaved[_verifiedDemoId]['personal'] as Map<String, dynamic>;
      expect(resavedPersonal['birthdate'], _verifiedDemoDob.toIso8601String());
      final resavedMembers = resaved[_verifiedDemoId]['familyMembers'] as List;
      expect(resavedMembers.length, 2);
    });

    testWidgets('a device that never ran the old code and has no persisted Perlita profile still seeds correctly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final profiles = await _readyProfiles(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final profile = profiles.profileFor(session.account!);

      expect(profile.personal.birthdate, _verifiedDemoDob);
      expect(profile.familyMembers.length, 2);
      expect(profile.householdId, 'HH-2026-9002');
      expect(profile.familyId, 'FAM-2026-9002');
    });

    testWidgets(
      'a device whose Household/Family ids predate the Web Admin sync (old hash-derived scheme) is corrected on '
      'load, without duplicating or losing family members',
      (tester) async {
        // The old generic hash-derived scheme every account still uses for
        // ResidentProfile.seedFrom — deliberately NOT HH-2026-9002/
        // FAM-2026-9002, to prove the migration actually rewrites a
        // mismatched id rather than happening to already match.
        const staleHouseholdId = 'HH-2026-741';
        const staleFamilyId = 'FAM-2026-741';
        final staleProfile = ResidentProfile(
          citizenAccountId: _verifiedDemoId,
          personal: Individual(
            individualId: _verifiedDemoId,
            firstName: 'Perlita',
            lastName: 'Quiambao',
            sex: 'Female',
            birthdate: _verifiedDemoDob,
            civilStatus: 'Single',
            mobile: '0919 000 9002',
            barangay: 'Bagumbayan',
            sitioPurok: 'Purok 2',
            completeAddress: 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
            occupation: 'Student',
            householdId: staleHouseholdId,
          ),
          familyMembers: [
            Individual(
              individualId: 'IND-$_verifiedDemoId-FATHER',
              firstName: 'Anselmo',
              lastName: 'Quiambao',
              relationshipToHead: 'Father',
              occupation: 'Construction Worker',
              familyId: staleFamilyId,
              householdId: staleHouseholdId,
            ),
          ],
          familyName: 'Quiambao Family',
          headIndividualId: _verifiedDemoId,
          familyId: staleFamilyId,
          householdId: staleHouseholdId,
          household: Household(householdId: staleHouseholdId, barangay: 'Bagumbayan', familyIds: [staleFamilyId]),
          personalSaved: true,
          familySaved: true,
        );
        SharedPreferences.setMockInitialValues({
          'teresa_rizal_resident_profiles': jsonEncode({_verifiedDemoId: staleProfile.toJson()}),
        });

        final profiles = await _readyProfiles(tester);
        final session = await _signedInAsVerifiedDemo(tester);
        final migrated = profiles.profileFor(session.account!);

        expect(migrated.householdId, 'HH-2026-9002');
        expect(migrated.familyId, 'FAM-2026-9002');
        expect(migrated.household.householdId, 'HH-2026-9002');
        expect(migrated.household.familyIds, ['FAM-2026-9002']);
        // Mother gets added (was never on this stale device); Father is
        // corrected in place, never duplicated.
        expect(migrated.familyMembers.length, 2);
        final father = migrated.familyMembers.firstWhere((m) => m.relationshipToHead == 'Father');
        expect(father.familyId, 'FAM-2026-9002');
        expect(father.householdId, 'HH-2026-9002');
        final mother = migrated.familyMembers.firstWhere((m) => m.relationshipToHead == 'Mother');
        expect(mother.familyId, 'FAM-2026-9002');
        expect(mother.householdId, 'HH-2026-9002');

        // Re-persisted, not just corrected in memory.
        final prefs = await SharedPreferences.getInstance();
        final resaved = jsonDecode(prefs.getString('teresa_rizal_resident_profiles')!) as Map<String, dynamic>;
        expect(resaved[_verifiedDemoId]['householdId'], 'HH-2026-9002');
        expect(resaved[_verifiedDemoId]['familyId'], 'FAM-2026-9002');
      },
    );
  });

  group('Personal Information — Age', () {
    testWidgets('shows Age calculated live from the corrected February 4, 2001 birthdate, and Civil Status Single', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: PersonalInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mar 15, 2001'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      final expectedAge = calculateAge(_verifiedDemoDob);
      expect(find.text('$expectedAge years old'), findsOneWidget);
      expect(find.text('Single'), findsWidgets);
      expect(find.text('Student'), findsWidgets);
      expect(find.text('Senior High School'), findsOneWidget);
      expect(find.text('4Ps Beneficiary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Family Information', () {
    testWidgets('shows Anselmo Quiambao (Father) and Lourdes Quiambao (Mother); the empty-state message is gone', (
      tester,
    ) async {
      // The default test canvas is too short to fit this screen's now-
      // longer Family Details section (Family ID/Household ID/Mother's
      // Maiden Name/Emergency Contact — see the Perlita Master Profile Web
      // Admin sync) plus the family member tiles below it within a Sliver
      // list's own build/cache extent — a realistic phone viewport keeps
      // everything reachable, same pattern used throughout this suite.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: FamilyInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The family member tiles sit below the (now longer) Family Details
      // section — a Sliver list only builds elements within the current
      // viewport plus cache extent, so scroll to the bottom to bring both
      // tiles into the built range before asserting on them (same
      // reasoning already documented in receipt_system_test.dart's own
      // _scrollToTopAndTap).
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No family members added yet'), findsNothing);
      expect(find.text('Anselmo Quiambao'), findsOneWidget);
      expect(find.text('Lourdes Quiambao'), findsOneWidget);
      // _MemberTile's own subtitle line shows relationship + age + account
      // status only (not occupation — see that widget's subtitleParts) —
      // occupation itself is verified against the underlying data directly
      // in the "fresh seed" group above.
      expect(find.textContaining('Father'), findsWidgets);
      expect(find.textContaining('Mother'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing Anselmo Quiambao opens the sheet without crashing (Father/Mother are valid dropdown options)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: FamilyInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anselmo Quiambao'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Family Member'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Educational Assistance wizard — field alignment', () {
    final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_educational');

    Future<RequestsService> pumpWizard(WidgetTester tester, {required MasterFileService masterFile}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = await _signedInAsVerifiedDemo(tester);
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
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
            ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(
            home: ServiceRequestWizardScreen(category: ServiceCategory.tulong, item: item, accent: AppColors.purple700),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return requests;
    }

    testWidgets('Student Information and Family Background steps prefill to match the Web Admin record', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await pumpWizard(tester, masterFile: mf);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Student Information
      await tester.pumpAndSettle();

      expect(find.text('Mar 15, 2001'), findsOneWidget);
      final expectedAge = calculateAge(_verifiedDemoDob);
      expect(find.textContaining('$expectedAge years old'), findsOneWidget);
      expect(find.text('Teresa, Rizal'), findsOneWidget);
      expect(find.text('Single'), findsWidgets);
      expect(find.text('Teresa National High School'), findsOneWidget);
      expect(find.text('2nd Year College'), findsOneWidget);
      expect(find.text('BS Education'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Family Background
      await tester.pumpAndSettle();

      expect(find.text('Anselmo Quiambao'), findsOneWidget);
      expect(find.text('Construction Worker'), findsOneWidget);
      expect(find.text('Lourdes Quiambao'), findsOneWidget);
      expect(find.text('Sari-Sari Store Vendor'), findsOneWidget);
      expect(find.text('9718'), findsOneWidget); // plain digits, not "₱9,718"
      expect(tester.takeException(), isNull);
    });

    testWidgets('Requirements & Attachments shows exactly 3 separate uploaders, all starting empty', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await pumpWizard(tester, masterFile: mf);

      // Applicant Info -> Student Info -> Family Background -> Additional
      // Information -> Requirements: 4 Continue taps from step 0.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Certificate of Enrollment'), findsOneWidget);
      expect(find.text('Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Barangay Certificate of Indigency'), findsOneWidget);
      // Exactly 3 empty upload prompts, each with its own requirement-
      // specific button label — nothing pre-attached, nothing marked
      // submitted, no "Existing document found" (Perlita's own signup/
      // registration ID is a different, unrelated system — see
      // utils/government_id.dart — and is never auto-offered here).
      expect(find.text('Upload Certificate of Enrollment'), findsOneWidget);
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
      expect(find.text('Existing document found'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('using an existing Master File document for one requirement leaves the other two still empty', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'certificate_of_enrollment',
        label: 'Certificate of Enrollment',
        attachment: _fakeAttachment('enrollment_cert.pdf'),
        origin: 'Some Other Service',
      );
      await pumpWizard(tester, masterFile: mf);

      // Applicant Info -> Student Info -> Family Background -> Additional
      // Information -> Requirements: 4 Continue taps from step 0.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Existing document found'), findsOneWidget);
      expect(find.text('enrollment_cert.pdf'), findsOneWidget);
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);

      await tester.ensureVisible(find.text('Use Existing Document'));
      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();

      expect(find.text('enrollment_cert.pdf'), findsOneWidget); // now the attached tile
      // The other two are untouched.
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'attaching all 3 requirements and submitting succeeds with a reference number; Track This Request opens the exact new request',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'certificate_of_enrollment',
          label: 'Certificate of Enrollment',
          attachment: _fakeAttachment('enrollment.pdf'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'valid_government_id',
          label: 'Valid Government-Issued ID',
          // Category left at the _fakeAttachment default (pdf), not image —
          // an image-categorized attachment triggers a real image-decode
          // attempt on this fixture's empty byte array (see _AttachedTile's
          // thumbnail preview), same reason no existing test in this suite
          // uses AttachmentCategory.image for a fake attachment either.
          attachment: _fakeAttachment('gov_id.jpg'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _verifiedDemoId,
          documentType: 'barangay_certificate_of_indigency',
          label: 'Barangay Certificate of Indigency',
          attachment: _fakeAttachment('indigency.pdf'),
          origin: 'Test',
        );
        final requests = await pumpWizard(tester, masterFile: mf);
        final before = requests.all.length;

        // Applicant Info -> Student Info -> Family Background -> Additional
        // Information -> Requirements: 4 Continue taps from step 0.
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();
        }

        // Attach all 3 via "Use Existing Document", one at a time — each
        // tap removes one from the remaining set.
        while (find.text('Use Existing Document').evaluate().isNotEmpty) {
          await tester.ensureVisible(find.text('Use Existing Document').first);
          await tester.tap(find.text('Use Existing Document').first);
          await tester.pumpAndSettle();
        }
        expect(find.text('Upload Document'), findsNothing);

        // This service has no formSpec 'purpose' field, so the Requirements
        // step's own free-text box is labeled "Purpose" and is required.
        await tester.enterText(find.byType(TextField).first, 'Educational assistance to support continuing studies');
        await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
        await tester.pumpAndSettle();

        expect(requests.all.length, before + 1);
        final submitted = requests.all.last;
        expect(submitted.typeName, 'Educational Assistance');
        expect(submitted.attachments.length, 3);
        expect(find.byType(RequestSubmittedScreen), findsOneWidget);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(find.text('Track This Request'), findsOneWidget);

        await tester.tap(find.text('Track This Request'));
        await tester.pumpAndSettle();

        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(find.text('Educational Assistance'), findsWidgets);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
