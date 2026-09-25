// Cluster 5 profile hub: Guest, Unverified, and Verified on the Servana
// shell, plus the Digital ID honesty panel.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/auth/login_screen.dart';
import 'package:teresa_rizal/screens/auth/register_screen.dart';
import 'package:teresa_rizal/screens/home/root_shell.dart';
import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/resident_id.dart';
import 'package:teresa_rizal/screens/profile/profile_screen.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:teresa_rizal/screens/profile/settings_screen.dart';
import 'package:teresa_rizal/screens/shared/documents_uploaded_screen.dart';
import 'package:teresa_rizal/screens/shared/my_requests_screen.dart';
import 'package:teresa_rizal/screens/shared/transactions_screen.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/widgets/digital_id_honesty.dart';
import 'package:teresa_rizal/widgets/guest_sign_in_gate.dart';
import 'package:teresa_rizal/widgets/soft_chrome.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_nav_item.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_services_action.dart';

const _shotKey = ValueKey('profile-hub-shot');

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

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

Future<CitizenSessionService> _session(
  WidgetTester tester, {
  CitizenAccount? account,
  bool guest = false,
}) async {
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
  if (account != null) {
    await session.login(account);
  } else if (guest) {
    await session.continueAsGuest();
  }
  return session;
}

Future<void> _pumpShell(
  WidgetTester tester,
  CitizenSessionService session,
) async {
  _phone(tester);
  await tester.runAsync(_loadShotFonts);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false),
          ),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const RootShell(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  final close = find.byIcon(Icons.close);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  await tester.tap(
    find.descendant(
      of: find.byType(TeresaRizalCurvedNavBar),
      matching: find.text('Profile'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['PROFILE_HUB_SHOTS'];
  if (dir == null || dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    if (image.width != 390 || image.height != 844) {
      throw StateError(
        '$name is ${image.width}x${image.height}, expected 390x844',
      );
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File('$dir/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
}

String _pillLabel(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('profile-status-pill')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}

void _expectHubChrome(WidgetTester tester, {String residentId = ResidentId.blank}) {
  final nav = tester.widget<TeresaRizalCurvedNavBar>(
    find.byType(TeresaRizalCurvedNavBar),
  );
  expect(nav.activeIndex, 3);
  expect(find.text('Home'), findsWidgets);
  expect(find.text('Balita'), findsWidgets);
  expect(find.text('Events'), findsWidgets);
  expect(find.text('Services'), findsWidgets);
  expect(find.text('Esperanza'), findsNothing);
  expect(find.text('Household & Family'), findsNothing);
  expect(find.text('Edit Profile'), findsNothing);
  expect(find.byIcon(Icons.edit_outlined), findsNothing);
  expect(find.text('ESP-RES-2024-9001'), findsNothing);
  expect(find.text('ESP-RES-2024-9002'), findsNothing);
  expect(
    find.descendant(
      of: find.byType(ProfileScreen),
      matching: find.byKey(const ValueKey('profile-resident-id')),
    ),
    findsOneWidget,
  );
  expect(
    tester.widget<Text>(find.byKey(const ValueKey('profile-resident-id'))).data,
    residentId,
  );
  expect(find.text('Resident profile'), findsOneWidget);
  expect(find.text('Settings'), findsOneWidget);
  expect(find.text('My requests'), findsOneWidget);
  expect(find.text('Transactions'), findsOneWidget);
  expect(find.text('Documents'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('digital-id-honesty'), skipOffstage: false),
    findsOneWidget,
  );
  expect(
    find.text(DigitalIdHonestyPanel.message, skipOffstage: false),
    findsOneWidget,
  );
  expect(find.text('Not a real government ID system'), findsOneWidget);

  final servicesIcon = tester.widget<Icon>(
    find.descendant(
      of: find.byType(TeresaRizalServicesAction),
      matching: find.byIcon(Icons.grid_view_rounded),
    ),
  );
  expect(servicesIcon.color, SoftColors.blue);
  final cradle = tester.widget<Container>(
    find.descendant(
      of: find.byType(TeresaRizalServicesAction),
      matching: find.byType(Container),
    ),
  );
  final cradleDecoration = cradle.decoration! as BoxDecoration;
  expect(cradleDecoration.color, SoftColors.blueSoft);
  expect(cradleDecoration.gradient, isNull);

  final bubble = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(TeresaRizalActiveBubble),
      matching: find.byType(DecoratedBox),
    ),
  );
  expect((bubble.decoration as BoxDecoration).color, SoftColors.blue);
}

void _expectOnScreen(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  final navTop = tester.getTopLeft(find.byType(TeresaRizalCurvedNavBar)).dy;
  expect(rect.top, greaterThan(0));
  expect(rect.bottom, lessThan(navTop));
}

Finder _profileScrollable() {
  return find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.byType(Scrollable),
  );
}

Future<void> _tapProfileLabel(WidgetTester tester, String label) async {
  final target = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.text(label),
  );
  await tester.scrollUntilVisible(target, 80, scrollable: _profileScrollable());
  await tester.pumpAndSettle();
  final navTop = tester.getTopLeft(find.byType(TeresaRizalCurvedNavBar)).dy;
  if (tester.getRect(target).bottom > navTop - 8) {
    await tester.drag(_profileScrollable(), const Offset(0, -48));
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _frameDocuments(WidgetTester tester) async {
  final documents = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.text('Documents'),
  );
  final navTop = tester.getTopLeft(find.byType(TeresaRizalCurvedNavBar)).dy;
  var guard = 0;
  while (tester.getRect(documents).bottom > navTop - 8 && guard < 8) {
    await tester.drag(_profileScrollable(), const Offset(0, -24));
    await tester.pumpAndSettle();
    guard++;
  }
  expect(tester.getRect(documents).bottom, lessThan(navTop - 4));
}

void main() {
  test('the hub does not print an internal account id as a resident id', () {
    final source = File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsStringSync();
    expect(source, contains('Account details '));
    expect(source, contains('account.profileCompleteness'));
    expect(source, isNot(contains('account.id')));
    expect(source, isNot(contains('Household & Family')));
    expect(source, isNot(contains('Esperanza')));
  });

  testWidgets('Guest profile leads with Sign In and Create Account', (
    tester,
  ) async {
    final session = await _session(tester, guest: true);
    await _pumpShell(tester, session);

    expect(find.text('Guest'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('profile-barangay'))).data,
      '—',
    );
    expect(_pillLabel(tester), 'Guest');
    expect(find.byKey(const ValueKey('profile-brand-seal')), findsNothing);
    _expectHubChrome(tester);
    await _frameDocuments(tester);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('profile-status-pill'))).top,
      greaterThan(0),
    );
    expect(tester.getRect(find.text('Sign In')).top, greaterThan(0));
    await _shot(tester, '01-guest-profile');

    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(LoginScreen))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Resident profile'));
    await tester.tap(find.text('Resident profile'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestSignInGate), findsOneWidget);
    expect(find.byType(ResidentProfileOverviewScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Unverified profile keeps Pending Review and a blank resident id',
    (tester) async {
      final nicanor = MockCatalog.demoAccounts.first;
      final session = await _session(tester, account: nicanor);
      await _pumpShell(tester, session);

      expect(find.text('Nicanor Sarmiento'), findsOneWidget);
      expect(find.text('Pending Review'), findsWidgets);
      expect(find.text('Verified'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('profile-barangay')))
            .data,
        'Labangtaytay',
      );
      expect(
        find.text('Account details ${nicanor.profileCompleteness}% complete'),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Municipal Government of Teresa'), findsOneWidget);
      expect(find.text('Official LGU seal · Rizal Province'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-brand-seal')), findsOneWidget);
      _expectHubChrome(tester);
      await _frameDocuments(tester);
      _expectOnScreen(tester, find.byKey(const ValueKey('profile-brand-seal')));
      _expectOnScreen(
        tester,
        find.byKey(const ValueKey('profile-status-pill')),
      );
      await _shot(tester, '02-unverified-profile');

      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Verified profile shows the Digital ID honesty panel', (
    tester,
  ) async {
    final perlita = MockCatalog.demoAccounts.last;
    final session = await _session(tester, account: perlita);
    await _pumpShell(tester, session);

    expect(find.text('Perlita Quiambao'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('profile-barangay'))).data,
      perlita.barangay,
    );
    expect(
      find.text('Account details ${perlita.profileCompleteness}% complete'),
      findsOneWidget,
    );
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('Municipal Government of Teresa'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-brand-seal')), findsOneWidget);
    _expectHubChrome(tester, residentId: ResidentId.verifiedSample);
    await _frameDocuments(tester);
    _expectOnScreen(tester, find.byKey(const ValueKey('profile-brand-seal')));
    _expectOnScreen(tester, find.byKey(const ValueKey('profile-status-pill')));
    await _shot(tester, '03-verified-profile');

    await _tapProfileLabel(tester, 'View demonstration');
    expect(find.byType(DigitalIdScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byType(SoftCircleButton), findsWidgets);
    expect(find.text('Resident Digital ID'), findsOneWidget);
    expect(find.text(ResidentId.verifiedSample), findsWidgets);
    final honesty = find.descendant(
      of: find.byType(DigitalIdScreen),
      matching: find.text('Not a real government ID'),
    );
    expect(honesty, findsOneWidget);
    await tester.scrollUntilVisible(honesty, 80);
    await tester.pumpAndSettle();
    expect(find.text('Barangay Resident ID'), findsNothing);
    await _shot(tester, '04-digital-id-honesty');

    Navigator.of(tester.element(find.byType(DigitalIdScreen))).pop();
    await tester.pumpAndSettle();
    await _tapProfileLabel(tester, 'My requests');
    expect(find.byType(MyRequestsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapProfileLabel(tester, 'Transactions');
    expect(find.byType(TransactionsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapProfileLabel(tester, 'Documents');
    expect(find.byType(DocumentsUploadedScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create Account from the guest hub opens registration', (
    tester,
  ) async {
    final session = await _session(tester, guest: true);
    await _pumpShell(tester, session);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
