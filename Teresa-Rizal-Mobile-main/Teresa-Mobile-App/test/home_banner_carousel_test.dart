// Home banner slot: filled carousel on Guest Home and Verified Home.
// Order is 01 → 02 → 03. The dashed placeholder is not painted in this slot.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/home/home_screen.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';
import 'package:teresa_rizal/widgets/home_banner_carousel.dart';
import 'package:teresa_rizal/widgets/soft_chrome.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _loadInter() async {
  // `flutter test` ships the Ahem face, which draws every glyph as a block.
  // Load the bundled Inter files so Home copy matches the G0 theme.
  final loader = FontLoader('Inter');
  for (final name in [
    'assets/fonts/Inter.ttf',
    'assets/fonts/Inter-Italic.ttf',
  ]) {
    final bytes = File(name).readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  }
  await loader.load();
}

Future<void> _pumpHome(WidgetTester tester, {required bool verified}) async {
  SharedPreferences.setMockInitialValues({});
  _phone(tester);
  await tester.runAsync(_loadInter);
  final session = CitizenSessionService();
  if (verified) {
    await session.login(MockCatalog.demoAccounts.last);
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('home-banner-shot'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>(
            create: (_) => RequestsService(),
          ),
          ChangeNotifierProvider<ResidentProfileService>(
            create: (_) => ResidentProfileService(),
          ),
          ChangeNotifierProvider<NotificationsService>(
            create: (_) => NotificationsService(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final close = find.byIcon(Icons.close);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  final context = tester.element(find.byType(HomeBannerCarousel));
  await tester.runAsync(() async {
    for (final slide in HomeBannerCarousel.slides) {
      await precacheImage(AssetImage(slide.asset), context);
    }
  });
  await tester.pump();
}

String _assetName(ImageProvider provider) {
  final image = provider is ResizeImage ? provider.imageProvider : provider;
  return (image as AssetImage).assetName;
}

void _expectFilledSlot(WidgetTester tester, {required int slide}) {
  expect(find.byType(HomeBannerCarousel), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(HomeBannerCarousel),
      matching: find.byType(DashedBannerSlot),
    ),
    findsNothing,
  );
  expect(find.text('Banner slot'), findsNothing);
  expect(find.textContaining('GPT art pending'), findsNothing);

  final clip = tester.widget<ClipRRect>(
    find.descendant(
      of: find.byType(HomeBannerCarousel),
      matching: find.byType(ClipRRect),
    ),
  );
  expect(clip.borderRadius, BorderRadius.circular(SoftRadius.lg));
  expect(SoftRadius.lg, 22);
  expect(clip.clipBehavior, Clip.hardEdge);

  final ratio = tester.widget<AspectRatio>(
    find.descendant(
      of: find.byType(HomeBannerCarousel),
      matching: find.byType(AspectRatio),
    ),
  );
  expect(ratio.aspectRatio, 1672 / 941);

  expect(
    find.descendant(
      of: find.byType(HomeBannerCarousel),
      matching: find.byType(Text),
    ),
    findsNothing,
  );

  final images = tester.widgetList<Image>(
    find.descendant(
      of: find.byType(HomeBannerCarousel),
      matching: find.byType(Image),
    ),
  );
  expect(images, isNotEmpty);
  for (final image in images) {
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
    expect(_assetName(image.image), isNot(teresaRizalSealAsset));
    expect(_assetName(image.image).contains('seal'), isFalse);
  }

  final slideSpec = HomeBannerCarousel.slides[slide];
  final current = tester.widget<Image>(find.byKey(ValueKey(slideSpec.asset)));
  expect(current.semanticLabel, slideSpec.semanticLabel);
  expect(_assetName(current.image), slideSpec.asset);
  expect(find.bySemanticsLabel(slideSpec.semanticLabel), findsOneWidget);
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['HOME_BANNER_SHOTS'];
  if (dir == null || dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('home-banner-shot')),
  );
  // toImage completes on the real event loop. The test binding's fake
  // async never finishes that callback, so this has to leave the zone.
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

void main() {
  testWidgets(
    'Guest Home shows banner carousel slide 01, clipped, with no dashed slot',
    (tester) async {
      await _pumpHome(tester, verified: false);
      expect(find.text('Welcome, Guest.'), findsOneWidget);
      _expectFilledSlot(tester, slide: 0);
      await _shot(tester, 'guest_home_banner_01');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Verified Home uses the same carousel, still on slide 01', (
    tester,
  ) async {
    await _pumpHome(tester, verified: true);
    expect(find.text('Magandang araw, Perlita.'), findsOneWidget);
    _expectFilledSlot(tester, slide: 0);
    await _shot(tester, 'verified_home_banner_01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping advances 01 → 02 → 03 and each slide keeps its label', (
    tester,
  ) async {
    await _pumpHome(tester, verified: true);
    _expectFilledSlot(tester, slide: 0);

    await tester.drag(find.byType(HomeBannerCarousel), const Offset(-400, 0));
    await tester.pumpAndSettle();
    _expectFilledSlot(tester, slide: 1);

    await tester.drag(find.byType(HomeBannerCarousel), const Offset(-400, 0));
    await tester.pumpAndSettle();
    _expectFilledSlot(tester, slide: 2);
    expect(tester.takeException(), isNull);
  });
}
