// Inbox chrome: content chips (guest hides Requests) and Pack E landings.
// Ambulance and Health Caravan still open the Pack C details.
// The flood advisory, evacuation update, and ended event leave this screen.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/balita/balita_post_detail_screen.dart';
import 'package:teresa_rizal/screens/balita/balita_screen.dart';
import 'package:teresa_rizal/screens/events/event_detail_screen.dart';
import 'package:teresa_rizal/screens/events/events_screen.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_landings.dart';
import 'package:teresa_rizal/screens/notifications/notifications_screen.dart';
import 'package:teresa_rizal/screens/shared/detail_chrome.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpInbox(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  _setPhoneViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(
          create: (_) => RequestsService(seedDemoData: false),
        ),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
  await tester.pumpAndSettle();
}

/// `Image.asset` stays a blank [RawImage] until the codec finishes.
/// Widget-test clocks do not finish that decode, so a `toImage` capture
/// taken right after `pumpAndSettle` paints the page wash through the
/// hero — the empty soft well. The signed-in shot only showed the
/// photograph because `runAsync` login let the same asset decode first.
Future<void> _resolveImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isEmpty) return;
  final context = tester.element(find.byType(Image).first);
  Object? failure;
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(
        image.image,
        context,
        onError: (exception, stackTrace) {
          failure ??= exception;
        },
      );
    }
  });
  await tester.pump();
  if (failure != null) {
    fail('Image failed to decode: $failure');
  }
}

void _expectAmbulanceAsset(WidgetTester tester) {
  final hero = tester.widget<Image>(
    find.byKey(const ValueKey('balita-ambulance-hero')),
  );
  final provider = hero.image;
  final asset = provider is AssetImage
      ? provider
      : (provider as ResizeImage).imageProvider as AssetImage;
  expect(asset.assetName, balitaAmbulanceAsset);
}

/// Guest, notification, and direct heroes all paint [balitaAmbulanceAsset].
/// Fails if the well is still the unresolved wash or the error colored box.
Future<void> _expectAmbulanceHeroPainted(WidgetTester tester) async {
  _expectAmbulanceAsset(tester);
  await _resolveImages(tester);
  final raw = find.descendant(
    of: find.byKey(const ValueKey('balita-ambulance-hero')),
    matching: find.byType(RawImage),
  );
  expect(raw, findsOneWidget);
  final decoded = tester.widget<RawImage>(raw).image;
  expect(decoded, isNotNull);
  expect(decoded!.width, greaterThan(8));
  expect(decoded.height, greaterThan(8));
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _resolveImages(tester);
  final dir = Platform.environment['INBOX_SHOTS_DIR'];
  if (dir == null || dir.isEmpty) return;
  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  await tester.pumpAndSettle();
  try {
    await tester.runAsync(() async {
      RenderRepaintBoundary? best;
      var bestArea = 0.0;
      for (final boundary in tester.renderObjectList<RenderRepaintBoundary>(
        find.byType(RepaintBoundary),
      )) {
        final size = boundary.size;
        final area = size.width * size.height;
        if (size.width >= 300 && size.height >= 700 && area > bestArea) {
          best = boundary;
          bestArea = area;
        }
      }
      final boundary =
          best ??
          tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = previousShadows;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await inter.load();
    // Widget screenshots otherwise paint Icon as an empty box.
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets(
    'filter chips narrow the inbox; only Event and Balita rows deep-link',
    (tester) async {
      await _pumpInbox(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Notification preferences'), findsNothing);
      expect(find.text('Sign in for personal alerts'), findsOneWidget);
      final filters = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('inbox-filters')),
      );
      expect(filters.scrollDirection, Axis.horizontal);
      expect(find.byKey(const ValueKey('inbox-filter-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('inbox-filter-requests')), findsNothing);
      expect(find.byKey(const ValueKey('inbox-filter-balita')), findsOneWidget);
      expect(find.byKey(const ValueKey('inbox-filter-events')), findsOneWidget);
      expect(find.byKey(const ValueKey('inbox-filter-advisories')), findsOneWidget);
      final allLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('inbox-filter-all')),
          matching: find.text('All'),
        ),
      );
      expect(allLabel.style?.color, SoftColors.white);
      expect(find.text('Heavy rain & flood advisory'), findsOneWidget);
      expect(find.text('Scholarship approved'), findsNothing);
      expect(find.text('Teresa Municipal Gym is open'), findsOneWidget);
      expect(
        find.text('New LGU Teresa ambulance for residents'),
        findsOneWidget,
      );
      expect(find.text('Health Caravan this Sunday'), findsOneWidget);
      await _shot(tester, '01-inbox-list');

      final balitaTile = find.byKey(
        const ValueKey('inbox-tile-sample-balita-ambulance'),
      );
      await tester.ensureVisible(balitaTile);
      await tester.pumpAndSettle();
      await tester.tap(balitaTile);
      await tester.pumpAndSettle();
      expect(find.byType(BalitaPostDetailScreen), findsOneWidget);
      expect(find.byType(EventsScreen), findsNothing);
      expect(find.byType(EventDetailScreen), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BalitaPostDetailScreen),
          matching: find.text('Opened from notification'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BalitaPostDetailScreen),
          matching: find.text('New LGU Teresa ambulance for residents'),
        ),
        findsOneWidget,
      );
      expect(find.text('Reading is open to guests'), findsOneWidget);
      expect(find.text('Sign in to like & comment'), findsOneWidget);
      expect(find.text('129'), findsNothing);
      await _expectAmbulanceHeroPainted(tester);
      await _shot(tester, '01-inbox-guest-balita-hero');
      await tester.tap(
        find.descendant(
          of: find.byType(BalitaPostDetailScreen),
          matching: find.byTooltip('Back'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.byType(BalitaPostDetailScreen), findsNothing);

      final eventTile = find.byKey(
        const ValueKey('inbox-tile-sample-event-health-caravan'),
      );
      await tester.ensureVisible(eventTile);
      await tester.pumpAndSettle();
      await tester.tap(eventTile);
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(find.byType(BalitaScreen), findsNothing);
      expect(find.byType(BalitaPostDetailScreen), findsNothing);
      expect(
        find.descendant(
          of: find.byType(EventDetailScreen),
          matching: find.text('Opened from notification'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(EventDetailScreen),
          matching: find.text('Health Caravan'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
        isFalse,
      );
      await _shot(tester, '03-inbox-tap-event-detail');
      await tester.tap(
        find.descendant(
          of: find.byType(EventDetailScreen),
          matching: find.byTooltip('Back'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.byType(EventDetailScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey('inbox-filter-advisories')));
      await tester.pumpAndSettle();
      expect(find.text('Heavy rain & flood advisory'), findsOneWidget);
      expect(find.text('Teresa Municipal Gym is open'), findsOneWidget);
      expect(find.text('Health Caravan this Sunday'), findsNothing);
      await _shot(tester, 'inbox_filter_advisories');

      final flood = find.byKey(
        const ValueKey('inbox-tile-sample-typhoon-advisory'),
      );
      final inboxScroll = find.descendant(
        of: find.byKey(const ValueKey('inbox-list')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(flood, 240, scrollable: inboxScroll);
      await tester.pumpAndSettle();
      await tester.tap(flood);
      await tester.pumpAndSettle();
      expect(find.byType(AdvisoryDetailPage), findsOneWidget);
      expect(find.text('Opened from notification'), findsOneWidget);
      expect(find.textContaining('Sample advisory, not a live alert.'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AdvisoryDetailPage),
          matching: find.byTooltip('Back'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('inbox-filter-all')));
      await tester.pumpAndSettle();
      final gym = find.byKey(
        const ValueKey('inbox-tile-sample-evacuation-update'),
      );
      await tester.scrollUntilVisible(gym, 240, scrollable: inboxScroll);
      await tester.pumpAndSettle();
      await tester.tap(gym);
      await tester.pumpAndSettle();
      expect(find.byType(EvacUpdatePage), findsOneWidget);
      expect(find.text('Map preview not available · text address only'), findsOneWidget);
      expect(find.byType(StaleDeepLinkPage), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(EvacUpdatePage),
          matching: find.byTooltip('Back'),
        ),
      );
      await tester.pumpAndSettle();

      final ended = find.byKey(const ValueKey('inbox-tile-sample-event-ended'));
      await tester.scrollUntilVisible(ended, 240, scrollable: inboxScroll);
      await tester.pumpAndSettle();
      await tester.tap(ended);
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(find.byType(StaleDeepLinkPage), findsNothing);
      expect(find.text('This event has ended'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signed-in inbox Balita detail paints the ambulance photograph', (
    tester,
  ) async {
    await _pumpInbox(tester);
    final perlita = MockCatalog.demoAccounts.firstWhere(
      (a) => a.firstName == 'Perlita',
    );
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => context.read<CitizenSessionService>().login(perlita),
    );
    await tester.pumpAndSettle();

    final balitaTile = find.byKey(
      const ValueKey('inbox-tile-sample-balita-ambulance'),
    );
    final inboxScroll = find.descendant(
      of: find.byKey(const ValueKey('inbox-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(balitaTile, 280, scrollable: inboxScroll);
    await tester.pumpAndSettle();
    await tester.tap(balitaTile);
    await tester.pumpAndSettle();

    expect(find.byType(BalitaPostDetailScreen), findsOneWidget);
    expect(find.text('Opened from notification'), findsOneWidget);
    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('Sign in to like & comment'), findsNothing);
    expect(find.text('Reading is open to guests'), findsNothing);
    expect(find.text('129'), findsOneWidget);
    expect(find.text('Comments · 24'), findsOneWidget);
    await _expectAmbulanceHeroPainted(tester);
    await _shot(tester, '02-inbox-notif-balita-hero');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ambulance hero and upcoming interest default off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    final caravan = MockCatalog.events.firstWhere(
      (e) => e.id == 'evt-health-caravan',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => BalitaService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const BalitaPostDetailScreen(postId: balitaAmbulancePostId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final perlita = MockCatalog.demoAccounts.firstWhere(
      (a) => a.firstName == 'Perlita',
    );
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => context.read<CitizenSessionService>().login(perlita),
    );
    await tester.pumpAndSettle();
    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('Opened from notification'), findsNothing);
    expect(find.text('Sign in to like & comment'), findsNothing);
    expect(find.text('129'), findsOneWidget);
    await _expectAmbulanceHeroPainted(tester);
    await _shot(tester, '03-balita-hero-signed-in');
    await _shot(tester, '04-balita-hero-ambulance');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: EventDetailScreen(event: caravan),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Opened from notification'), findsNothing);
    expect(find.text('Upcoming'), findsWidgets);
    expect(
      tester.widget<InterestToggle>(find.byType(InterestToggle)).on,
      isFalse,
    );
    await _shot(tester, '05-event-interested-off');
    expect(tester.takeException(), isNull);
  });
}
