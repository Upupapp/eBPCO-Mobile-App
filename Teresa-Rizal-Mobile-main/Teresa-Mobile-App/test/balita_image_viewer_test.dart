// Functional verification of PostImageViewer — the tap-to-enlarge Balita
// image overlay — covering Guest gating, Nicanor's (unverified but
// signed-in) engagement also being gated the same way, and feed/viewer
// like-state synchronization.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/main.dart';
import 'package:teresa_rizal/screens/balita/post_image_viewer.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/widgets/guest_sign_in_gate.dart';
import 'package:teresa_rizal/widgets/restricted_feature_notice.dart';
import 'package:teresa_rizal/widgets/teresa_rizal_curved_navbar.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Demo-account sign-in (LoginScreen._quickLogin) shows a "this app is a
/// frontend simulation" SnackBar via the app-level ScaffoldMessenger, which
/// — unlike a route — persists across navigation for its default ~4s
/// duration. Its static (non-animating) middle stretch doesn't schedule
/// any frame, so `pumpAndSettle()` alone doesn't wait it out, same class of
/// gap as a raw `Future.delayed` — it can still be sitting at the bottom of
/// the screen, over real content, several steps later. Advance the clock
/// straight past it before interacting with anything near the bottom edge.
Future<void> _waitOutSignInToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// The first Balita post ('bal-mangrove-award' in mock_catalog.dart) — has
/// an image, a body message, and non-zero starting likes/shares — good
/// coverage for both "message shown" and "engagement counts stay synced"
/// assertions.
/// The lead post no longer ships a photograph. The dashed slot is what
/// opens the same viewer the old city-hall image opened.
final _mangrovePostImage = find.descendant(
  of: find.byKey(const ValueKey('bal-mangrove-award')),
  matching: find.text('Photo slot'),
);

/// RootShell's floating navbar reserves its full pill-plus-headroom
/// bounding box at the bottom of the screen (see nav_style.dart) — only
/// the pill itself is painted, but the whole box still hit-tests, so
/// content that happens to be laid out underneath it (which, on a short
/// phone viewport, a long post's image can be) isn't reliably tappable.
/// Rather than guess a fixed scroll distance — the exact resting position
/// varies with which account signed in and how much of the post's own
/// text renders above the image — read the image's actual current center
/// and, if it's sitting in that bottom reserve, drag it up into the
/// middle of the screen first, the same adjustment a real person would
/// make before tapping something they can see is crowded against the nav
/// bar.
Finder get _feedScrollable => find.descendant(
  of: find.byKey(const ValueKey('balita-feed')),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  ),
);

/// Puts [target] in the open band above the floating nav. A card taller
/// than the viewport can be "visible" while its center is still off-screen.
Future<void> _bringOnScreen(WidgetTester tester, Finder target) async {
  final position = tester.state<ScrollableState>(_feedScrollable).position;
  var guard = 0;
  while (target.evaluate().isEmpty &&
      position.pixels < position.maxScrollExtent &&
      guard < 12) {
    position.jumpTo(
      (position.pixels + 280).clamp(0.0, position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
    guard += 1;
  }
  final screenHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 8; i++) {
    final center = tester.getCenter(target);
    if (center.dy > 140 && center.dy < screenHeight * 0.62) return;
    final dy = (screenHeight * 0.38 - center.dy).clamp(-320.0, 320.0);
    await tester.drag(_feedScrollable, Offset(0, dy));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapClearOfNavbar(WidgetTester tester, Finder target) async {
  await _bringOnScreen(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openMangroveViewer(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(TeresaRizalCurvedNavBar),
      matching: find.text('Balita'),
    ),
  );
  await tester.pumpAndSettle();
  // Scoped to the AppBar specifically — once Balita is the selected nav
  // tab, the navbar's own floating active label also reads "Balita", so an
  // unscoped find.text('Balita') would match both.
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text('Balita')),
    findsOneWidget,
  );
  // Balita's own promotional popup (PromotionalBannerDialog), shown the
  // first time this tab is opened — dismiss it before interacting with
  // the feed underneath, same as a real user tapping its X.
  await _dismissWelcomeBanner(tester);

  await _bringOnScreen(tester, _mangrovePostImage);
  expect(_mangrovePostImage, findsOneWidget);
  await _tapClearOfNavbar(tester, _mangrovePostImage);
  expect(find.byType(PostImageViewer), findsOneWidget);
}

void main() {
  testWidgets(
    'Guest: can open the viewer and read the post, but React/Comment/Share all show the account-required notice',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      await _openMangroveViewer(tester);

      // The viewer is the photo: counter, close, pinch. The post copy stays
      // on the card. Social actions are not committed from this surface.
      expect(find.text('1/1'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PostImageViewer),
          matching: find.text('Like'),
        ),
        findsNothing,
      );

      final closeInViewer = find.descendant(
        of: find.byType(PostImageViewer),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeInViewer, findsOneWidget);
      await tester.tap(closeInViewer);
      await tester.pumpAndSettle();
      expect(find.byType(PostImageViewer), findsNothing);

      final mangroveCard = find.byKey(const ValueKey('bal-mangrove-award'));
      expect(
        find.descendant(
          of: mangroveCard,
          matching: find.textContaining('Bagumbayan at Dalig River Cleanup'),
        ),
        findsOneWidget,
      );

      final likeOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Like'),
      );
      await _bringOnScreen(tester, likeOnCard);
      await tester.tap(likeOnCard);
      await tester.pumpAndSettle();
      expect(
        find.byType(GuestSignInGate),
        findsOneWidget,
        reason: 'Like should open the guest sign-in gate',
      );
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text(GuestSignInGate.engageBody), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      // Comments stay on the card. Guests get a Sign in CTA instead of a composer.
      final commentOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Comment'),
      );
      await _bringOnScreen(tester, commentOnCard);
      await tester.tap(commentOnCard);
      await tester.pumpAndSettle();
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Sign in to join the conversation'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      Navigator.of(tester.element(find.text('Comments'))).pop();
      await tester.pumpAndSettle();

      // Guest share uses the Pack B gate. Signed-in share stays the local sheet.
      final shareOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Share'),
      );
      await _bringOnScreen(tester, shareOnCard);
      await tester.tap(shareOnCard);
      await tester.pumpAndSettle();
      expect(find.byType(GuestSignInGate), findsOneWidget);
      expect(find.text(GuestSignInGate.shareBody), findsOneWidget);
      expect(find.text('Copy link'), findsNothing);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Balita')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Nicanor Sarmiento (signed in, unverified): treated the same as Guest — React/Comment/Share are blocked in the viewer, viewing/zooming stays available',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('demo-unverified')));
      await tester.tap(find.byKey(const Key('demo-unverified')));
      await tester.pumpAndSettle();
      await _waitOutSignInToast(tester);
      await _dismissWelcomeBanner(tester);

      await tester.tap(find.text('Balita'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // Viewing/zooming the image itself stays available — the gate only
      // wraps the react/comment/share actions, never opening the viewer.
      final mangroveCard = find.byKey(const ValueKey('bal-mangrove-award'));
      final likeOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Like'),
      );
      await _bringOnScreen(tester, likeOnCard);

      // Starting state: 89 likes, unchanged — an unverified account is
      // blocked the same as a Guest now (Phase 7 of the Balita access
      // rules), not treated as merely "signed in".
      expect(
        find.descendant(of: mangroveCard, matching: find.text('89')),
        findsOneWidget,
      );
      await tester.tap(likeOnCard);
      await tester.pumpAndSettle();

      expect(find.byType(RestrictedFeatureNotice), findsOneWidget);
      // The like count never moved — the action was blocked before it ran.
      Navigator.of(tester.element(find.byType(RestrictedFeatureNotice))).pop();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: mangroveCard, matching: find.text('89')),
        findsOneWidget,
      );

      // Comment opens the sheet. Unverified accounts get a verification CTA
      // in place of the composer.
      final commentOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Comment'),
      );
      await _bringOnScreen(tester, commentOnCard);
      await tester.tap(commentOnCard);
      await tester.pumpAndSettle();
      expect(find.text('Continue verification'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(RestrictedFeatureNotice), findsNothing);
      Navigator.of(tester.element(find.text('Continue verification'))).pop();
      await tester.pumpAndSettle();

      // Viewing and zooming the image itself stays available. The slot
      // sits above the engagement row, so bring it back into the band
      // the floating nav does not cover.
      await _tapClearOfNavbar(
        tester,
        find.byKey(const ValueKey('balita-media-bal-mangrove-award')),
      );
      expect(find.byType(PostImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
    },
  );

  testWidgets(
    'Opening a post tracks a view internally, but no view count is ever shown in the UI',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      final mangrove = MockCatalog.announcements.firstWhere(
        (a) => a.id == 'bal-mangrove-award',
      );
      final startingViews = mangrove.viewCount;

      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Balita'),
        ),
      );
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);
      // View count is tracked (see BalitaService.recordView) but must never
      // be rendered anywhere in the feed or the viewer.
      expect(find.textContaining('views'), findsNothing);

      await _tapClearOfNavbar(tester, _mangrovePostImage);
      expect(find.byType(PostImageViewer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PostImageViewer),
          matching: find.textContaining('views'),
        ),
        findsNothing,
      );
      expect(mangrove.viewCount, startingViews + 1);

      final closeInViewer = find.descendant(
        of: find.byType(PostImageViewer),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.ensureVisible(closeInViewer);
      await tester.tap(closeInViewer);
      await tester.pumpAndSettle();
      expect(find.textContaining('views'), findsNothing);
    },
  );

  testWidgets(
    'Verified user: engagement row shows reaction count on the left, comments then shares together on the right',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('demo-verified')));
      await tester.tap(find.byKey(const Key('demo-verified')));
      await tester.pumpAndSettle();
      await _waitOutSignInToast(tester);
      await _dismissWelcomeBanner(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(TeresaRizalCurvedNavBar),
          matching: find.text('Balita'),
        ),
      );
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // 'bal-mangrove-award' has no comments seeded, so it can't show the
      // comment count — scroll to 'bal-1' (214 likes, 2 comments, 18
      // shares), which has all three visible metrics at once.
      await _bringOnScreen(
        tester,
        find.textContaining('Sumali sa buong-munisipyong'),
      );
      // Left (reaction) vs. right (comments, then shares) placement is
      // guaranteed by BalitaEngagementRow's own Row/Expanded source rather
      // than re-measured here by pixel geometry, which proved unreliable
      // to assert on under this test harness in an earlier pass.
      final community = find.byKey(const ValueKey('bal-1'));
      expect(
        find.descendant(of: community, matching: find.text('214')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: community, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: community, matching: find.text('Share')),
        findsOneWidget,
      );
      expect(find.text('18 shares'), findsNothing);
      expect(find.textContaining('views'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Verified user: commenting in the image viewer increments the visible comment count immediately',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'teresa_rizal_onboarding_complete': true,
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const TeresaRizalMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('demo-verified')));
      await tester.tap(find.byKey(const Key('demo-verified')));
      await tester.pumpAndSettle();
      await _waitOutSignInToast(tester);
      await _dismissWelcomeBanner(tester);

      await tester.tap(find.text('Balita'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // 'bal-mangrove-award' starts with no comments (untouched by any
      // earlier test in this file — only its viewCount is polluted by
      // cross-test viewer-opens, which this check doesn't rely on), so the
      // comment count starts at 0, then the card shows 1 the moment the
      // first one is submitted.
      final mangroveCard = find.byKey(const ValueKey('bal-mangrove-award'));
      final commentOnCard = find.descendant(
        of: mangroveCard,
        matching: find.byTooltip('Comment'),
      );
      await _bringOnScreen(tester, commentOnCard);
      expect(
        find.descendant(of: mangroveCard, matching: find.text('0')),
        findsOneWidget,
      );
      await tester.tap(commentOnCard);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Maganda ang balita na ito!',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Maganda ang balita na ito!'), findsOneWidget);
      expect(
        find.descendant(of: mangroveCard, matching: find.text('1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
