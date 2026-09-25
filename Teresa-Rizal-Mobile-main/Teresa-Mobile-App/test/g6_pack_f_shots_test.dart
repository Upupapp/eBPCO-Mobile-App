// 390×844 logical (780×1688 px at 2×) Inter captures for Pack F.
// Run: flutter test --dart-define=PACK_F_SHOTS=true test/g6_pack_f_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/screens/profile/digital_id_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/g6_chrome.dart';
import 'package:teresa_rizal/screens/profile/g6/g6_sample.dart';
import 'package:teresa_rizal/screens/profile/g6/household_info_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/household_screen.dart';
import 'package:teresa_rizal/screens/profile/g6/member_screens.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';

const _capture = bool.fromEnvironment('PACK_F_SHOTS');

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

class _WriteComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final name = golden.pathSegments.last;
    final file = File('/opt/cursor/artifacts/pack-f/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);
    if (name == 'g6-member-add-keyboard.png') {
      await File(
        '/opt/cursor/artifacts/pack-f/kbd-member-add.png',
      ).writeAsBytes(imageBytes);
    }
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await compare(imageBytes, golden);
  }

  @override
  Uri getTestUri(Uri key, int? version) => key;
}

Future<void> _resolveImages(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    await precacheImage(const AssetImage(teresaRizalSealAsset), context);
  });
  await tester.pump();
}

void _view(WidgetTester tester, {double inset = 0}) {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  tester.view.viewInsets = FakeViewPadding(bottom: inset * 2);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _resolveImages(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
}

void main() {
  testWidgets('Pack F frames at 390x844 logical, 2x, with Inter', (
    tester,
  ) async {
    if (!_capture) return;

    final previous = goldenFileComparator;
    goldenFileComparator = _WriteComparator();
    addTearDown(() => goldenFileComparator = previous);
    // Widget tests draw BoxShadow as a solid offset rect. These frames need
    // the real blur (primary pill and card elevation). Restored before the
    // test returns; the binding asserts painting debug flags are unchanged.
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    try {
      await tester.runAsync(_loadShotFonts);

      Future<void> frame(
        Widget home,
        String name, {
        double inset = 0,
        bool settle = true,
      }) async {
        _view(tester, inset: inset);
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(name),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: home,
          ),
        );
        if (settle) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
        }
        await _shot(tester, name);
      }

      await frame(const G6HouseholdScreen(populated: true), 'g6-household.png');
      await frame(
        const G6HouseholdScreen(populated: false),
        'g6-household-empty.png',
      );
      await frame(
        const G6HouseholdInfoScreen(people: 5),
        'g6-household-info.png',
      );
      await frame(
        G6MemberDetailScreen(member: G6Sample.jose),
        'g6-member-detail.png',
      );
      await frame(
        G6MemberDetailScreen(member: G6Sample.paolo),
        'g6-member-pending.png',
      );
      await frame(const G6AddMemberScreen(), 'g6-member-add.png');

      _view(tester, inset: 336);
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('g6-member-add-keyboard'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const Stack(
            children: [
              G6AddMemberScreen(keyboardFrame: true, keyboardCaption: true),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 336,
                child: G6TextIme(),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.ensureVisible(find.byKey(const ValueKey('g6-member-birth')));
      await tester.pump();
      await _shot(tester, 'g6-member-add-keyboard.png');

      _view(tester);
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('g6-member-remove'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const G6HouseholdScreen(populated: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lorna Santos'));
      await tester.tap(find.text('Lorna Santos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(G6Button, 'Remove'));
      await tester.tap(find.widgetWithText(G6Button, 'Remove'));
      await tester.pumpAndSettle();
      await _shot(tester, 'g6-member-remove.png');

      await frame(
        const DigitalIdScreen(shot: G6IdShot.front),
        'g6-id-front.png',
      );
      await frame(const DigitalIdScreen(shot: G6IdShot.back), 'g6-id-back.png');

      _view(tester);
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('g6-id-flip'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const DigitalIdScreen(shot: G6IdShot.flip),
        ),
      );
      await tester.pump();
      await _resolveImages(tester);
      await tester.tap(find.byKey(const ValueKey('digital-id-card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('g6-id-flip.png'),
      );

      await frame(
        const DigitalIdScreen(shot: G6IdShot.fullscreen),
        'g6-id-fullscreen.png',
      );
      await frame(
        const DigitalIdScreen(shot: G6IdShot.locked),
        'g6-id-locked.png',
      );
    } finally {
      debugDisableShadows = previousShadows;
    }
  });
}
