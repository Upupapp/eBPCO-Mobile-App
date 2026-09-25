// Regression test for RenderFlex/overflow on the new Resident Profile
// screens — same technique as home_screen_overflow_test.dart and
// post_composer_overflow_test.dart: render each screen at a spread of
// device widths/heights and text scales, assert zero layout exceptions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/resident_profile.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/family_information_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/household_information_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/review_submit_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/submission_confirmation_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/widgets/resident_profile_status_card.dart';

void main() {
  final sizes = <String, Size>{
    'extreme narrow (280x568)': const Size(280, 568),
    'small (320x568)': const Size(320, 568),
    'normal (360x800)': const Size(360, 800),
    'large (412x915)': const Size(412, 915),
  };

  final screens = <String, Widget Function()>{
    'ResidentProfileOverviewScreen': () => const ResidentProfileOverviewScreen(),
    'PersonalInformationScreen': () => const PersonalInformationScreen(),
    'FamilyInformationScreen': () => const FamilyInformationScreen(),
    'HouseholdInformationScreen': () => const HouseholdInformationScreen(),
    'ReviewSubmitScreen': () => const ReviewSubmitScreen(),
    'SubmissionConfirmationScreen': () => const SubmissionConfirmationScreen(),
  };

  for (final screenEntry in screens.entries) {
    for (final sizeEntry in sizes.entries) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
          '${screenEntry.key} has zero overflow at ${sizeEntry.key}, textScale $textScale',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            tester.view.physicalSize = sizeEntry.value;
            tester.view.devicePixelRatio = 1.0;
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

            final session = CitizenSessionService();
            await session.login(MockCatalog.demoAccounts.first);

            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<CitizenSessionService>.value(value: session),
                  ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
                ],
                child: MaterialApp(home: screenEntry.value()),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  // ResidentProfileStatusCard is shared by Home and Profile but its
  // pending/needsCorrection/verified states are never reached by the
  // freshly-seeded profile used in the screen tests above — cover them
  // directly, at the narrowest width, since it's the same Row-based
  // structure that was the actual source of the bugs fixed in this file.
  final statuses = <String, VerificationStatus>{
    'incomplete': VerificationStatus.incomplete,
    'pendingVerification': VerificationStatus.pendingVerification,
    'needsCorrection': VerificationStatus.needsCorrection,
    'verified': VerificationStatus.verified,
  };

  for (final statusEntry in statuses.entries) {
    testWidgets('ResidentProfileStatusCard has zero overflow in ${statusEntry.key} state at extreme narrow width', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(280, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final account = MockCatalog.demoAccounts.first;
      final profile = ResidentProfile.seedFrom(account)
        ..status = statusEntry.value
        ..correctionMessage = 'Please provide your complete Sitio / Purok.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ResidentProfileStatusCard(profile: profile, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
