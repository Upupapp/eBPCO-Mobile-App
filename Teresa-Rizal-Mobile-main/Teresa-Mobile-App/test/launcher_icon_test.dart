// The app must ship the Municipality of Teresa, Rizal's seal, never Flutter's logo.
//
// Until 2026-08-29 every launcher icon was byte-identical to the Flutter SDK's
// template art. That was not a cosmetic problem: on Android 12+ the system
// splash is derived from the launcher icon, so the Flutter logo was the first
// thing every citizen saw on every cold start, and it was the app's face in the
// launcher.
//
// Icons are generated, never hand-edited:
//
//     dart run flutter_launcher_icons
//
// with the config in `pubspec.yaml` and the source art in `tool/icon/`.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

/// MD5 of the stock Flutter launcher icon at each density, Flutter 3.47.0.
///
/// A denylist of the exact art that was here, rather than a comparison against
/// whatever the installed SDK happens to ship: the SDK is not guaranteed to be
/// present, and a test that quietly skips when it cannot find something reads as
/// a pass. If a future Flutter changes its template art these hashes go stale in
/// the safe direction — they can no longer match, so the test cannot start
/// failing wrongly.
const _flutterDefaultIcons = <String, String>{
  'mdpi': '6270344430679711b81476e29878caa7',
  'hdpi': '13e9c72ec37fac220397aa819fa1ef2d',
  'xhdpi': 'a0a8db5985280b3679d99a820ae2db79',
  'xxhdpi': 'afe1b655b9f32da22f9a4301bb8e6ba8',
  'xxxhdpi': '57838d52c318faff743130c3fcfae0c6',
};

/// The colour-type byte of a PNG's IHDR chunk.
///
/// Layout: 8-byte signature, then the IHDR chunk — 4 length, 4 type, 4 width,
/// 4 height, 1 bit-depth, then colour type at offset 25. Types 4 (grey+alpha)
/// and 6 (RGBA) carry an alpha channel.
int _pngColourType(File f) => f.readAsBytesSync()[25];

bool _hasAlphaChannel(File f) {
  final type = _pngColourType(f);
  return type == 4 || type == 6;
}

String _md5(File f) => md5.convert(f.readAsBytesSync()).toString();

void main() {
  group('Android launcher icon', () {
    test('exists at every density and is not Flutter\'s default art', () {
      final flutterDefaults = <String>[];
      var checked = 0;

      for (final density in _densities) {
        final file = File('android/app/src/main/res/mipmap-$density/ic_launcher.png');
        expect(file.existsSync(), isTrue, reason: 'missing launcher icon for $density');
        checked++;

        expect(file.lengthSync(), greaterThan(0), reason: '$density icon is empty');
        if (_md5(file) == _flutterDefaultIcons[density]) flutterDefaults.add(density);
      }

      expect(checked, _densities.length, reason: 'not every density was examined');
      expect(
        flutterDefaults,
        isEmpty,
        reason: 'These densities still ship Flutter\'s logo: ${flutterDefaults.join(', ')}. '
            'Regenerate with `dart run flutter_launcher_icons`.',
      );
    });

    test('has an adaptive icon wired to the seal foreground', () {
      // Android 12+ derives the cold-start splash from this.
      final xml = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
      expect(xml.existsSync(), isTrue, reason: 'no adaptive icon — Android 8+ will letterbox the legacy one');

      final source = xml.readAsStringSync();
      expect(source, contains('ic_launcher_foreground'));
      expect(source, contains('ic_launcher_background'));

      for (final density in _densities) {
        expect(
          File('android/app/src/main/res/drawable-$density/ic_launcher_foreground.png').existsSync(),
          isTrue,
          reason: 'missing adaptive foreground for $density',
        );
      }
    });

    test('the Android 12+ splash is configured, not left to the platform default', () {
      // Without this the platform draws the adaptive icon's foreground alone on
      // the window background, so the seal loses its white plate and its black
      // outer ring sinks into the navy.
      final styles = File('android/app/src/main/res/values-v31/styles.xml');
      expect(styles.existsSync(), isTrue);

      final source = styles.readAsStringSync();
      expect(source, contains('windowSplashScreenBackground'));
      expect(source, contains('windowSplashScreenAnimatedIcon'));
    });
  });

  group('iOS app icon', () {
    test('has no alpha channel — the App Store rejects icons that do', () {
      final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(dir.existsSync(), isTrue);

      final pngs = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();
      expect(pngs.length, greaterThan(10), reason: 'found ${pngs.length} icons — the icon set looks incomplete');

      final withAlpha = pngs.where(_hasAlphaChannel).map((f) => f.uri.pathSegments.last).toList()..sort();
      expect(
        withAlpha,
        isEmpty,
        reason: 'iOS app icons with an alpha channel:\n  ${withAlpha.join('\n  ')}\n'
            'Submission is rejected for this. `remove_alpha_ios: true` in the '
            'flutter_launcher_icons config handles it — regenerate.',
      );
    });
  });
}
