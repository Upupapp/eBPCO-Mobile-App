// Promotional dialog chrome: portrait shell, empty poster, five bodies.
//
// Home, Balita, Events, Dokyu, and Tulong each show the shell once per
// session. Emergency does not. The poster is a dashed slot — no PNG.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/home/root_shell.dart';
import 'package:teresa_rizal/services/balita_service.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';
import 'package:teresa_rizal/widgets/home_welcome_banner.dart';
import 'package:teresa_rizal/widgets/promotional_banner_dialog.dart';
import 'package:teresa_rizal/widgets/service_launcher_menu.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// `flutter test` ships Ahem, which paints every glyph as a block. SoftType
/// asks for Inter, and the close control asks for MaterialIcons. Register both
/// before the first frame or the shots are .notdef bars and a square box.
Future<void> _loadShotFonts() async {
  final inter = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    final bytes = File(name).readAsBytesSync();
    inter.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await inter.load();

  final icons = FontLoader('MaterialIcons');
  final iconBytes = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  icons.addFont(Future.value(iconBytes));
  await icons.load();
}

Future<void> _pumpShell(WidgetTester tester, {CitizenAccount? account}) async {
  SharedPreferences.setMockInitialValues({});
  _phone(tester);
  await tester.runAsync(_loadShotFonts);
  final session = CitizenSessionService();
  if (account != null) await session.login(account);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('promo-dialog-shot'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(
            create: (_) => RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
          ),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: RootShell.withKey(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['PROMO_DIALOG_SHOTS'];
  if (dir == null || dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('promo-dialog-shot')),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    if (image.width != 390 || image.height != 844) {
      throw StateError('$name is ${image.width}x${image.height}, expected 390x844');
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File('$dir/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
}

void _expectEmptyShell(WidgetTester tester, String label) {
  final dialog = find.byType(PromotionalBannerDialog);
  expect(find.descendant(of: dialog, matching: find.byType(PromoPosterPlaceholder)), findsOneWidget);
  expect(find.descendant(of: dialog, matching: find.text(label)), findsOneWidget);
  expect(find.descendant(of: dialog, matching: find.text('Poster slot')), findsOneWidget);
  expect(
    find.descendant(of: find.byType(PromotionalBannerDialog), matching: find.byType(Image)),
    findsNothing,
  );

  final clip = tester.widget<ClipRRect>(
    find.descendant(
      of: find.byType(PromotionalBannerDialog),
      matching: find.byType(ClipRRect),
    ),
  );
  expect(clip.borderRadius, BorderRadius.circular(20));

  final poster = tester.getRect(find.byType(PromoPosterPlaceholder));
  expect(poster.width, lessThanOrEqualTo(390 * 0.94 + 0.01));
  expect(poster.height, lessThanOrEqualTo(844 * 0.90 + 0.01));
  expect(poster.width / poster.height, closeTo(2 / 3, 0.01));

  final close = tester.getRect(find.byTooltip('Close $label banner'));
  expect(close.width, 44);
  expect(close.height, 44);
  expect(close.right, closeTo(poster.right + 14, 0.5));
  expect(close.top, closeTo(poster.top - 14, 0.5));

  // ignore: deprecated_member_use
  final expectedBarrier = Colors.black.withOpacity(0.60);
  final barrier = tester
      .widgetList<ModalBarrier>(find.byType(ModalBarrier))
      .singleWhere((candidate) => candidate.color == expectedBarrier);
  expect(barrier.dismissible, isTrue);
  final closeMaterial = tester.widget<Material>(
    find.descendant(of: find.byType(PromotionalBannerDialog), matching: find.byType(Material)).last,
  );
  expect(closeMaterial.type, MaterialType.circle);
  expect(closeMaterial.color, Colors.black);
  final glyph = tester.widget<Icon>(
    find.descendant(of: find.byType(PromotionalBannerDialog), matching: find.byIcon(Icons.close)),
  );
  expect(glyph.icon, Icons.close);
  expect(glyph.color, Colors.white);
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(TeresaRizalCurvedNavBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _dismiss(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close));
  await tester.pumpAndSettle();
  expect(find.byType(PromoPosterPlaceholder), findsNothing);
}

void main() {
  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    WidgetController.hitTestWarningShouldBeFatal = false;
  });

  test('shell locks are 0.94 by 0.90, radius 20, and a 60% black barrier', () {
    expect(PromotionalBannerDialog.maxWidthFraction, 0.94);
    expect(PromotionalBannerDialog.maxHeightFraction, 0.90);
    expect(PromotionalBannerDialog.cornerRadius, 20);
    expect(PromotionalBannerDialog.closeOutset, 14);
    expect(PromotionalBannerDialog.closeHit, 44);
    // ignore: deprecated_member_use
    expect(PromotionalBannerDialog.barrierColor, Colors.black.withOpacity(0.60));
    expect(PromotionalBannerDialog.placeholderAspectRatio, 2 / 3);
  });

  test('dialog sources do not name a poster file', () {
    for (final path in [
      'lib/widgets/promotional_banner_dialog.dart',
      'lib/widgets/home_welcome_banner.dart',
      'lib/screens/home/root_shell.dart',
      'lib/screens/home/home_screen.dart',
    ]) {
      final source = File(path).readAsStringSync().toLowerCase();
      expect(source, isNot(contains('.png')), reason: path);
      expect(source, isNot(contains('esperanza')), reason: path);
    }
  });

  testWidgets('Home and Balita show the empty shell once, Emergency does not', (tester) async {
    await _pumpShell(tester);

    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    expect(find.text('Welcome, Guest.'), findsOneWidget);
    _expectEmptyShell(tester, 'Home');
      await _shot(tester, 'home_promo_shell_060');

    await _dismiss(tester);
    expect(find.byType(HomeWelcomeBanner), findsNothing);

    await _tapNav(tester, 'Balita');
    _expectEmptyShell(tester, 'Balita');
    await _shot(tester, 'balita_promo_shell_060');

    final poster = tester.getRect(find.byType(PromoPosterPlaceholder));
    await tester.tapAt(Offset(8, poster.top - 24));
    await tester.pumpAndSettle();
    expect(find.byType(PromoPosterPlaceholder), findsNothing);

    await _tapNav(tester, 'Home');
    expect(find.byType(HomeWelcomeBanner), findsNothing);

    await _tapNav(tester, 'Balita');
    expect(find.byType(PromoPosterPlaceholder), findsNothing);

    await _tapNav(tester, 'Events');
    _expectEmptyShell(tester, 'Events');
    await _dismiss(tester);

    await _tapNav(tester, 'Events');
    expect(find.byType(PromoPosterPlaceholder), findsNothing);

    RootShell.openService(
      tester.element(find.byType(RootShell)),
      ServiceLauncherTarget.emergency,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PromotionalBannerDialog), findsNothing);
    expect(find.byType(PromoPosterPlaceholder), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dokyu and Tulong show the empty shell once for a verified session', (tester) async {
    await _pumpShell(tester, account: MockCatalog.demoAccounts.last);
    expect(find.text('Magandang araw, Perlita.'), findsOneWidget);
    _expectEmptyShell(tester, 'Home');
    await _dismiss(tester);

    final context = tester.element(find.byType(RootShell));
    RootShell.openService(context, ServiceLauncherTarget.dokyu);
    await tester.pumpAndSettle();
    _expectEmptyShell(tester, 'Dokyu');
    await _dismiss(tester);

    RootShell.openService(tester.element(find.byType(RootShell)), ServiceLauncherTarget.dokyu);
    await tester.pumpAndSettle();
    expect(find.byType(PromoPosterPlaceholder), findsNothing);

    RootShell.openService(tester.element(find.byType(RootShell)), ServiceLauncherTarget.tulong);
    await tester.pumpAndSettle();
    _expectEmptyShell(tester, 'Tulong');
    await _dismiss(tester);

    RootShell.openService(tester.element(find.byType(RootShell)), ServiceLauncherTarget.tulong);
    await tester.pumpAndSettle();
    expect(find.byType(PromoPosterPlaceholder), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an asset path is contained and never cropped', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PromotionalBannerDialog.show(
                context,
                assetPath: teresaRizalSealAsset,
                label: 'Home',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(PromoPosterPlaceholder), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadius.circular(20));
    expect(tester.takeException(), isNull);
  });
}
