import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/balita/balita_post_detail_screen.dart';
import 'package:teresa_rizal/screens/balita/balita_screen.dart';
import 'package:teresa_rizal/screens/events/event_detail_screen.dart';
import 'package:teresa_rizal/screens/events/events_screen.dart';
import 'package:teresa_rizal/screens/shared/detail_chrome.dart';
import 'package:teresa_rizal/screens/shared/event_poster_viewer.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/widgets/restricted_feature_notice.dart';

Widget _app(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CitizenSessionService()),
      ChangeNotifierProvider(
        create: (_) => RequestsService(
          seedDemoData: false,
          retireLegacyDemoRequestSeeds: true,
        ),
      ),
      ChangeNotifierProvider(create: (_) => BalitaService()),
      ChangeNotifierProvider(create: (_) => ResidentProfileService()),
      ChangeNotifierProvider(create: (_) => MasterFileService()),
      ChangeNotifierProvider(create: (_) => NotificationsService()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home,
    ),
  );
}

Future<void> _signInPerlita(WidgetTester tester) async {
  final perlita = MockCatalog.demoAccounts.firstWhere(
    (a) => a.firstName == 'Perlita',
  );
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(
    () => context.read<CitizenSessionService>().login(perlita),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  void usePhone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder textWidget(String data) {
    return find.byWidgetPredicate((w) => w is Text && w.data == data);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(finder, 280, scrollable: scrollable);
    await tester.pumpAndSettle();
  }

  testWidgets('signed-in ambulance detail shows social counts and comments', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(
      _app(const BalitaPostDetailScreen(postId: balitaAmbulancePostId)),
    );
    await tester.pumpAndSettle();
    await _signInPerlita(tester);

    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('129'), findsOneWidget);
    expect(find.text('Comments · 24'), findsOneWidget);
    expect(
      find.text('Salamat po, Mayor. Useful for emergencies.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Local preview sample — not a live dispatch feed.'),
      findsOneWidget,
    );
    expect(find.text('Opened from notification'), findsNothing);
    expect(find.byType(OpenedFromNotificationEyebrow), findsNothing);
    expect(find.text('Sign in to like & comment'), findsNothing);
  });

  testWidgets(
    'notification landing adds the eyebrow and does not use the inbox',
    (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        _app(
          const BalitaPostDetailScreen(
            postId: balitaAmbulancePostId,
            openedFromNotification: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _signInPerlita(tester);
      expect(find.text('Opened from notification'), findsOneWidget);
      expect(find.byType(OpenedFromNotificationEyebrow), findsOneWidget);
    },
  );

  testWidgets('guest reading stays open with an inline sign-in gate', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(
      _app(const BalitaPostDetailScreen(postId: balitaAmbulancePostId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('Reading is open to guests'), findsOneWidget);
    expect(
      find.textContaining(
        'Guests may read; liking and commenting need an account.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in to like & comment'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(find.byType(RestrictedFeatureNotice), findsNothing);
    expect(find.text('Comments · 24'), findsNothing);
  });

  testWidgets('upcoming Health Caravan detail keeps calendar honesty', (
    tester,
  ) async {
    usePhone(tester);
    final event = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan',
    );
    await tester.pumpWidget(_app(EventDetailScreen(event: event)));
    await tester.pumpAndSettle();

    expect(find.text('Health Caravan'), findsOneWidget);
    expect(find.text('Poster · asset pending'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text("I'm interested"), findsOneWidget);
    expect(
      find.text('Interest is local preview — not ticketed registration'),
      findsOneWidget,
    );
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('interest-toggle')));
    await tester.pump();
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isTrue,
    );
    await scrollTo(
      tester,
      find.text(
        'Opens device calendar / local preview — not a live LGU booking.',
      ),
    );
    expect(
      find.text(
        'Opens device calendar / local preview — not a live LGU booking.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Poblacion · text address only — no map tiles'),
      findsOneWidget,
    );
    expect(find.text('Opened from notification'), findsNothing);
  });

  testWidgets('notification event landing shows the eyebrow', (tester) async {
    usePhone(tester);
    final event = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan',
    );
    await tester.pumpWidget(
      _app(EventDetailScreen(event: event, openedFromNotification: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Opened from notification'), findsOneWidget);
    expect(find.text('Poster · asset pending'), findsOneWidget);
  });

  testWidgets('past Health Caravan disables RSVP and calendar', (tester) async {
    usePhone(tester);
    final event = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan-past',
    );
    await tester.pumpWidget(_app(EventDetailScreen(event: event)));
    await tester.pumpAndSettle();

    expect(find.text('This event has ended'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    expect(find.text('Past event · muted wash'), findsOneWidget);
    await scrollTo(tester, find.byType(InterestToggle));
    expect(find.text('RSVP disabled — event has ended'), findsOneWidget);
    final toggle = tester.widget<InterestToggle>(find.byType(InterestToggle));
    expect(toggle.enabled, isFalse);
    expect(toggle.on, isFalse);
    final calendar = tester.widget<DetailPillButton>(
      find.byKey(const Key('add-to-calendar')),
    );
    expect(calendar.onPressed, isNull);

    await tester.tap(find.byKey(const Key('interest-toggle')));
    await tester.pump();
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isFalse,
    );
  });

  testWidgets('Balita hub card opens the post detail', (tester) async {
    usePhone(tester, size: const Size(390, 1400));

    await tester.pumpWidget(_app(const BalitaScreen()));
    await tester.pumpAndSettle();
    // The hub lead is the social still (`bal-lgu-ambulance`). Pack C detail
    // is the later sample (`bal-ambulance`).
    final card = find.byKey(const ValueKey('bal-ambulance'));
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('balita-feed')),
      matching: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(card, 400, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: card,
        matching: textWidget('New LGU Teresa ambulance for residents'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BalitaPostDetailScreen), findsOneWidget);
    expect(find.text('Municipality of Teresa'), findsWidgets);
  });

  testWidgets(
    'Events hub card opens event detail and View poster stays a poster',
    (tester) async {
      usePhone(tester, size: const Size(390, 900));

      await tester.pumpWidget(_app(const EventsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View poster').first);
      await tester.pumpAndSettle();
      expect(find.byType(EventPosterViewer), findsOneWidget);
      expect(find.byType(EventDetailScreen), findsNothing);

      Navigator.of(tester.element(find.byType(EventPosterViewer))).pop();
      await tester.pumpAndSettle();

      final title = textWidget('Health Caravan');
      await scrollTo(tester, title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(
        find.text('Sun, Oct 5, 2026 · 8:00 AM – 12:00 PM'),
        findsOneWidget,
      );
    },
  );
}
