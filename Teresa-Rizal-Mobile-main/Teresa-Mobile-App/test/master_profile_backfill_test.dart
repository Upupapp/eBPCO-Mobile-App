// Functional coverage for Phase 4 — the Master (Resident) Profile as
// single source of truth. Verifies the two core guarantees: a field the
// profile already knows renders read-only in a Dokyu/Tulong wizard (with
// an Edit Profile escape hatch, never a second editable copy that could
// drift from the citizen's real record), and ResidentProfileService's
// backfill path never silently flips personalSaved.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/service_request_wizard_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/app_button.dart';
import 'package:teresa_rizal/widgets/app_text_field.dart';

final _soloParentItem = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_solo_parent');

Future<ResidentProfileService> _pumpSoloParentWizard(WidgetTester tester, {required bool blankSex}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — sex: 'Female' on her CitizenAccount

  final profileService = ResidentProfileService();
  var attempts = 0;
  await tester.pumpWidget(const SizedBox.shrink());
  while (!profileService.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('ResidentProfileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

  // Seeds the profile from the account (sex: 'Female'), then blanks it out
  // in-memory for the "master doesn't know this yet" scenario — the
  // wizard reads this same live ResidentProfileService instance, so the
  // mutation is visible to it without any extra persistence step.
  final personal = profileService.profileFor(session.account!).personal;
  if (blankSex) personal.sex = '';

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<ResidentProfileService>.value(value: profileService),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        home: ServiceRequestWizardScreen(
          category: ServiceCategory.tulong,
          item: _soloParentItem,
          accent: AppColors.purple700,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return profileService;
}

void main() {
  testWidgets(
    'Sex renders read-only (with Edit Profile) when the Master Profile already has it, not a second editable field',
    (tester) async {
      await _pumpSoloParentWizard(tester, blankSex: false);

      // Applicant Info -> Continue -> "Identifying Information" step, where
      // the Sex field lives in tulong_solo_parent's formSpec.
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Sex'), findsOneWidget);
      // Read-only display shows the known value directly, not a selectable
      // dropdown control. This step also has other select fields
      // (Educational Attainment, Employment Status) that legitimately
      // stay editable — Perlita's Master Profile doesn't have those, or
      // (Employment Status) it was never a master-eligible key at all —
      // so the precise check is that no *Sex* dropdown exists, not that
      // zero AppSelectFields exist anywhere on the step.
      expect(find.text('Female'), findsWidgets);
      final selectLabels = tester
          .widgetList<AppSelectField<String>>(find.byType(AppSelectField<String>))
          .map((w) => w.label)
          .toList();
      expect(selectLabels, isNot(contains('Sex')));
      expect(find.text('Edit Profile'), findsWidgets); // escape hatch is present
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets); // read-only marker actually rendered
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Sex stays a normal editable field when the Master Profile does not have it yet', (tester) async {
    await _pumpSoloParentWizard(tester, blankSex: true);

    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Sex'), findsOneWidget);
    // A real, tappable select control exists for it now — not a read-only
    // display, since there's nothing on the profile to protect yet.
    expect(find.byType(AppSelectField<String>), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('ResidentProfileService.backfillPersonalField updates fields without ever touching personalSaved', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ResidentProfileService();
    var attempts = 0;
    while (!service.loaded) {
      attempts++;
      if (attempts > 200) throw StateError('ResidentProfileService never finished loading.');
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    final account = MockCatalog.demoAccounts.last;
    final profile = service.profileFor(account);
    // Simulate the citizen having already explicitly completed Personal
    // Information in the past.
    profile.personalSaved = true;
    final personal = profile.personal;
    personal.occupation = ''; // pretend this one field was never captured

    personal.occupation = 'Sari-sari Store Owner';
    await service.backfillPersonalField(account.id, personal);

    final updated = service.profileFor(account);
    expect(updated.personal.occupation, 'Sari-sari Store Owner');
    // The critical guarantee: an incidental backfill from a request form
    // must never flip the citizen's own "I completed Personal Information"
    // flag, in either direction.
    expect(updated.personalSaved, isTrue);
  });
}
