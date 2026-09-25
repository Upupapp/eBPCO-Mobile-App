// Regression test for RenderFlex/overflow on the new Privacy Policy and
// Help & Support screens — same technique as resident_profile_overflow_test.dart:
// render each screen at a spread of device widths/text scales, assert zero
// layout exceptions. A second pass expands every accordion panel at the
// narrowest width, since that's where long FAQ/policy body text is most
// likely to overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/screens/legal/privacy_policy_screen.dart';
import 'package:teresa_rizal/screens/support/help_support_screen.dart';
import 'package:teresa_rizal/screens/support/report_problem_screen.dart';
import 'package:teresa_rizal/widgets/expandable_panel.dart';

void main() {
  final sizes = <String, Size>{
    'extreme narrow (280x568)': const Size(280, 568),
    'small (320x568)': const Size(320, 568),
    'normal (360x800)': const Size(360, 800),
    'large (412x915)': const Size(412, 915),
  };

  final screens = <String, Widget Function()>{
    'PrivacyPolicyScreen': () => const PrivacyPolicyScreen(),
    'HelpSupportScreen': () => const HelpSupportScreen(),
    'ReportProblemScreen': () => const ReportProblemScreen(),
  };

  for (final screenEntry in screens.entries) {
    for (final sizeEntry in sizes.entries) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets('${screenEntry.key} has zero overflow at ${sizeEntry.key}, textScale $textScale', (tester) async {
          tester.view.physicalSize = sizeEntry.value;
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(MaterialApp(home: screenEntry.value()));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final screenEntry in {
    'PrivacyPolicyScreen': () => const PrivacyPolicyScreen(),
    'HelpSupportScreen': () => const HelpSupportScreen(),
  }.entries) {
    testWidgets('${screenEntry.key} has zero overflow with every panel expanded at extreme narrow (280x568)', (
      tester,
    ) async {
      // A very tall viewport (width still the narrowest supported phone) so
      // the whole ListView builds in a single pass instead of only its
      // visible window — a plain ListView only builds items near the
      // viewport, so without this, every panel below the fold wouldn't
      // exist as a widget yet and this sweep couldn't find or tap it.
      tester.view.physicalSize = const Size(280, 20000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: screenEntry.value()));
      await tester.pumpAndSettle();

      final titles = tester.widgetList<ExpandablePanel>(find.byType(ExpandablePanel)).map((p) => p.title).toList();
      for (final title in titles) {
        final headerFinder = find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;
        await tester.tap(headerFinder, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
