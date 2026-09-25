// 390×844 captures of the G2 hubs and the nested subflows that follow them:
// Balita hub, Balita comments, comments with the keyboard inset, Events hub,
// Events poster.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/screens/balita/comments_sheet.dart';
import 'package:teresa_rizal/screens/shared/event_poster_viewer.dart';
import 'package:teresa_rizal/widgets/event_card.dart';

/// `flutter test` ships Ahem, which paints every glyph as a block. SoftType
/// asks for Inter, and nav/action icons ask for MaterialIcons. Register both
/// before the first frame or the shots are .notdef bars and square boxes.
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

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissClose(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

// Goldens are recorded on the Linux agent. macOS rasterises Inter
// differently (identical frames measure ~6% apart), so the pixel compare runs
// on Linux only; every other machine still walks the frames.
Future<void> _saveShot(WidgetTester tester, String name) async {
  if (!Platform.isLinux) return;
  await expectLater(
    find.byType(TeresaRizalMobileApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('G2 hubs then nested subflows at 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({
      'teresa_rizal_onboarding_complete': true,
    });
    _setPhoneViewport(tester);
    await tester.runAsync(_loadShotFonts);
    await tester.pumpWidget(const TeresaRizalMobileApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('demo-verified')));
    await tester.tap(find.byKey(const Key('demo-verified')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _dismissClose(tester);

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await _dismissClose(tester);
    expect(find.text('Municipal news'), findsOneWidget);
    expect(find.text('Lahat'), findsOneWidget);
    expect(find.text('New LGU Teresa ambulance for residents'), findsOneWidget);
    expect(find.text('129'), findsOneWidget);
    await _saveShot(tester, '01-balita-hub');

    final comment = find.descendant(
      of: find.byKey(const ValueKey('bal-lgu-ambulance')),
      matching: find.byTooltip('Comment'),
    );
    await tester.ensureVisible(comment);
    await tester.pumpAndSettle();
    await tester.tap(comment);
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSheet), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await _saveShot(tester, '02-balita-comments');

    // Shared IME path: the sheet pads with MediaQuery.viewInsets. A widget
    // test does not open a real keyboard, so the inset is applied directly.
    tester.view.viewInsets = const FakeViewPadding(bottom: 312);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Write a comment...'), findsOneWidget);
    expect(find.text('24 comments · local only'), findsOneWidget);
    await _saveShot(tester, '02b-balita-comments-keyboard');
    tester.view.resetViewInsets();
    await tester.pump();

    Navigator.of(tester.element(find.byType(CommentsSheet))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events').first);
    await tester.pumpAndSettle();
    await _dismissClose(tester);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(find.byType(EventCard), findsWidgets);
    await _saveShot(tester, '03-events-hub');

    await tester.tap(find.text('View poster').first);
    await tester.pumpAndSettle();
    expect(find.byType(EventPosterViewer), findsOneWidget);
    expect(find.text('Poster slot'), findsOneWidget);
    await _saveShot(tester, '04-events-poster');
  });
}
