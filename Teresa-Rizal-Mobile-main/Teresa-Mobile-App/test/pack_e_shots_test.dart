// 390×844 logical (780×1688 px at 2×) Inter captures for Pack E.
// Run: flutter test --dart-define=PACK_E_SHOTS=true test/pack_e_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/screens/notifications/g5/g5_landings.dart';
import 'package:teresa_rizal/screens/notifications/g5/g5_samples.dart';
import 'package:teresa_rizal/screens/notifications/notifications_screen.dart';
import 'package:teresa_rizal/theme/app_theme.dart';

const _capture = bool.fromEnvironment('PACK_E_SHOTS');

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
    final file = File(
      '/opt/cursor/artifacts/pack-e/${golden.pathSegments.last}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await compare(imageBytes, golden);
  }

  @override
  Uri getTestUri(Uri key, int? version) => key;
}

void main() {
  testWidgets('Pack E frames at 390x844 logical, 2x, with Inter', (
    tester,
  ) async {
    if (!_capture) return;

    final previous = goldenFileComparator;
    goldenFileComparator = _WriteComparator();
    addTearDown(() => goldenFileComparator = previous);

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(_loadShotFonts);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;

    final frames = <(String, Widget, double)>[
      (
        'g5-inbox',
        const NotificationsScreen(
          key: ValueKey('g5-inbox'),
          preset: G5InboxPreset.signedIn,
        ),
        1,
      ),
      (
        'g5-inbox-advisories',
        const NotificationsScreen(
          key: ValueKey('g5-inbox-advisories'),
          preset: G5InboxPreset.advisories,
        ),
        1,
      ),
      (
        'g5-inbox-filter-empty',
        const NotificationsScreen(
          key: ValueKey('g5-inbox-filter-empty'),
          preset: G5InboxPreset.emptyEvents,
        ),
        1,
      ),
      (
        'g5-inbox-1p3x',
        const NotificationsScreen(
          key: ValueKey('g5-inbox-1p3x'),
          preset: G5InboxPreset.signedIn,
        ),
        1.3,
      ),
      (
        'g5-inbox-guest',
        const NotificationsScreen(
          key: ValueKey('g5-inbox-guest'),
          preset: G5InboxPreset.guest,
        ),
        1,
      ),
      ('g5-tulong-approved', const TulongApprovedPage(), 1),
      ('g5-correction-focus', const CorrectionFocusPage(), 1),
      (
        'g5-advisory-detail',
        const AdvisoryDetailPage(key: ValueKey('advisory')),
        1,
      ),
      (
        'g5-advisory-hotline',
        const AdvisoryDetailPage(key: ValueKey('hotline'), hotlineOpen: true),
        1,
      ),
      ('g5-evac-detail-notif', const EvacUpdatePage(), 1),
      ('g5-tulong-program', const TulongProgramPage(), 1),
      ('g5-deeplink-stale', const StaleDeepLinkPage(), 1),
      ('g5-guest-gate', const GuestGatePage(destination: SizedBox.shrink()), 1),
    ];

    for (final (name, frame, scale) in frames) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: frame,
        ),
      );
      await tester.pump();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      if (images.isNotEmpty) {
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
        expect(failure, isNull);
      }
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
    }
    debugDisableShadows = previousShadows;
  });
}
