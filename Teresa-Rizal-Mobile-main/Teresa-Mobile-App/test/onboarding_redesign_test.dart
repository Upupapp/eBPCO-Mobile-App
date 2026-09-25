// How the redesigned onboarding presents itself: depth, motion preferences,
// screen sizes, semantics, and whether the words are true.
//
// `onboarding_flow_test.dart` covers where the controls lead and what gets
// persisted. This file covers the parts that used to be untestable, because
// until 2026-08-30 each page was a single flattened PNG — a screen reader saw
// nothing, text scaling did nothing, and the copy could not be checked at all.
// The artwork advertised "Business Permit — Approved", an outcome this app
// cannot produce (there is no backend), and no test could have noticed.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/screens/onboarding/onboarding_page_data.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_screen.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';

/// Pumps onboarding on its own, at a chosen viewport / text scale / motion
/// preference.
///
/// The `MaterialApp.builder` override is deliberate: `WidgetsApp` installs its
/// own `MediaQuery` from the view, so wrapping the app in one has no effect —
/// the override has to sit *inside*, between the app and its content.
Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool reduceMotion = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: const OnboardingScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Starts a drag on the PHOTOGRAPH — never on the copy — and steps it.
///
/// Both details were measured, and a test written without either passes
/// against a screen where swiping does not work at all:
///
///  * the copy and controls sit in a bottom `Scrollable`, which hit-tests
///    opaquely, so a drag begun over the headline never reaches the pager
///    (240px of drag at y=422 moved `pixels` by 0.0; the same drag at y=150
///    moved it 240px);
///  * the first move of a gesture is spent winning the gesture arena, so one
///    large `moveBy` scrolls nothing.
Future<TestGesture> _dragPhotoAndHold(
  WidgetTester tester, {
  double by = -140,
}) async {
  final origin = tester.getTopLeft(find.byType(PageView));
  final gesture = await tester.startGesture(
    Offset(origin.dx + 160, origin.dy + 180),
  );
  const steps = 7;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(by / steps, 0));
    await tester.pump();
  }
  return gesture;
}

Future<void> _swipeToNextPage(WidgetTester tester) async {
  final gesture = await _dragPhotoAndHold(tester, by: -320);
  await gesture.up();
  await tester.pumpAndSettle();
}

/// The horizontal translation a keyed parallax layer is currently carrying.
double _tx(WidgetTester tester, String key) =>
    tester.widget<Transform>(find.byKey(Key(key))).transform.getTranslation().x;

/// Every string the tree is currently rendering.
List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  // ---------------------------------------------------------------------
  // The swipe surface
  // ---------------------------------------------------------------------

  testWidgets('the photograph is a swipe surface', (tester) async {
    await _pump(tester);

    // Regression guard for a defect that shipped in the first draft of this
    // redesign: the whole interface was wrapped in one full-screen
    // SingleChildScrollView laid over the PageView. A Scrollable hit-tests
    // opaquely, so it swallowed every pointer and swiping between pages did
    // nothing on a device — only the Next button worked. Nothing failed; the
    // screen simply stopped responding to the gesture it looks like it wants.
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    final gesture = await _dragPhotoAndHold(tester);

    expect(
      controller.position.pixels,
      greaterThan(0),
      reason:
          'a drag on the photograph moved the pager by nothing — something opaque is over it',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  // ---------------------------------------------------------------------
  // Parallax
  // ---------------------------------------------------------------------

  testWidgets('the photograph lags the chips over it', (tester) async {
    await _pump(tester);
    final gesture = await _dragPhotoAndHold(tester);

    final background = _tx(tester, 'onboarding_background_0').abs();
    final chips = _tx(tester, 'onboarding_chips').abs();

    // Relative, not pixel values: the factors are a design choice and should be
    // free to change. What must not change is that there IS depth — one
    // flattened layer would make these equal, which is exactly the "parallax"
    // the retired composite artwork could offer.
    expect(
      background,
      greaterThan(0),
      reason: 'the photograph did not move at all',
    );
    expect(
      chips,
      greaterThan(background),
      reason: 'the chips must travel further than the photograph behind them',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('every page has a keyed background layer', (tester) async {
    await _pump(tester);
    for (var i = 0; i < onboardingScenes.length; i++) {
      if (i > 0) await _swipeToNextPage(tester);
      expect(
        find.byKey(Key('onboarding_background_$i')),
        findsOneWidget,
        reason: 'page $i lost its background layer',
      );
    }
  });

  // ---------------------------------------------------------------------
  // Reduced motion
  // ---------------------------------------------------------------------

  testWidgets('reduced motion: parallax is zero, and the page is fully usable', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: true);

    // The content is all there, at full strength — reduced motion removes
    // movement, not hierarchy or information.
    expect(find.text(onboardingScenes[0].headline), findsOneWidget);
    expect(find.text(onboardingScenes[0].subtext), findsOneWidget);
    for (final f in onboardingScenes[0].features) {
      expect(find.text(f.label), findsOneWidget);
    }

    final gesture = await _dragPhotoAndHold(tester);
    for (final layer in ['onboarding_background_0', 'onboarding_chips']) {
      expect(
        _tx(tester, layer),
        0,
        reason:
            '$layer still translates under reduced motion — it must be exactly zero, not merely small',
      );
    }
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'reduced motion: Next still advances, without waiting out an animation',
    (tester) async {
      await _pump(tester, reduceMotion: true);

      await tester.tap(find.byKey(const Key('onboarding_next')));
      // A single pump, NOT pumpAndSettle: under reduced motion the page change is
      // a jump, so one frame is enough. If this ever needs settling again, an
      // animation has come back that reduced-motion users were promised they
      // would not have to sit through.
      await tester.pump();

      expect(find.text(onboardingScenes[1].headline), findsOneWidget);
      expect(find.text(onboardingScenes[0].headline), findsNothing);
    },
  );

  // ---------------------------------------------------------------------
  // Responsiveness
  // ---------------------------------------------------------------------

  const viewports = <String, Size>{
    'compact 320x568': Size(320, 568),
    'small 360x800': Size(360, 800),
    'reference 390x844': Size(390, 844),
    'large 412x915': Size(412, 915),
    'tablet 834x1112': Size(834, 1112),
    'landscape 844x390': Size(844, 390),
  };

  for (final entry in viewports.entries) {
    for (final scale in <double>[1.0, 2.0]) {
      testWidgets('${entry.key} at text scale $scale lays out without overflow', (
        tester,
      ) async {
        await _pump(tester, size: entry.value, textScale: scale);

        expect(
          tester.takeException(),
          isNull,
          reason:
              'onboarding overflowed or threw at ${entry.key}, text scale $scale',
        );

        // Rendered something real, so a blank screen cannot pass as "no
        // overflow", and every control is still reachable.
        expect(find.text(onboardingScenes[0].headline), findsOneWidget);
        expect(find.byKey(const Key('onboarding_skip')), findsOneWidget);
        expect(find.byKey(const Key('onboarding_next')), findsOneWidget);
        expect(find.byKey(const Key('onboarding_progress')), findsOneWidget);

        // The supporting line must survive a small screen — hiding it to make
        // things fit is not a responsive layout, it is a shorter app for people
        // with smaller phones.
        expect(find.text(onboardingScenes[0].subtext), findsOneWidget);
      });
    }
  }

  testWidgets(
    'the page-2 caveat survives the smallest screen at the largest text',
    (tester) async {
      await _pump(tester, size: const Size(320, 568), textScale: 2.0);
      // Next, not a swipe. At this size and text scale the identity bar and
      // the bottom block between them cover the screen, so there is no
      // photograph left to start a drag on — the button is the only way
      // through, and it works. Worth writing down rather than papering over:
      // on the smallest handset at the largest text, onboarding becomes a
      // button-driven flow.
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();

      expect(find.text(onboardingScenes[1].note!), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // ---------------------------------------------------------------------
  // Semantics
  // ---------------------------------------------------------------------

  testWidgets(
    'the page position, Skip and the primary action are all announced',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip'), findsOneWidget);

      final next = tester.getSemantics(
        find.byKey(const Key('onboarding_next')),
      );
      expect(next.flagsCollection.isButton, isTrue);
      expect(next.label, contains('Next'));

      await _swipeToNextPage(tester);
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      await _swipeToNextPage(tester);
      expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);
      // The sealed comps keep Skip beside Get Started, so it stays announced.
      expect(find.bySemanticsLabel('Skip'), findsOneWidget);

      final start = tester.getSemantics(
        find.byKey(const Key('onboarding_get_started')),
      );
      expect(start.flagsCollection.isButton, isTrue);
      expect(start.label, contains('Get Started'));

      handle.dispose();
    },
  );

  testWidgets(
    'each photograph is described once, and the chips are not repeated',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        find.bySemanticsLabel(onboardingScenes[0].semanticDescription),
        findsOneWidget,
      );

      // Each capability appears exactly once as text. If the photograph ever
      // gains a caption naming the same things, a screen reader starts saying
      // them twice.
      for (final f in onboardingScenes[0].features) {
        expect(
          find.text(f.label),
          findsOneWidget,
          reason: '"${f.label}" is rendered more than once',
        );
      }

      handle.dispose();
    },
  );

  // ---------------------------------------------------------------------
  // Copy accuracy
  // ---------------------------------------------------------------------

  testWidgets('each page shows its copy, and claims nothing the app cannot do', (
    tester,
  ) async {
    await _pump(tester);

    final seen = <String>[];
    for (var i = 0; i < onboardingScenes.length; i++) {
      if (i > 0) await _swipeToNextPage(tester);
      final scene = onboardingScenes[i];
      expect(find.text(scene.headline), findsOneWidget);
      expect(find.text(scene.subtext), findsOneWidget);
      seen.addAll(_visibleText(tester));
    }

    final all = seen.join(' | ');

    // The retired artwork's claim. Business permits are a real Dokyu service;
    // an onboarding screen implying one has been APPROVED is the part that was
    // never true.
    expect(
      all,
      isNot(contains('Business Permit')),
      reason: 'onboarding must not advertise business permits',
    );

    // Nothing here processes, approves, or guarantees anything.
    for (final claim in [
      'Approved',
      'instant',
      'Instant',
      'real-time',
      'Real-time',
      'guaranteed',
      'Guaranteed',
    ]) {
      expect(
        all,
        isNot(contains(claim)),
        reason:
            'onboarding claims "$claim", which no part of this app delivers',
      );
    }

    // Events are listed, not booked.
    for (final claim in [
      'Register',
      'Registration',
      'Reserve',
      'Ticket',
      'RSVP',
    ]) {
      expect(
        all,
        isNot(contains(claim)),
        reason:
            'onboarding implies event $claim, which the app does not support',
      );
    }
  });

  test('every headline is two authored lines, and no scene is wordy', () {
    // The pattern this is built on sets two short lines and one sentence. A
    // headline that grows a third line, or a paragraph of supporting copy,
    // stops being a welcome screen and becomes a page nobody reads.
    for (final scene in onboardingScenes) {
      final lines = scene.headline.split('\n');
      expect(
        lines,
        hasLength(2),
        reason:
            '${scene.id}: the headline should be exactly two authored lines',
      );
      for (final line in lines) {
        expect(
          line.length,
          lessThanOrEqualTo(30),
          reason: '${scene.id}: "$line" is too long for a hero line',
        );
      }
      expect(
        scene.subtext.length,
        lessThanOrEqualTo(130),
        reason: '${scene.id}: the supporting line is a paragraph',
      );
    }
  });

  testWidgets('the access caveat is on page two and is not softened away', (
    tester,
  ) async {
    await _pump(tester);
    await _swipeToNextPage(tester);
    expect(
      find.text('Dokyu and Tulong are available to verified residents.'),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------
  // Assets
  // ---------------------------------------------------------------------

  testWidgets('every asset onboarding references is declared and loadable', (
    tester,
  ) async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final scene in onboardingScenes) {
      expect(
        pubspec,
        contains(scene.backgroundAsset),
        reason:
            '${scene.backgroundAsset} is used by onboarding but not declared in pubspec.yaml',
      );
    }
    expect(pubspec, contains(teresaRizalSealAsset));

    for (final asset in [
      ...onboardingScenes.map((s) => s.backgroundAsset),
      teresaRizalSealAsset,
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '$asset is declared but empty or missing',
      );
    }
  });

  test('the retired composite welcome artwork is gone from the runtime', () {
    // Removed from pubspec (so it no longer ships) and referenced by no source
    // file. The PNG files themselves are deliberately still on disk as design
    // references — deleting them is an owner call, and this asserts the part
    // that actually affects the app.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('assets/images/Welcome Screen')),
      reason:
          'the flattened composites are being bundled again — about 4.5 MB in every binary',
    );

    for (final dir in ['lib', 'test']) {
      for (final file in Directory(
        dir,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // This file names the retired asset in order to forbid it.
        if (file.path.endsWith('onboarding_redesign_test.dart')) continue;
        expect(
          file.readAsStringSync(),
          isNot(contains('Welcome Screen 1.png')),
          reason: '${file.path} still loads the retired composite artwork',
        );
      }
    }
  });

  testWidgets(
    'the municipal hall photo of a different province is not used here',
    (tester) async {
      // rectangle_cityhall.jpg names another municipality on its facade.
      // It must not appear on onboarding or as Balita media.
      await _pump(tester);
      final images = tester.widgetList<Image>(find.byType(Image)).map((i) {
        final provider = i.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        return asset is AssetImage ? asset.assetName : '';
      });
      expect(images, isNot(contains(onboardingExcludedAsset)));
    },
  );
}
