import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/events/event_detail_screen.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_chrome.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_landings.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_link.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_routes.dart';
import 'package:teresa_rizal/screens/notifications/notifications_screen.dart';
import 'package:teresa_rizal/screens/requests/pack_d/pack_d_frame.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/widgets/soft_chrome.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: home,
  );
}

Future<void> _pumpGuestInbox(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  _phone(tester);
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
      child: _app(const NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ended event notification opens the past-event page', (
    tester,
  ) async {
    await _pumpGuestInbox(tester);
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('inbox-list')),
      matching: find.byType(Scrollable),
    );
    final ended = find.byKey(const ValueKey('inbox-tile-sample-event-ended'));
    await tester.scrollUntilVisible(ended, 280, scrollable: scroll);
    await tester.pumpAndSettle();
    await tester.tap(ended);
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.byType(StaleDeepLinkPage), findsNothing);
    expect(find.text('This event has ended'), findsOneWidget);
    expect(find.text('Past'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing event id opens the stale deep link', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => G5Routes.openEventById(context, 'evt-missing'),
            child: const Text('Open missing'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open missing'));
    await tester.pumpAndSettle();
    expect(find.byType(StaleDeepLinkPage), findsOneWidget);
    expect(find.byType(EventDetailScreen), findsNothing);
    expect(find.text('This update is no longer available'), findsOneWidget);
  });

  testWidgets(
    'correction landing disables Resubmit; Pack D detail keeps it enabled',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const CorrectionFocusPage()));
      await tester.pumpAndSettle();
      final gated = tester.widget<G5Button>(
        find.byKey(const ValueKey('g5-resubmit')),
      );
      expect(gated.onPressed, isNull);
      expect(
        find.text('Replace the flagged Valid ID to enable Resubmit'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _app(
          PackDFrameScreen(
            frame: PackDFrame.correction,
            onBack: () {},
            onGo: (_) {},
            onSex: (_) {},
            onPayMethod: (_) {},
            onOpenSettings: () {},
            onViewReceipt: () {},
            onCancelRequest: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final live = tester.widget<SoftPillButton>(
        find.widgetWithText(SoftPillButton, 'Resubmit'),
      );
      expect(live.onPressed, isNotNull);
    },
  );

  testWidgets('guest chips exclude Requests', (tester) async {
    await _pumpGuestInbox(tester);
    expect(find.byKey(const ValueKey('inbox-filter-requests')), findsNothing);
    expect(find.byKey(const ValueKey('inbox-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-filter-balita')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-filter-events')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inbox-filter-advisories')),
      findsOneWidget,
    );
    expect(find.text('Scholarship approved'), findsNothing);
    expect(find.text('Barangay clearance needs correction'), findsNothing);
    expect(find.text('Heavy rain & flood advisory'), findsOneWidget);
  });

  testWidgets('guest personal link opens the gate and hides the payout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _phone(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false),
          ),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => G5Routes.follow(context, G5Link.scholarship),
              child: const Text('Open scholarship'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open scholarship'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestGatePage), findsOneWidget);
    expect(find.byType(TulongApprovedPage), findsNothing);
    expect(find.text('Sign in to open this update'), findsOneWidget);
    expect(find.textContaining('₱5,000.00'), findsNothing);
    expect(find.text('TR-TUL-0917'), findsNothing);
  });

  testWidgets('MDRRMO hotline stays disabled and 911 stays callable', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(const AdvisoryDetailPage(hotlineOpen: true)));
    await tester.pumpAndSettle();
    final emergency = tester.widget<G5CallPill>(
      find.byKey(const ValueKey('g5-call-911')),
    );
    final local = tester.widget<G5CallPill>(
      find.byKey(const ValueKey('g5-call-mdrrmo')),
    );
    expect(emergency.enabled, isTrue);
    expect(emergency.onPressed, isNotNull);
    expect(local.enabled, isFalse);
    expect(local.onPressed, isNull);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Not yet available'), findsOneWidget);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('g5-hotline-mdrrmo')),
          )
          .ignoring,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('g5-call-mdrrmo')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(find.text('MDRRMO Teresa'), findsOneWidget);
    expect(find.text('[TO BE PROVIDED]'), findsOneWidget);
    expect(find.textContaining('No invented numbers.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in scholarship sample opens the approved landing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _phone(tester);
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
        child: _app(const NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final perlita = MockCatalog.demoAccounts.firstWhere(
      (a) => a.firstName == 'Perlita',
    );
    final context = tester.element(find.byType(NotificationsScreen));
    await tester.runAsync(
      () => context.read<CitizenSessionService>().login(perlita),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-filter-requests')), findsOneWidget);
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('inbox-list')),
      matching: find.byType(Scrollable),
    );
    final tile = find.byKey(
      const ValueKey('inbox-tile-sample-educational-assistance'),
    );
    await tester.scrollUntilVisible(tile, 280, scrollable: scroll);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(TulongApprovedPage), findsOneWidget);
    expect(find.byType(GuestGatePage), findsNothing);
    expect(find.textContaining('₱5,000.00'), findsOneWidget);
    expect(find.textContaining('Not live assistance funds.'), findsOneWidget);
  });
}
