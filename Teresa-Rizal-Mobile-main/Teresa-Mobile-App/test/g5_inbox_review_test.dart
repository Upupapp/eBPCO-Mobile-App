// UI-review fixes: filter chips scroll into view, newest-first within a day,
// and the category line stays on one row at 1.3x.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/screens/notifications/g5/g5_samples.dart';
import 'package:teresa_rizal/screens/notifications/notifications_screen.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';

void _phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home, {double textScale = 1}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: home,
  );
}

void _expectChipInView(WidgetTester tester, String keyName) {
  final chip = tester.getRect(find.byKey(ValueKey('inbox-filter-$keyName')));
  final view = tester.getRect(find.byKey(const ValueKey('inbox-filters')));
  expect(
    chip.left,
    greaterThanOrEqualTo(view.left - 1),
    reason: '$keyName left',
  );
  expect(
    chip.right,
    lessThanOrEqualTo(view.right + 1),
    reason: '$keyName right',
  );
}

Text _chipLabel(WidgetTester tester, String keyName, String label) {
  return tester.widget<Text>(
    find.descendant(
      of: find.byKey(ValueKey('inbox-filter-$keyName')),
      matching: find.text(label),
    ),
  );
}

void main() {
  testWidgets(
    'selecting Advisories filters the list and scrolls the chip into view',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(const NotificationsScreen(preset: G5InboxPreset.signedIn)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Scholarship approved'), findsOneWidget);
      final filters = find.descendant(
        of: find.byKey(const ValueKey('inbox-filters')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('inbox-filter-advisories')),
        60,
        scrollable: filters,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('inbox-filter-advisories')));
      await tester.pumpAndSettle();

      expect(
        _chipLabel(tester, 'advisories', 'Advisories').style?.color,
        SoftColors.white,
      );
      expect(
        _chipLabel(tester, 'all', 'All').style?.color,
        isNot(SoftColors.white),
      );
      _expectChipInView(tester, 'advisories');
      expect(find.text('Heavy rain & flood advisory'), findsOneWidget);
      expect(find.text('Teresa Municipal Gym is open'), findsOneWidget);
      expect(find.text('Scholarship approved'), findsNothing);
      expect(find.text('Health Caravan this Sunday'), findsNothing);
      expect(find.text('Educational Assistance now open'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a reused inbox state follows the next preset filter', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(const NotificationsScreen(preset: G5InboxPreset.signedIn)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Scholarship approved'), findsOneWidget);

    // No key: pumpWidget keeps the same State, so initState does not run again.
    await tester.pumpWidget(
      _app(const NotificationsScreen(preset: G5InboxPreset.advisories)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scholarship approved'), findsNothing);
    expect(find.text('Barangay clearance needs correction'), findsNothing);
    expect(find.text('Heavy rain & flood advisory'), findsOneWidget);
    expect(find.text('Teresa Municipal Gym is open'), findsOneWidget);
    expect(
      _chipLabel(tester, 'advisories', 'Advisories').style?.color,
      SoftColors.white,
    );
    _expectChipInView(tester, 'advisories');
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('inbox-filters')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Events filter is empty and Show all restores newest-first order',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(const NotificationsScreen(preset: G5InboxPreset.emptyEvents)),
      );
      await tester.pumpAndSettle();

      expect(
        _chipLabel(tester, 'events', 'Events').style?.color,
        SoftColors.white,
      );
      _expectChipInView(tester, 'events');
      expect(find.text('No event notifications'), findsOneWidget);
      expect(find.text('Browse Events'), findsOneWidget);
      expect(find.text('Show all notifications'), findsOneWidget);
      expect(
        find.textContaining(
          'Filters sort local samples on this device and never delete.',
        ),
        findsOneWidget,
      );
      expect(find.text('Health Caravan this Sunday'), findsNothing);
      expect(find.text('Scholarship approved'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('g5-show-all')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'all', 'All').style?.color, SoftColors.white);
      _expectChipInView(tester, 'all');
      expect(find.text('No event notifications'), findsNothing);
      final flood = tester
          .getTopLeft(find.text('Heavy rain & flood advisory'))
          .dy;
      final scholarship = tester
          .getTopLeft(find.text('Scholarship approved'))
          .dy;
      final gym = tester
          .getTopLeft(find.text('Teresa Municipal Gym is open'))
          .dy;
      expect(flood, lessThan(scholarship));
      expect(scholarship, lessThan(gym));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('category line has no subtype and does not overflow at 1.3x', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const NotificationsScreen(preset: G5InboxPreset.signedIn),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dokyu'), findsWidgets);
    expect(find.text('Tulong'), findsWidgets);
    expect(find.text('Advisory'), findsWidgets);
    expect(find.textContaining('Action ne'), findsNothing);
    expect(find.text('8:10 AM'), findsOneWidget);
    expect(find.text('Urgent'), findsWidgets);

    final scroll = find.descendant(
      of: find.byKey(const ValueKey('inbox-list')),
      matching: find.byType(Scrollable),
    );
    for (final clock in ['8:10 AM', '7:45 AM', '7:02 AM', '6:30 AM']) {
      await tester.scrollUntilVisible(find.text(clock), 200, scrollable: scroll);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(clock));
      expect(paragraph.didExceedMaxLines, isFalse, reason: clock);
    }

    await tester.scrollUntilVisible(
      find.text('Health Caravan this Sunday'),
      240,
      scrollable: scroll,
    );
    expect(find.text('Balita'), findsWidgets);
    expect(find.text('Event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
