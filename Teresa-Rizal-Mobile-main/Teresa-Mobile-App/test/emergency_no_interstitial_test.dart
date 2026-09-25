// Nothing pops over the Emergency screen.
//
// RootShell offers a full-screen promotional banner the first time each tab is
// opened in a session. That is a deliberate, well-built feature — a Set keyed by
// page so one popup's dismissal never eats another's, and an access-level gate
// so it never floats over a RestrictedFeatureNotice.
//
// It was wrong on exactly one tab. Observed on a device 2026-08-30: opening Risk
// Reduction & Emergency raised a full-screen popup over the red "In a
// life-threatening emergency, call 911 or MDRRMO directly" banner and the
// evacuation-centre list. On every other tab an interstitial costs a tap. There
// it costs time, to someone who may not have any.
//
// This test exists because the fix is the ABSENCE of a map entry, and absences
// are exactly what gets restored by accident — a merge, a revert, or someone
// tidying the map back into a tidy 1..5 sequence.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File('lib/screens/home/root_shell.dart').readAsStringSync();

  test('the Emergency page has no promotional interstitial', () {
    // The map is `index: (asset, label, requiredLevel)`. Any entry whose label
    // is Emergency puts a popup over the emergency screen.
    final entry = RegExp(r"\d+:\s*\([^)]*'Emergency'[^)]*\)").firstMatch(shell);
    expect(
      entry?.group(0),
      isNull,
      reason:
          'A promotional banner is registered for the Emergency page:\n'
          '  ${entry?.group(0)}\n\n'
          'It covers the "call 911 or MDRRMO directly" banner and the evacuation '
          'centre list, and must be dismissed before either can be used. Every '
          'other tab may have one; this one may not.',
    );
  });

  test('the other tabs keep theirs — this is a targeted removal, not a purge', () {
    // If someone "fixes" the popup problem by deleting the feature, this fails.
    // The LGU commissioned six of these assets; only one placement was wrong.
    for (final label in ['Balita', 'Events', 'Dokyu', 'Tulong']) {
      expect(
        shell,
        contains("'$label'"),
        reason:
            '$label lost its promotional banner — only Emergency should have been removed',
      );
    }
  });

  test('the Emergency poster is not shipped', () {
    // That file carried another municipality's seal. The screen does not
    // paint it, and it must not stay in the bundle.
    expect(File('assets/images/Emergency.png').existsSync(), isFalse);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('assets/images/Emergency.png')),
    );
  });
}
