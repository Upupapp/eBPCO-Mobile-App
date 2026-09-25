// Coverage for the targeted Family Information update: Perlita's Emergency
// Contact section becomes editable (Name/Relationship/Contact Number), with
// Cancel/Save actions, sensible validation, and a migration-safe seeded
// default (Rogelio Escano / Brother / 0919 000 9012) that never overwrites
// a citizen's own saved edit on a later app launch. Family members
// (Anselmo/Lourdes Quiambao), Family ID, and Household ID are explicitly
// untouched by this feature — see the Perlita Master Profile Web Admin sync
// this builds on.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/profile/resident_profile/family_information_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/app_text_field.dart';

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

/// Pumps FamilyInformationScreen wired to the exact same [profiles]/
/// [session] instances the caller already holds — so later assertions
/// against those instances see whatever the widget actually saved, rather
/// than a second, unrelated ResidentProfileService that never received it.
Future<void> _pumpFamilyInfo(
  WidgetTester tester, {
  required CitizenSessionService session,
  required ResidentProfileService profiles,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<ResidentProfileService>.value(value: profiles),
      ],
      child: const MaterialApp(home: FamilyInformationScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(
    tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
  );
  await tester.pumpAndSettle();
}

Finder _fieldInput(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(TextField));

void main() {
  group('Display — seeded default', () {
    testWidgets('shows Rogelio Escano / Brother / 0919 000 9012 read-only, with an Edit action', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      expect(find.text('Emergency Contact'), findsOneWidget);
      expect(find.text('Rogelio Escano'), findsOneWidget);
      expect(find.text('Brother'), findsOneWidget);
      expect(find.text('0919 000 9012'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      // Not yet in edit mode — no editable text fields for this section.
      expect(find.widgetWithText(AppTextField, 'Name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Edit flow', () {
    testWidgets('tapping Edit shows real editable fields pre-filled with the current values, not hint text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppTextField, 'Name'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Relationship'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Contact number'), findsOneWidget);
      // The current values are real editable text, not placeholder/hint.
      expect(tester.widget<TextField>(_fieldInput('Name')).controller!.text, 'Rogelio Escano');
      expect(tester.widget<TextField>(_fieldInput('Relationship')).controller!.text, 'Brother');
      expect(tester.widget<TextField>(_fieldInput('Contact number')).controller!.text, '0919 000 9012');
      expect(find.widgetWithText(AppButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Save persists the new values and the screen immediately shows them', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(_fieldInput('Name'), 'Maria Escano');
      await tester.enterText(_fieldInput('Relationship'), 'Sister');
      await tester.enterText(_fieldInput('Contact number'), '0917 111 2222');
      await tester.pumpAndSettle();

      await _scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Maria Escano'), findsOneWidget);
      expect(find.text('Sister'), findsOneWidget);
      expect(find.text('0917 111 2222'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsNothing); // back to read-only

      final saved = profiles.profileFor(session.account!);
      expect(saved.emergencyContactName, 'Maria Escano');
      expect(saved.emergencyContactRelationship, 'Sister');
      expect(saved.emergencyContactNumber, '0917 111 2222');
      expect(saved.emergencyContactEdited, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cancel discards edits and restores the currently saved values', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(_fieldInput('Name'), 'Someone Else');
      await tester.pumpAndSettle();

      await _scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Someone Else'), findsNothing);
      expect(find.text('Rogelio Escano'), findsOneWidget);
      expect(find.text('Brother'), findsOneWidget);
      expect(find.text('0919 000 9012'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsNothing);
      expect(profiles.profileFor(session.account!).emergencyContactEdited, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('Validation', () {
    Future<void> openEditAndClearField(WidgetTester tester, String fieldLabel) async {
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldInput(fieldLabel), '');
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('empty Name blocks Save with an error, nothing is persisted', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await openEditAndClearField(tester, 'Name');

      expect(find.textContaining('name'), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget); // still in edit mode
      expect(profiles.profileFor(session.account!).emergencyContactEdited, isFalse);
    });

    testWidgets('empty Relationship blocks Save with an error', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await openEditAndClearField(tester, 'Relationship');

      expect(find.textContaining('relationship'), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);
    });

    testWidgets('empty Contact Number blocks Save with an error', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await openEditAndClearField(tester, 'Contact number');

      expect(find.textContaining('contact number'), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);
    });

    testWidgets('a malformed contact number blocks Save with a format error', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldInput('Contact number'), '12345');
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid mobile number'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);
    });

    testWidgets('a +63 formatted mobile number is accepted', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      await _pumpFamilyInfo(tester, session: session, profiles: profiles);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldInput('Contact number'), '+639171112222');
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Save'), findsNothing);
      expect(profiles.profileFor(session.account!).emergencyContactNumber, '+639171112222');
    });
  });

  group('Migration safety — a saved edit is never overwritten by the seeded default', () {
    testWidgets("after saving a custom emergency contact, a fresh app relaunch keeps the citizen's own value", (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final firstLaunchProfiles = await _readyProfiles(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      firstLaunchProfiles.profileFor(session.account!); // seeds the default first
      await firstLaunchProfiles.saveEmergencyContact(
        session.account!.id,
        name: 'Auntie Fely',
        relationship: 'Aunt',
        number: '0918 000 1111',
      );

      // Simulates relaunching the app — a brand-new service instance
      // reading from the same persisted SharedPreferences store, which is
      // exactly where the Perlita Master Profile alignment's own seeded
      // default would otherwise re-apply.
      final relaunchedProfiles = await _readyProfiles(tester);
      final relaunched = relaunchedProfiles.profileFor(session.account!);

      expect(relaunched.emergencyContactName, 'Auntie Fely');
      expect(relaunched.emergencyContactRelationship, 'Aunt');
      expect(relaunched.emergencyContactNumber, '0918 000 1111');
      expect(relaunched.emergencyContactEdited, isTrue);
    });

    testWidgets('a device that never edited the emergency contact still gets the seeded default on every load', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final profiles = await _readyProfiles(tester);
      final session = await _signedInAsVerifiedDemo(tester);
      final profile = profiles.profileFor(session.account!);

      expect(profile.emergencyContactName, 'Rogelio Escano');
      expect(profile.emergencyContactRelationship, 'Brother');
      expect(profile.emergencyContactNumber, '0919 000 9012');
      expect(profile.emergencyContactEdited, isFalse);
    });
  });

  group('Untouched by this feature', () {
    testWidgets('family members, Family ID, and Household ID are unaffected by editing the emergency contact', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      final profiles = await _readyProfiles(tester);
      profiles.profileFor(session.account!); // seeds the profile first
      await profiles.saveEmergencyContact(
        session.account!.id,
        name: 'Different Person',
        relationship: 'Neighbor',
        number: '0999 888 7777',
      );

      final profile = profiles.profileFor(session.account!);
      expect(profile.familyId, 'FAM-2026-9002');
      expect(profile.householdId, 'HH-2026-9002');
      final father = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Father');
      expect(father.fullName, 'Anselmo Quiambao');
      final mother = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Mother');
      expect(mother.fullName, 'Lourdes Quiambao');
      expect(mother.maidenName, 'Escano');
    });
  });

  group('Migration — resaving an old persisted profile', () {
    testWidgets(
      'a device that already persisted the seeded default under the old (pre-edit-feature) shape still shows it '
      'read-only with a working Edit action',
      (tester) async {
        // Represents a profile saved by an earlier build, before
        // emergencyContactEdited existed at all (defaults to false on
        // decode — see ResidentProfile.fromJson).
        final legacyJson = {
          'citizenAccountId': 'ESP-RES-2024-9002',
          'personal': {
            'individualId': 'ESP-RES-2024-9002',
            'firstName': 'Perlita',
            'lastName': 'Quiambao',
            'sex': 'Female',
            'birthdate': DateTime(2001, 3, 15).toIso8601String(),
            'civilStatus': 'Single',
            'mobile': '0919 000 9002',
            'barangay': 'Bagumbayan',
            'sitioPurok': 'Purok 2',
            'completeAddress': 'Purok 2, Barangay Bagumbayan, Teresa, Rizal',
            'occupation': 'Student',
            'householdId': 'HH-2026-9002',
          },
          'familyMembers': <Map<String, dynamic>>[],
          'familyName': 'Quiambao Family',
          'headIndividualId': 'ESP-RES-2024-9002',
          'familyId': 'FAM-2026-9002',
          'householdId': 'HH-2026-9002',
          'household': {'householdId': 'HH-2026-9002', 'barangay': 'Bagumbayan'},
          'personalSaved': true,
          'familySaved': true,
          'emergencyContactName': 'Rogelio Escano',
          'emergencyContactRelationship': 'Brother',
          'emergencyContactNumber': '0919 000 9012',
          // No 'emergencyContactEdited' key at all — simulates data saved
          // before this field existed.
        };
        SharedPreferences.setMockInitialValues({
          'teresa_rizal_resident_profiles': jsonEncode({'ESP-RES-2024-9002': legacyJson}),
        });

        final session = await _signedInAsVerifiedDemo(tester);
        final profiles = await _readyProfiles(tester);
        await _pumpFamilyInfo(tester, session: session, profiles: profiles);

        expect(find.text('Rogelio Escano'), findsOneWidget);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(AppTextField, 'Name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
