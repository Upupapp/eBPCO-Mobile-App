// 390×844 review shots for Pack C. Inter is registered before the first
// frame. debugShowCheckedModeBanner is off. Inbox tiles are not the path
// into the notification frames — those land with openedFromNotification.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/balita/balita_post_detail_screen.dart';
import 'package:teresa_rizal/screens/events/event_detail_screen.dart';
import 'package:teresa_rizal/screens/shared/detail_chrome.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/theme/app_theme.dart';

Future<void> _loadShotFonts() async {
  final inter = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    final bytes = File(name).readAsBytesSync();
    inter.addFont(
      Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  }
  await inter.load();

  final icons = FontLoader('MaterialIcons');
  final iconBytes = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  icons.addFont(Future.value(iconBytes));
  await icons.load();
}

Widget _frame(Widget home) {
  return MultiProvider(
    key: UniqueKey(),
    providers: [
      ChangeNotifierProvider(create: (_) => CitizenSessionService()),
      ChangeNotifierProvider(create: (_) => BalitaService()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home,
    ),
  );
}

void main() {
  testWidgets('Pack C detail frames at 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(_loadShotFonts);

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      // Goldens are recorded on the Linux agent. macOS rasterises Inter
      // differently (identical frames measure ~6% apart), so the pixel compare runs
      // on Linux only; every other machine still walks the frames.
      if (!Platform.isLinux) return;
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/pack-c/$name.png'),
      );
    }

    Future<void> signIn() async {
      final perlita = MockCatalog.demoAccounts.firstWhere(
        (a) => a.firstName == 'Perlita',
      );
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(
        () => context.read<CitizenSessionService>().login(perlita),
      );
      await tester.pumpAndSettle();
    }

    final caravan = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan',
    );
    final past = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan-past',
    );

    await tester.pumpWidget(
      _frame(const BalitaPostDetailScreen(postId: balitaAmbulancePostId)),
    );
    await tester.pump();
    await signIn();
    await shot('balita_post_detail');

    await tester.pumpWidget(
      _frame(
        const BalitaPostDetailScreen(
          postId: balitaAmbulancePostId,
          openedFromNotification: true,
        ),
      ),
    );
    await tester.pump();
    await signIn();
    await shot('balita_post_detail_notif');

    final signedIn = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => signedIn.read<CitizenSessionService>().logout(),
    );
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      _frame(const BalitaPostDetailScreen(postId: balitaAmbulancePostId)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in to like & comment'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    await shot('balita_post_detail_guest');

    await tester.pumpWidget(_frame(EventDetailScreen(event: caravan)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isFalse,
    );
    await shot('event_detail');

    await tester.pumpWidget(
      _frame(EventDetailScreen(event: caravan, openedFromNotification: true)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isFalse,
    );
    await shot('event_detail_notif');

    await tester.pumpWidget(_frame(EventDetailScreen(event: past)));
    await tester.pumpAndSettle();
    expect(find.text('This event has ended'), findsOneWidget);
    await shot('event_detail_past');
  });
}
