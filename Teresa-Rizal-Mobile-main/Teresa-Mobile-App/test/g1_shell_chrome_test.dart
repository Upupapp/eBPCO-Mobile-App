// G1 shell polish: drawer variants, unverified Home, guest social gate,
// and the unread bell on each hub.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/auth/login_screen.dart';
import 'package:teresa_rizal/screens/balita/balita_screen.dart';
import 'package:teresa_rizal/screens/events/events_screen.dart';
import 'package:teresa_rizal/screens/home/home_screen.dart';
import 'package:teresa_rizal/screens/profile/profile_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notification_feed.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/widgets/guest_sign_in_gate.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_services_action.dart';
import 'package:teresa_rizal/widgets/home_banner_carousel.dart';
import 'package:teresa_rizal/widgets/soft_chrome.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// `flutter test` ships Ahem. SoftType asks for Inter, and the shell glyphs
/// (search, bell, Servana, menu tiles, chevrons) ask for MaterialIcons.
/// Register both before the first frame or the shots are .notdef squares.
bool _shotFontsLoaded = false;

Future<void> _loadShotFonts() async {
  if (_shotFontsLoaded) return;
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
  _shotFontsLoaded = true;
}

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'teresa_rizal_onboarding_complete': true,
  });
  _setPhoneViewport(tester);
  await tester.runAsync(_loadShotFonts);
  await tester.pumpWidget(const TeresaRizalMobileApp());
  await tester.pumpAndSettle();
}

Future<void> _precacheHomeBanners(WidgetTester tester) async {
  final context = tester.element(find.byType(HomeBannerCarousel));
  await tester.runAsync(() async {
    for (final slide in HomeBannerCarousel.slides) {
      await precacheImage(AssetImage(slide.asset), context);
    }
  });
  await tester.pump();
}

void _expectHomeHeaderLock(WidgetTester tester) {
  final seal = tester.getRect(find.byKey(const ValueKey('home-brand-seal')));
  final avatar = tester.getRect(
    find.byKey(const ValueKey('home-greeting-avatar')),
  );
  final greeting = tester.getRect(
    find.byKey(const ValueKey('home-greeting-text')),
  );
  expect(seal.top, lessThan(avatar.top));
  expect(avatar.left, lessThan(greeting.left));
  final gap = greeting.left - avatar.right;
  expect(gap, inInclusiveRange(10, 12));
  expect(
    tester.getSize(find.byTooltip('Search')).shortestSide,
    greaterThanOrEqualTo(48),
  );
  expect(
    tester.getSize(find.byTooltip('Alerts')).shortestSide,
    greaterThanOrEqualTo(48),
  );
}

/// One painted H1 line bottoms the avatar on that line. A wrap centers it
/// on the whole greeting block.
void _expectAvatarVerticalAlign(WidgetTester tester, {required bool wrapped}) {
  final avatar = tester.getRect(
    find.byKey(const ValueKey('home-greeting-avatar')),
  );
  final greeting = tester.getRect(
    find.byKey(const ValueKey('home-greeting-text')),
  );
  if (wrapped) {
    expect(
      find.byKey(const ValueKey('home-greeting-align-center')),
      findsOneWidget,
    );
    expect(greeting.height, greaterThan(avatar.height));
    expect(avatar.center.dy, closeTo(greeting.center.dy, 1));
  } else {
    expect(
      find.byKey(const ValueKey('home-greeting-align-end')),
      findsOneWidget,
    );
    expect(greeting.height, lessThan(avatar.height));
    expect(avatar.bottom, closeTo(greeting.bottom, 1));
  }
}

void _expectFilledHomeBanner(WidgetTester tester) {
  expect(
    find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(HomeBannerCarousel),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(DashedBannerSlot),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byType(HomeScreen),
      matching: find.text('Banner slot'),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byType(HomeScreen),
      matching: find.textContaining('GPT art pending'),
    ),
    findsNothing,
  );
}

Future<void> _keepUnread(WidgetTester tester, int keep) async {
  final context = tester.element(find.byType(HomeScreen));
  final service = Provider.of<NotificationsService>(context, listen: false);
  final ids = latestNotificationFeedIds;
  final drop = ids.length <= keep ? const <String>[] : ids.sublist(keep);
  for (final id in drop) {
    await service.markRead(id);
  }
  await tester.pumpAndSettle();
}

bool _paints(RenderObject ancestor, RenderObject? node) {
  while (node != null) {
    if (identical(node, ancestor)) return true;
    node = node.parent;
  }
  return false;
}

/// Modal routes paint the barrier and sheet in their own boundary, so a
/// capture of that boundary is a black void. Prefer a full-screen boundary
/// that also paints the page underneath (dimmed Balita/Home). Fall back to
/// the root layer, which composites both.
Future<ui.Image> _capture(WidgetTester tester) async {
  final menuOpen = find
      .byKey(const ValueKey('menu-sheet'))
      .evaluate()
      .isNotEmpty;
  final gateOpen = find.byType(GuestSignInGate).evaluate().isNotEmpty;
  if (menuOpen || gateOpen) {
    final modal = menuOpen
        ? find.byKey(const ValueKey('menu-sheet'))
        : find.byType(GuestSignInGate);
    final pageFinder = find.byType(BalitaScreen).evaluate().isNotEmpty
        ? find.byType(BalitaScreen)
        : find.byType(HomeScreen);
    final modalObject = modal.evaluate().first.renderObject;
    final pageObject = pageFinder.evaluate().isEmpty
        ? null
        : pageFinder.evaluate().first.renderObject;
    RenderRepaintBoundary? both;
    var bothDepth = 1 << 30;
    if (pageObject != null && modalObject != null) {
      for (final boundary in tester.renderObjectList<RenderRepaintBoundary>(
        find.byType(RepaintBoundary),
      )) {
        if (boundary.size.width < 300 || boundary.size.height < 700) continue;
        if (!_paints(boundary, modalObject) || !_paints(boundary, pageObject)) {
          continue;
        }
        if (boundary.depth < bothDepth) {
          both = boundary;
          bothDepth = boundary.depth;
        }
      }
    }
    if (both != null) return both.toImage(pixelRatio: 1);

    final renderView = tester.binding.renderViews.single;
    // The shot falls back to the view layer when no boundary covers both
    // the page and the sheet. `layer` is the only handle the test binding
    // exposes for that capture.
    // ignore: invalid_use_of_protected_member
    final layer = renderView.layer;
    if (layer is OffsetLayer) {
      return layer.toImage(Offset.zero & renderView.size, pixelRatio: 1);
    }
  }

  RenderRepaintBoundary? best;
  var bestArea = 0.0;
  var bestDepth = 1 << 30;
  for (final boundary in tester.renderObjectList<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  )) {
    final size = boundary.size;
    final area = size.width * size.height;
    if (size.width < 300 || size.height < 700) continue;
    if (area > bestArea || (area == bestArea && boundary.depth < bestDepth)) {
      best = boundary;
      bestArea = area;
      bestDepth = boundary.depth;
    }
  }
  final boundary =
      best ??
      tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
  return boundary.toImage(pixelRatio: 1);
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['G1_SHOTS_DIR'];
  if (dir == null || dir.isEmpty) return;
  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  await tester.pumpAndSettle();
  try {
    await tester.runAsync(() async {
      final image = await _capture(tester);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = previousShadows;
  }
}

/// Scroll the sheet only as far as the overflow, so Sign out lands fully
/// inside 390×844 without jumping it to the top of the viewport.
Future<void> _revealSignOut(WidgetTester tester) async {
  final button = find.ancestor(
    of: find.text('Sign out'),
    matching: find.byType(SoftPillButton),
  );
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey('menu-sheet')),
    matching: find.byType(Scrollable),
  );
  final viewHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 6; i++) {
    final rect = tester.getRect(button);
    final overflow = rect.bottom - (viewHeight - 12);
    if (overflow <= 0 && rect.top >= 0) return;
    await tester.drag(scrollable, Offset(0, -(overflow + 8)));
    await tester.pumpAndSettle();
  }
}

void _expectFullyOnScreen(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(width));
  expect(rect.bottom, lessThanOrEqualTo(height));
  expect(rect.height, greaterThan(40));
}

void main() {
  testWidgets('Guest drawer is the guest variant', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);
    expect(find.text('Welcome, Guest.'), findsOneWidget);
    expect(find.text('Browsing as Guest'), findsOneWidget);
    _expectHomeHeaderLock(tester);
    _expectAvatarVerticalAlign(tester, wrapped: false);
    _expectFilledHomeBanner(tester);
    _expectServicesCradle(tester);
    await _keepUnread(tester, 0);
    await _precacheHomeBanners(tester);
    await _shot(tester, 'home-guest');

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu-sheet')), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byKey(const ValueKey('drawer-variant-guest')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drawer-variant-signed-in')),
      findsNothing,
    );
    final sheet = find.byKey(const ValueKey('menu-sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Sign in')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Create account')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Resident profile')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Sign out')),
      findsNothing,
    );
    expect(find.text('Guest · public destinations only'), findsOneWidget);
    expect(find.text('Government Directory'), findsOneWidget);
    await _shot(tester, 'drawer-guest');
  });

  testWidgets('Signed-in drawer is the account variant', (tester) async {
    await _boot(tester);
    await tester.ensureVisible(find.byKey(const Key('demo-verified')));
    await tester.tap(find.byKey(const Key('demo-verified')));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);
    expect(find.text('Magandang araw, Perlita.'), findsOneWidget);
    _expectHomeHeaderLock(tester);
    _expectAvatarVerticalAlign(tester, wrapped: false);
    _expectFilledHomeBanner(tester);
    await _precacheHomeBanners(tester);
    await _shot(tester, 'verified-home');

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('menu-sheet'));
    expect(
      find.byKey(const ValueKey('drawer-variant-signed-in')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Resident profile')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Sign out')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Sign in')),
      findsNothing,
    );
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(find.text('MORE'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Mock destination · not a real ID'),
      ),
      findsOneWidget,
    );
    await _revealSignOut(tester);
    final signOut = find.ancestor(
      of: find.text('Sign out'),
      matching: find.byType(SoftPillButton),
    );
    _expectFullyOnScreen(tester, signOut);
    await _shot(tester, 'drawer-signed-in');
  });

  testWidgets('Unverified home keeps the header lock and says so', (
    tester,
  ) async {
    await _boot(tester);
    await tester.ensureVisible(find.byKey(const Key('demo-unverified')));
    await tester.tap(find.byKey(const Key('demo-unverified')));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    expect(find.text('Magandang araw, Nicanor.'), findsOneWidget);
    expect(find.textContaining('Welcome, Guest'), findsNothing);
    _expectHomeHeaderLock(tester);
    _expectAvatarVerticalAlign(tester, wrapped: true);
    expect(find.byKey(const ValueKey('home-brand-seal')), findsOneWidget);
    expect(find.text('Unverified'), findsWidgets);
    expect(find.text('Labangtaytay'), findsWidgets);
    _expectFilledHomeBanner(tester);
    await _keepUnread(tester, 0);
    expect(
      find.byKey(const ValueKey('home-unverified-notice')),
      findsOneWidget,
    );
    expect(find.text('Continue verification'), findsOneWidget);
    expect(find.textContaining('Pending review'), findsWidgets);
    await _precacheHomeBanners(tester);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byKey(const ValueKey('alerts-unread-count')),
      ),
      findsNothing,
    );
    await _shot(tester, 'home-unverified');
  });

  testWidgets('A wrapping greeting centers the avatar on the block', (
    tester,
  ) async {
    await _boot(tester);
    final session = Provider.of<CitizenSessionService>(
      tester.element(find.byType(LoginScreen)),
      listen: false,
    );
    final base = MockCatalog.demoAccounts.first;
    await session.login(
      CitizenAccount(
        id: base.id,
        firstName: 'Magdalena Purificacion',
        lastName: base.lastName,
        email: base.email,
        mobile: base.mobile,
        barangay: base.barangay,
        purok: base.purok,
        address: base.address,
        birthdate: base.birthdate,
        sex: base.sex,
        civilStatus: base.civilStatus,
        occupation: base.occupation,
        profileCompleteness: base.profileCompleteness,
        status: base.status,
      ),
    );
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    expect(
      find.text('Magandang araw, Magdalena Purificacion.'),
      findsOneWidget,
    );
    _expectHomeHeaderLock(tester);
    _expectAvatarVerticalAlign(tester, wrapped: true);
    _expectFilledHomeBanner(tester);
    await _precacheHomeBanners(tester);
    await _shot(tester, 'home-wrapped-greeting');
  });

  testWidgets('Guest social action opens the sign-in gate', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Like').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.byType(GuestSignInGate), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text(GuestSignInGate.engageBody), findsOneWidget);
    expect(find.text(GuestSignInGate.simulationNote), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GuestSignInGate),
        matching: find.text('Sign in'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(GuestSignInGate),
        matching: find.text('Not now'),
      ),
      findsOneWidget,
    );
    await _shot(tester, 'guest-social-gate');

    await tester.tap(
      find.descendant(
        of: find.byType(GuestSignInGate),
        matching: find.text('Not now'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GuestSignInGate), findsNothing);

    await tester.tap(find.text('Share').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text(GuestSignInGate.shareBody), findsOneWidget);
    expect(find.text(GuestSignInGate.simulationNote), findsNothing);
    await _shot(tester, 'guest-social-gate-share');
  });

  testWidgets('Unread bell is on Home, Balita, Events, and Profile', (
    tester,
  ) async {
    await _boot(tester);
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byKey(const ValueKey('alerts-unread-count')),
      ),
      findsOneWidget,
    );

    Future<void> openHub(String label, Type screen) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);
      expect(
        find.descendant(
          of: find.byType(screen),
          matching: find.byKey(const ValueKey('alerts-unread-count')),
        ),
        findsOneWidget,
      );
    }

    await openHub('Balita', BalitaScreen);
    await openHub('Events', EventsScreen);
    await openHub('Profile', ProfileScreen);
  });

  testWidgets('Bell unread count pill shows 3', (tester) async {
    await _boot(tester);
    await tester.ensureVisible(find.byKey(const Key('demo-unverified')));
    await tester.tap(find.byKey(const Key('demo-unverified')));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);
    await _keepUnread(tester, 3);

    expect(find.text('3 unread notifications'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-unverified-notice')), findsNothing);
    expect(
      find.descendant(of: find.byType(HomeScreen), matching: find.text('3')),
      findsWidgets,
    );
    final cradle = tester.widget<Container>(
      find.byKey(const ValueKey('nav-services-cradle')),
    );
    final decoration = cradle.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, SoftColors.blueSoft);
    await _precacheHomeBanners(tester);
    await _shot(tester, 'home-bell-unread');
  });
}

void _expectServicesCradle(WidgetTester tester) {
  final cradle = tester.widget<Container>(
    find.byKey(const ValueKey('nav-services-cradle')),
  );
  final decoration = cradle.decoration! as BoxDecoration;
  expect(decoration.gradient, isNull);
  expect(decoration.color, SoftColors.blueSoft);
  expect(find.byType(TeresaRizalServicesAction), findsOneWidget);
}
