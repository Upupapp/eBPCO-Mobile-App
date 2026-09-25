// 390×844 captures of the Cluster 6 Balita social stills. Inter is loaded
// explicitly because `flutter test` paints with Ahem. The app turns the
// debug banner off.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/screens/balita/balita_screen.dart';
import 'package:teresa_rizal/screens/balita/comments_sheet.dart';
import 'package:teresa_rizal/screens/balita/post_image_viewer.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';

// Frames land in the Cursor artifacts volume where it exists, and in the
// system temp directory elsewhere, so the read-back assertions run anywhere.
final _outDir = Directory('/opt/cursor').existsSync()
    ? '/opt/cursor/artifacts/pr-b2-social'
    : '${Directory.systemTemp.path}/teresa-shots/pr-b2-social';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissClose(WidgetTester tester) async {
  // Promo chrome on this base uses a plain close, not the rounded viewer X.
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _boot(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({
    'teresa_rizal_onboarding_complete': true,
    ...prefs,
  });
  _setPhoneViewport(tester);
  await tester.pumpWidget(const TeresaRizalMobileApp());
  await tester.pumpAndSettle();
}

Future<void> _signInPerlita(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('demo-verified')));
  await tester.tap(find.byKey(const Key('demo-verified')));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await _dismissClose(tester);
}

Future<void> _openBalita(WidgetTester tester) async {
  await tester.tap(find.text('Balita'));
  await tester.pumpAndSettle();
  await _dismissClose(tester);
  final context = tester.element(find.byType(BalitaScreen));
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/balita/lgu_ambulance.png'),
      context,
    );
  });
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  await tester.pumpAndSettle();
  try {
    await tester.runAsync(() async {
      // The root view layer includes modal sheets. A page RepaintBoundary
      // sits under the overlay and would miss every sheet.
      final renderView = tester.binding.renderViews.single;
      final layer = renderView.debugLayer! as OffsetLayer;
      final image = await layer.toImage(renderView.paintBounds, pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_outDir/$name.png');
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
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Italic.ttf'));
    await inter.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('liked, comments, share, and viewer', (tester) async {
    await _boot(tester, {});
    await _signInPerlita(tester);
    await _openBalita(tester);

    final card = find.byKey(const ValueKey('bal-lgu-ambulance'));
    expect(find.text('Municipal news'), findsOneWidget);
    expect(find.text('Lahat'), findsOneWidget);
    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('129'), findsOneWidget);
    final heart = tester.widget<Icon>(
      find.descendant(of: card, matching: find.byIcon(Icons.favorite_rounded)),
    );
    expect(heart.color, SoftColors.danger);
    await _shot(tester, '01-balita-liked');

    final comment = find.descendant(
      of: card,
      matching: find.byTooltip('Comment'),
    );
    await tester.ensureVisible(comment);
    await tester.tap(comment);
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSheet), findsOneWidget);
    expect(find.text('24 comments · local only'), findsOneWidget);
    expect(find.text('Juan R.'), findsOneWidget);
    expect(find.text('Ana L.'), findsOneWidget);
    expect(find.text('Kim S.'), findsOneWidget);
    expect(find.text('Write a comment...'), findsOneWidget);
    await _shot(tester, '02-balita-comments');
    Navigator.of(tester.element(find.byType(CommentsSheet))).pop();
    await tester.pumpAndSettle();

    final share = find.descendant(of: card, matching: find.byTooltip('Share'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Local clipboard'), findsOneWidget);
    expect(find.text('Save image'), findsOneWidget);
    expect(find.text('To device gallery'), findsOneWidget);
    expect(find.text('System share'), findsOneWidget);
    expect(find.text('OS share sheet'), findsOneWidget);
    expect(find.text('Facebook'), findsNothing);
    expect(
      find.text('On-device options · no fake social destinations'),
      findsOneWidget,
    );
    await _shot(tester, '04-balita-share');
    Navigator.of(tester.element(find.text('Copy link'))).pop();
    await tester.pumpAndSettle();

    final feed = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('balita-feed')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    feed.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('balita-media-bal-lgu-ambulance')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PostImageViewer), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    final viewerImage = find.descendant(
      of: find.byType(PostImageViewer),
      matching: find.byType(Image),
    );
    expect(viewerImage, findsOneWidget);
    expect(
      tester.getSize(viewerImage).height,
      greaterThan(100),
      reason: 'viewer image size ${tester.getSize(viewerImage)}',
    );
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(PostImageViewer),
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );
    await _shot(tester, '05-balita-viewer');
    expect(
      File('$_outDir/05-balita-viewer.png').lengthSync(),
      greaterThan(40000),
    );
    final commentsBytes = File(
      '$_outDir/02-balita-comments.png',
    ).readAsBytesSync();
    final shareBytes = File('$_outDir/04-balita-share.png').readAsBytesSync();
    expect(commentsBytes, isNot(equals(shareBytes)));
  });

  testWidgets('guest comments replace the composer with Sign in', (
    tester,
  ) async {
    await _boot(tester, {});
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissClose(tester);
    await _openBalita(tester);

    final card = find.byKey(const ValueKey('bal-lgu-ambulance'));
    final comment = find.descendant(
      of: card,
      matching: find.byTooltip('Comment'),
    );
    await tester.ensureVisible(comment);
    await tester.tap(comment);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to join the conversation'), findsOneWidget);
    expect(find.text('Guest view'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Juan R.'), findsOneWidget);
    expect(find.text('Ana L.'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await _shot(tester, '03-balita-comments-guest');
    final comments = File('$_outDir/02-balita-comments.png').readAsBytesSync();
    final guest = File(
      '$_outDir/03-balita-comments-guest.png',
    ).readAsBytesSync();
    expect(comments, isNot(equals(guest)));
  });

  testWidgets('empty Balita is a quiet wash note', (tester) async {
    await _boot(tester, {'teresa_rizal_balita_posts': '[]'});
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissClose(tester);
    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await _dismissClose(tester);

    expect(find.text('Municipal news'), findsOneWidget);
    expect(find.text('No posts yet'), findsOneWidget);
    expect(
      find.text(
        'Announcements from Teresa, Rizal will appear here when published.',
      ),
      findsOneWidget,
    );
    expect(find.text('Lahat'), findsNothing);
    await _shot(tester, '06-balita-empty');
  });
}
