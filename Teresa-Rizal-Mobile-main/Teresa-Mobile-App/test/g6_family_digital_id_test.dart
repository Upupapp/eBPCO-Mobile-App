// Pack F family / household / Digital ID, plus the Pack H keyboard rules
// on Add member.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/digital_id_card.dart';
import 'package:teresa_rizal/screens/profile/g6/g6_chrome.dart';
import 'package:teresa_rizal/screens/profile/g6/g6_sample.dart';
import 'package:teresa_rizal/screens/profile/g6/household_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/member_screens.dart';
import 'package:teresa_rizal/screens/profile/g6/resident_id.dart';
import 'package:teresa_rizal/screens/profile/profile_screen.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';

Future<CitizenSessionService> _session(
  WidgetTester tester,
  dynamic account,
) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) {
      throw StateError('CitizenSessionService never finished loading.');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }
  if (account != null) await session.login(account);
  return session;
}

Future<void> _loadInter() async {
  final inter = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    inter.addFont(rootBundle.load(name));
  }
  await inter.load();
}

void _phone(WidgetTester tester, {double inset = 0}) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _pumpId(
  WidgetTester tester,
  G6IdShot? shot, {
  bool reduce = false,
}) async {
  _phone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: reduce
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: DigitalIdScreen(shot: shot),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    DigitalIdFlipHint.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('flip swaps the face at 210ms of a 420ms easeInOutCubic turn', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pumpId(tester, G6IdShot.front);
    final state = tester.state<DigitalIdCardState>(find.byType(DigitalIdCard));
    expect(state.showingBack, isFalse);
    expect(find.byKey(const ValueKey('digital-id-flip-3d')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('digital-id-card')));
    await tester.pump();
    expect(state.linearT, 0);
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    await tester.pump(const Duration(milliseconds: 209));
    expect(state.showingBack, isFalse);
    expect(state.linearT, lessThan(0.5));

    await tester.pump(const Duration(milliseconds: 1));
    expect(state.showingBack, isTrue);
    expect(state.linearT, closeTo(0.5, 0.002));
    expect(kDigitalIdFlipCurve.transform(state.linearT), closeTo(0.5, 0.01));
    expect(find.bySemanticsLabel('Showing back of card'), findsOneWidget);
  });

  testWidgets('reduce motion crossfades in 150ms with no 3D rotation', (
    tester,
  ) async {
    await _pumpId(tester, G6IdShot.front, reduce: true);
    expect(find.byKey(const ValueKey('digital-id-flip-fade')), findsOneWidget);
    expect(find.byKey(const ValueKey('digital-id-flip-3d')), findsNothing);

    final state = tester.state<DigitalIdCardState>(find.byType(DigitalIdCard));
    expect(state.reduceMotion, isTrue);
    await tester.tap(find.byKey(const ValueKey('digital-id-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 74));
    expect(state.linearT, lessThan(0.5));
    expect(state.showingBack, isFalse);
    await tester.pump(const Duration(milliseconds: 76));
    expect(state.showingBack, isTrue);
    expect(state.linearT, closeTo(1, 0.02));
    expect(find.byKey(const ValueKey('digital-id-flip-3d')), findsNothing);
  });

  testWidgets('household members have no Digital ID card', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: G6MemberDetailScreen(member: G6Sample.jose),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DigitalIdCard), findsNothing);
    expect(find.text('Resident Digital ID'), findsNothing);
    expect(find.text('New request for Jose'), findsWidgets);

    await tester.tap(find.widgetWithText(G6Button, 'New request for Jose'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceCatalogScreen), findsOneWidget);
  });

  testWidgets('hub row and card share TR-SAMPLE-000412 for the verified demo', (
    tester,
  ) async {
    final session = await _session(tester, MockCatalog.demoAccounts.last);
    _phone(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false),
          ),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final hub = tester
        .widget<Text>(find.byKey(const ValueKey('profile-resident-id')))
        .data;
    expect(hub, ResidentId.verifiedSample);

    await tester.pumpWidget(
      ChangeNotifierProvider<CitizenSessionService>.value(
        value: session,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DigitalIdScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('digital-id-resident-id')))
          .data,
      hub,
    );
    expect(find.text('SAMPLE'), findsOneWidget);
  });

  testWidgets('unverified hub and card id are an em dash', (tester) async {
    final session = await _session(tester, MockCatalog.demoAccounts.first);
    _phone(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false),
          ),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('profile-resident-id')))
          .data,
      ResidentId.blank,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SizedBox(
          width: 358,
          height: 226,
          child: DigitalIdCard(
            data: DigitalIdData.forAccount(
              holderName: 'Nicanor Sarmiento',
              barangay: 'Labangtaytay',
              address: 'Sample',
              verified: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('digital-id-resident-id')))
          .data,
      ResidentId.blank,
    );
    expect(find.text('SAMPLE'), findsNothing);
    expect(find.text(ResidentId.verifiedSample), findsNothing);
  });

  testWidgets('household card has Barangay and Members and no Household ID', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const G6HouseholdScreen(populated: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Household ID'), findsNothing);
    expect(find.textContaining('HH-SAMPLE'), findsNothing);
    expect(find.text('Barangay'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Dalig'), findsWidgets);
  });

  testWidgets('Add member is a pushed route, not a sheet', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const G6HouseholdScreen(populated: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('g6-add-member-cta')));
    await tester.tap(find.byKey(const ValueKey('g6-add-member-cta')));
    await tester.pumpAndSettle();
    expect(find.byType(G6AddMemberScreen), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(G6AddMemberScreen)));
    expect(route, isA<MaterialPageRoute<dynamic>>());
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Hakbang 1 · Member details'), findsOneWidget);
    expect(find.textContaining('Step '), findsNothing);
  });

  testWidgets(
    'Add member footer rides the IME, header stays pinned, next opens the picker',
    (tester) async {
      await tester.runAsync(_loadInter);
      _phone(tester, inset: 336);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const G6AddMemberScreen(keyboardFrame: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isTrue);

      final screen = 844.0;
      final footer = tester.getRect(
        find.byKey(const ValueKey('g6-member-footer')),
      );
      final field = tester.getRect(
        find.byKey(const ValueKey('g6-member-name')),
      );
      final head = tester.getRect(
        find.byKey(const ValueKey('g6-member-pinned-head')),
      );
      final gap = footer.top - field.bottom;

    expect(footer.bottom, closeTo(screen - 336, 1));
    expect(gap, greaterThanOrEqualTo(16), reason: 'measured gap $gap');
    expect(gap, closeTo(38, 4), reason: 'measured gap $gap');
      expect(head.bottom, lessThan(field.top));
      expect(find.text('Hakbang 1 · Member details'), findsOneWidget);
      expect(find.text('Spouse'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      final headTop = head.top;
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('g6-member-pinned-head'))).top,
        headTop,
      );

      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('g6-member-name')),
      );
      expect(nameField.keyboardType, TextInputType.name);
      expect(nameField.textCapitalization, TextCapitalization.words);
      expect(nameField.textInputAction, TextInputAction.next);
      expect(nameField.scrollPadding.bottom, greaterThanOrEqualTo(16));

      await tester.showKeyboard(find.byKey(const ValueKey('g6-member-name')));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('g6-member-name')))
            .focusNode!
            .hasFocus,
        isFalse,
      );
    },
  );
}
