// The name under the icon must be the same on Android and iOS, and must fit.
//
// Two separate defects lived here:
//
//   * Android's `android:label` was the snake_case package id `teresa_rizal`,
//     so the home screen showed a developer identifier while iOS showed a real
//     name. The two platforms disagreed and Android was the wrong one.
//   * Once both said "Teresa, Rizal Mobile", it was measured **truncating** to
//     "Teresa, Rizal M…" in the Pixel 8 app drawer at sixteen characters, while
//     neighbouring apps ("Play Store", "Messages", "Calendar") fit. iOS would
//     truncate identically, since CFBundleDisplayName carried the same string.
//
// The owner chose `Teresa, Rizal` for both home screens on 2026-08-29, keeping
// "Teresa, Rizal Mobile" as the full product name where there is room — the web
// manifest `name`, and the browser tab title. `short_name` in the web manifest
// exists for exactly this distinction and already carried it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The name shown under the launcher icon. One string, both platforms.
const _homeScreenName = 'Teresa, Rizal';

/// The full product name, used where length is not constrained.
const _productName = 'Teresa, Rizal Mobile';

/// Measured budget, not a guess: at 16 characters the Pixel 8 drawer showed
/// "Teresa, Rizal M…". This is a floor under that finding — if a longer name is ever
/// wanted, re-measure on a launcher and move this with the evidence, rather than
/// deleting it.
const _maxHomeScreenNameLength = 13;

String _androidLabel() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final match = RegExp(r'android:label="([^"]*)"').firstMatch(manifest);
  expect(match, isNotNull, reason: 'no android:label found in AndroidManifest.xml');
  return match!.group(1)!;
}

String _iosDisplayName() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  // <key>CFBundleDisplayName</key> followed by its <string> value.
  final match = RegExp(
    r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
    multiLine: true,
  ).firstMatch(plist);
  expect(match, isNotNull, reason: 'no CFBundleDisplayName found in Info.plist');
  return match!.group(1)!.trim();
}

void main() {
  test('Android and iOS show the same name under the icon', () {
    expect(
      _androidLabel(),
      _iosDisplayName(),
      reason: 'the home-screen name differs between platforms — it is one product, one name',
    );
  });

  test('that name is the one the owner chose', () {
    expect(_androidLabel(), _homeScreenName);
    expect(_iosDisplayName(), _homeScreenName);
  });

  test('the name is not a scaffold identifier', () {
    for (final name in [_androidLabel(), _iosDisplayName()]) {
      expect(name, isNot(contains('_')), reason: '"$name" looks like a package id, not a product name');
      expect(name.toLowerCase(), isNot('teresa_rizal'));
      expect(name.trim(), isNotEmpty);
    }
  });

  test('the name fits a launcher grid', () {
    expect(
      _homeScreenName.length,
      lessThanOrEqualTo(_maxHomeScreenNameLength),
      reason: 'measured: 16 characters truncated to "Teresa, Rizal M…" in the Pixel 8 drawer',
    );
  });

  test('the full product name survives where there is room', () {
    // Shortening the home-screen name must not quietly shorten the product
    // everywhere — the store listing and the PWA install prompt use these.
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"name": "$_productName"'));
    expect(manifest, contains('"short_name": "$_homeScreenName"'));

    final index = File('web/index.html').readAsStringSync();
    expect(index, contains('<title>$_productName</title>'));
    // "Add to Home Screen" on iOS Safari is a home screen, so it takes the short one.
    expect(index, contains('content="$_homeScreenName"'));
  });

  test('CFBundleName stays within Apple\'s 15-character guidance', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final match = RegExp(r'<key>CFBundleName</key>\s*<string>([^<]*)</string>').firstMatch(plist);
    expect(match, isNotNull);
    expect(match!.group(1)!.length, lessThanOrEqualTo(15));
  });
}
