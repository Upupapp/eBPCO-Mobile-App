import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The iOS privacy manifest (merged from eBPCOMobile's guard): it must stay
/// part of the Runner build, and declare what this app actually sends.
void main() {
  final manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
  final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  test('the manifest is bundled with the Runner target', () {
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(RegExp('PrivacyInfo.xcprivacy').allMatches(project).length, greaterThanOrEqualTo(4));
  });

  test('no tracking is declared', () {
    expect(manifest, matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')));
  });

  test('everything the app sends is declared', () {
    for (final type in [
      'Name', 'EmailAddress', 'PhoneNumber', 'PhysicalAddress', 'UserID', 'DeviceID',
      'OtherFinancialInfo', 'PhotosorVideos', 'OtherUserContent', 'OtherDataTypes',
    ]) {
      expect(manifest, contains('NSPrivacyCollectedDataType$type'), reason: type);
    }
  });

  test('the push token is declared because the app sends it', () {
    final api = File('lib/core/api/citizen_api.dart').readAsStringSync();
    expect(api, contains("'/devices'"));
    expect(manifest, contains('NSPrivacyCollectedDataTypeDeviceID'));
  });
}
