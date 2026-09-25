// 390×844 logical (780×1688 px at 2×) Inter captures for Pack D.
// Run: flutter test --dart-define=PACK_D_SHOTS=true test/pack_d_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/screens/requests/pack_d/pack_d_frame.dart';
import 'package:teresa_rizal/theme/app_theme.dart';

const _capture = bool.fromEnvironment('PACK_D_SHOTS');

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

class _WriteComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final file = File('/opt/cursor/artifacts/pack-d/${golden.pathSegments.last}');
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
  testWidgets('Pack D frames at 390x844 logical, 2x, with Inter', (tester) async {
    if (!_capture) return;

    final previous = goldenFileComparator;
    goldenFileComparator = _WriteComparator();
    addTearDown(() => goldenFileComparator = previous);

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(_loadShotFonts);

    for (final frame in packDShotFrames) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: PackDFrameScreen(
            frame: frame,
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
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('${frame.fileName}.png'),
      );
    }
  });
}
