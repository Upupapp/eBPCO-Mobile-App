// Four branch tabs plus a raised Services control. The aperture travels
// in 320ms ease-out-cubic and never sits on Services.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_nav_item.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_nav_motion.dart';
import 'package:teresa_rizal/widgets/nav_item_data.dart';

const _items = [
  NavItemData(
    outlineIcon: Icons.home_outlined,
    filledIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavItemData(
    outlineIcon: Icons.campaign_outlined,
    filledIcon: Icons.campaign_rounded,
    label: 'Balita',
  ),
  NavItemData(
    outlineIcon: Icons.event_outlined,
    filledIcon: Icons.event_rounded,
    label: 'Events',
  ),
  NavItemData(
    outlineIcon: Icons.person_outline_rounded,
    filledIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int index = 0;
  int centerTaps = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: TeresaRizalCurvedNavBar(
          items: _items,
          activeIndex: index,
          onTabSelected: (i) => setState(() => index = i),
          onCenterPressed: () => setState(() => centerTaps += 1),
        ),
      ),
    );
  }
}

double _indicatorLeft(WidgetTester tester) {
  return tester.getTopLeft(find.byType(TeresaRizalActiveBubble)).dx;
}

double _expectedRestingLeft(WidgetTester tester, int branchIndex) {
  final bar = tester.getRect(find.byKey(const ValueKey('nav-bar-shape')));
  return bar.left +
      TeresaRizalNavMotion.bubbleLeft(
        width: bar.width,
        branchIndex: branchIndex,
      );
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  test('aperture and page use the Servana branch timings', () {
    expect(TeresaRizalNavMotion.selection, const Duration(milliseconds: 320));
    expect(TeresaRizalNavMotion.page, const Duration(milliseconds: 260));
    expect(TeresaRizalNavMotion.selectionCurve, Curves.easeOutCubic);
    expect(TeresaRizalNavMotion.pageCurve, Curves.easeOutCubic);
    expect(TeresaRizalNavMotion.pageRiseOffset, 8);
    expect(TeresaRizalNavMotion.pageStartScale, 0.985);
    expect(TeresaRizalNavMotion.press, const Duration(milliseconds: 90));
    expect(TeresaRizalNavMotion.pressRelease, const Duration(milliseconds: 70));
    expect(TeresaRizalNavMotion.pressScale, 0.94);
    expect(TeresaRizalNavMotion.releaseScale, 1.03);
    expect(TeresaRizalNavMotion.bubbleDiameter, 52);
    expect(TeresaRizalNavMotion.centerDiameter, 56);
    expect(TeresaRizalNavMotion.barHeight, 72);
    expect(
      TeresaRizalNavMotion.reducedDuration,
      const Duration(milliseconds: 100),
    );
  });

  testWidgets(
    'one aperture, one pill, and a Services control that is not a tab',
    (tester) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('nav-floating-indicator')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('nav-bar-shape')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-center-action')), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);

      final start = _indicatorLeft(tester);
      await tester.tap(find.byKey(const ValueKey('nav-center-action')));
      await tester.pumpAndSettle();
      expect(_indicatorLeft(tester), start);
      expect(tester.state<_HarnessState>(find.byType(_Harness)).index, 0);
      expect(tester.state<_HarnessState>(find.byType(_Harness)).centerTaps, 1);

      for (final text in tester.widgetList<Text>(find.text('Home'))) {
        if (text.style?.fontWeight == FontWeight.w700) {
          fail('nav label used Bold 700');
        }
      }
      final home = tester.widget<Text>(find.text('Home'));
      expect(home.style?.fontWeight, FontWeight.w500);
      final services = tester.widget<Text>(find.text('Services'));
      expect(services.style?.fontWeight, isNot(FontWeight.w700));
      expect(services.style?.fontWeight, isNot(FontWeight.w500));
    },
  );

  testWidgets(
    'the aperture moves during a long trip and skips the center slot',
    (tester) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();

      final start = _indicatorLeft(tester);
      await _tapTab(tester, 'Profile');
      await tester.pump(const Duration(milliseconds: 120));
      final mid = _indicatorLeft(tester);
      expect(mid, greaterThan(start + 1));

      await tester.pumpAndSettle();
      final end = _indicatorLeft(tester);
      expect(mid, lessThan(end - 1));
      expect(end, closeTo(_expectedRestingLeft(tester, 3), 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  final transitions = <List<String>>[
    ['Home', 'Balita'],
    ['Balita', 'Events'],
    ['Events', 'Profile'],
    ['Profile', 'Home'],
    ['Home', 'Events'],
    ['Home', 'Profile'],
    ['Profile', 'Balita'],
  ];

  for (final t in transitions) {
    final from = t[0];
    final to = t[1];
    testWidgets('$from -> $to: aperture settles on the destination branch', (
      tester,
    ) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();

      final fromIndex = _items.indexWhere((i) => i.label == from);
      final toIndex = _items.indexWhere((i) => i.label == to);

      if (fromIndex != 0) {
        await _tapTab(tester, from);
        await tester.pumpAndSettle();
      }
      final startLeft = _indicatorLeft(tester);

      await _tapTab(tester, to);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final settledLeft = _indicatorLeft(tester);
      expect(settledLeft, closeTo(_expectedRestingLeft(tester, toIndex), 0.5));
      if (fromIndex != toIndex) {
        expect(settledLeft, isNot(closeTo(startLeft, 0.5)));
      }
    });
  }

  testWidgets(
    'interrupted mid-flight tap (Home -> Profile -> Balita) settles on Balita',
    (tester) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();

      await _tapTab(tester, 'Profile');
      await tester.pump(const Duration(milliseconds: 80));
      await _tapTab(tester, 'Balita');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        _indicatorLeft(tester),
        closeTo(_expectedRestingLeft(tester, 1), 0.5),
      );
    },
  );

  testWidgets('aperture top never changes across branches', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    double topOf(WidgetTester t) => t
        .widget<AnimatedPositioned>(
          find.byKey(const ValueKey('nav-floating-indicator')),
        )
        .top!;

    final initialTop = topOf(tester);
    expect(initialTop, TeresaRizalNavMotion.bubbleTop);

    for (final label in ['Balita', 'Events', 'Profile', 'Home']) {
      await _tapTab(tester, label);
      await tester.pumpAndSettle();
      expect(topOf(tester), initialTop);
    }
  });

  testWidgets(
    'every branch label stays visible, and Services stays visible too',
    (tester) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();

      const labels = ['Home', 'Balita', 'Events', 'Profile', 'Services'];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }

      await _tapTab(tester, 'Profile');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('reduced motion shortens the aperture trip', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();
    await _tapTab(tester, 'Profile');
    await tester.pump(TeresaRizalNavMotion.reducedDuration);
    await tester.pump();
    expect(
      _indicatorLeft(tester),
      closeTo(_expectedRestingLeft(tester, 3), 0.5),
    );
  });
}
