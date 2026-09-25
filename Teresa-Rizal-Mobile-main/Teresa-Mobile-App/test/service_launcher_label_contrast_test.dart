// The service launcher's labels must carry their own contrast.
//
// The menu deliberately uses a 12% scrim rather than a modal barrier, so the
// screen behind it stays readable. On Home that screen includes a full-bleed
// event poster, and until 2026-08-30 the brand-blue "Dokyu" / "Tulong" labels
// were painted straight onto it - blue text over a dark photograph, colliding
// with the poster's own white lettering. Observed on a device; no test looked,
// because nothing was wrong with the widget in isolation.
//
// The bubble above each label had always solved this for itself with a white
// ring. The labels now do the same.
//
// This asserts the RENDERED decoration, not the source: a check that greps for
// a Container would pass on a Container with no colour, and a check on the
// TextStyle would pass on blue-on-blue.
import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/widgets/service_launcher_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Opens the launcher over a deliberately dark backdrop - the condition the
  /// device walk was in when the labels disappeared.
  Future<void> openOverDarkBackdrop(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.navy900,
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    ServiceLauncherMenu.show(ctx, onSelect: (_) {});
    await tester.pumpAndSettle();
  }

  tearDown(() {
    if (ServiceLauncherMenu.isOpen) ServiceLauncherMenu.dismiss();
  });

  for (final label in ['Dokyu', 'Tulong']) {
    testWidgets('the $label label sits on an opaque backing', (tester) async {
      await openOverDarkBackdrop(tester);
      expect(find.text(label), findsOneWidget, reason: 'the launcher did not open');

      // Walk the label's ancestors for a painted, opaque background. Any of
      // them will do - what matters is that something behind the glyphs is
      // solid, not which widget provides it.
      final backings = tester
          .widgetList<Container>(find.ancestor(of: find.text(label), matching: find.byType(Container)))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null && d.color!.a == 1.0)
          .toList();

      expect(
        backings,
        isNotEmpty,
        reason:
            'the $label label has no opaque background, so it is only as legible '
            'as whatever happens to be behind the menu. The scrim is 12% by '
            'design - back the label instead of darkening it.',
      );
    });
  }

  testWidgets('the scrim stays light - the fix must not become a modal barrier', (tester) async {
    await openOverDarkBackdrop(tester);

    // The one full-screen tinted layer is the dismiss barrier. If a future
    // change "fixes" legibility by darkening it, the menu stops reading as an
    // overlay and the content behind it is lost - which is the thing the
    // label backing exists to avoid having to do.
    final scrims = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.color)
        .whereType<Color>()
        .where((c) => c.a > 0 && c.a < 1.0)
        .toList();

    expect(scrims, isNotEmpty, reason: 'no translucent scrim found at all - has the menu changed shape?');
    for (final c in scrims) {
      expect(
        c.a,
        lessThan(0.3),
        reason: 'the scrim darkened to ${c.a} - it is meant to tint, not to cover',
      );
    }
  });

  testWidgets('a disposed launcher releases the static it registered', (tester) async {
    await openOverDarkBackdrop(tester);
    expect(ServiceLauncherMenu.isOpen, isTrue);

    // A genuine teardown. Pumping another MaterialApp does NOT do this -
    // the element types match, so the framework updates the tree in place,
    // the Overlay survives and dispose never runs. (That is also why signing
    // out in the real app does not reach this: one MaterialApp, one root
    // navigator, and the entry is inserted with rootOverlay: true. No user
    // path to the leak has been demonstrated - this guards the invariant, not
    // a reproduced defect.) A root of a different type forces the rebuild.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(
      ServiceLauncherMenu.isOpen,
      isFalse,
      reason:
          'the static still points at a disposed State. show() early-returns '
          'while it is set, so the "+" that opens Dokyu and Tulong would stay '
          'dead for the rest of the process, and dismiss() would call reverse() '
          'on a disposed controller.',
    );

    // And the button must actually work again, which is the thing a citizen
    // would notice - isOpen going false is only the mechanism.
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          }),
        ),
      ),
    );
    ServiceLauncherMenu.show(ctx, onSelect: (_) {});
    await tester.pumpAndSettle();
    expect(find.text('Dokyu'), findsOneWidget, reason: 'the launcher would not reopen');
  });
}
