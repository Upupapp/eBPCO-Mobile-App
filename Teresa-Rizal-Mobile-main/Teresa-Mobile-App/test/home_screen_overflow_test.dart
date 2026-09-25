// Regression test for the dashboard-card/section-header overflow bugs:
// renders HomeScreen at a spread of real device widths/heights and text
// scale factors, and asserts no RenderFlex/overflow exceptions were thrown
// during layout — the class of bug that a static childAspectRatio number
// or an un-Flexible Row can silently reintroduce later.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/home/home_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

void main() {
  final sizes = <String, Size>{
    'extreme narrow (280x568, old small Android)': const Size(280, 568),
    'small (320x568, iPhone SE class)': const Size(320, 568),
    'normal (360x800, common Android)': const Size(360, 800),
    'large (412x915, Pixel class)': const Size(412, 915),
    'tall narrow (360x1000)': const Size(360, 1000),
    'wide (600x1000, small tablet)': const Size(600, 1000),
  };

  for (final entry in sizes.entries) {
    for (final textScale in [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('HomeScreen has zero overflow at ${entry.key}, textScale $textScale', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final session = CitizenSessionService();
        final account = MockCatalog.demoAccounts.first;
        await session.login(account);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CitizenSessionService>.value(value: session),
              ChangeNotifierProvider<RequestsService>(create: (_) => RequestsService()),
              ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
              ChangeNotifierProvider<NotificationsService>(create: (_) => NotificationsService()),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
