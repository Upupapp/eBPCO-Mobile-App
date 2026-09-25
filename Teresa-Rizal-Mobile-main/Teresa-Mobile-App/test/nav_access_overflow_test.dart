// Regression coverage for the nav/access-control feature set: Guest-mode
// Home (a materially different Hero layout from the signed-in path the
// existing home_screen_overflow_test.dart covers), the registration/
// verification wizard, RestrictedFeatureNotice, and MagneticNavbarCore
// (the bottom nav). Same technique as the other *_overflow_test.dart
// files: render at a spread of widths/text-scales, assert zero exceptions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/screens/auth/register_screen.dart';
import 'package:teresa_rizal/screens/home/home_screen.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';
import 'package:teresa_rizal/widgets/nav_item_data.dart';
import 'package:teresa_rizal/widgets/restricted_feature_notice.dart';

void main() {
  final sizes = <String, Size>{
    'extreme narrow (280x568)': const Size(280, 568),
    'small (320x568)': const Size(320, 568),
    'normal (360x800)': const Size(360, 800),
    'large (412x915)': const Size(412, 915),
  };

  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size,
    double textScale,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  MultiProvider providers({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: child),
    );
  }

  for (final sizeEntry in sizes.entries) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'Guest HomeScreen has zero overflow at ${sizeEntry.key}, textScale $textScale',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          await pumpAtSize(
            tester,
            sizeEntry.value,
            textScale,
            providers(child: const HomeScreen()),
          );
          // No session.continueAsGuest() call needed: with no stored session
          // and no login, CitizenSessionService starts signed-out; HomeScreen
          // must render its Guest branch instead of crashing on `account!`.
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'RegisterScreen (fresh, step 1) has zero overflow at ${sizeEntry.key}, textScale $textScale',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          await pumpAtSize(
            tester,
            sizeEntry.value,
            textScale,
            providers(child: const RegisterScreen()),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TeresaRizalCurvedNavBar (4 branches, Events active) has zero overflow at ${sizeEntry.key}, textScale $textScale',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          await pumpAtSize(
            tester,
            sizeEntry.value,
            textScale,
            MaterialApp(
              home: Scaffold(
                body: const SizedBox(),
                bottomNavigationBar: TeresaRizalCurvedNavBar(
                  activeIndex: 2,
                  onTabSelected: (_) {},
                  onCenterPressed: () {},
                  items: const [
                    NavItemData(
                      outlineIcon: Icons.home_outlined,
                      filledIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    NavItemData(
                      outlineIcon: Icons.campaign_outlined,
                      filledIcon: Icons.campaign_rounded,
                      label: 'Balita',
                    ),
                    NavItemData(
                      outlineIcon: Icons.event_outlined,
                      filledIcon: Icons.event_rounded,
                      label: 'Events',
                    ),
                    NavItemData(
                      outlineIcon: Icons.person_outline_rounded,
                      filledIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TeresaRizalCurvedNavBar (4 branches, Profile active) has zero overflow at ${sizeEntry.key}, textScale $textScale',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          await pumpAtSize(
            tester,
            sizeEntry.value,
            textScale,
            MaterialApp(
              home: Scaffold(
                body: const SizedBox(),
                bottomNavigationBar: TeresaRizalCurvedNavBar(
                  activeIndex: 3,
                  onTabSelected: (_) {},
                  onCenterPressed: () {},
                  items: const [
                    NavItemData(
                      outlineIcon: Icons.home_outlined,
                      filledIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    NavItemData(
                      outlineIcon: Icons.campaign_outlined,
                      filledIcon: Icons.campaign_rounded,
                      label: 'Balita',
                    ),
                    NavItemData(
                      outlineIcon: Icons.event_outlined,
                      filledIcon: Icons.event_rounded,
                      label: 'Events',
                    ),
                    NavItemData(
                      outlineIcon: Icons.person_outline_rounded,
                      filledIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final reason in RestrictionReason.values) {
    testWidgets(
      'RestrictedFeatureNotice ($reason) has zero overflow at extreme narrow width',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await pumpAtSize(
          tester,
          const Size(280, 568),
          1.3,
          providers(
            child: RestrictedFeatureNotice(
              reason: reason,
              featureName: 'Tulong (Assistance Requests)',
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'RegisterScreen jumps straight to Verification for an already-signed-in account, no overflow',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      await session.login(
        MockCatalog.demoAccounts.first,
      ); // Nicanor — Pending Review
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => RequestsService()),
            ChangeNotifierProvider(create: (_) => BalitaService()),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Verification'),
        findsOneWidget,
      ); // AppBar title for the status-only path
      expect(
        find.text('Pending Review'),
        findsOneWidget,
      ); // StatusChip inside VerificationStatusPanel
    },
  );

  test('AccessLevel ordering supports "at least" comparisons via .index', () {
    expect(AccessLevel.guest.index < AccessLevel.unverified.index, isTrue);
    expect(AccessLevel.unverified.index < AccessLevel.verified.index, isTrue);
  });
}
