import 'package:flutter/material.dart';

/// Motion tokens — durations/curves named by *intent* (what the animation is
/// for) rather than left as raw `Duration(milliseconds: …)` literals at each
/// call site, so independently-written screens still end up feeling
/// coordinated. Adapted from the Servana Client App's system-design
/// discipline (see its `motion_tokens.dart`) — the specific values below are
/// Teresa, Rizal's own choices, not copied numbers, calibrated for a
/// government-services app used briskly and often rather than a lifestyle
/// app: nothing here should feel decorative or slow down a citizen trying to
/// submit a request.
class AppMotion {
  AppMotion._();

  /// No animation — used to make a call site's intent explicit ("this
  /// transition is deliberately instant") rather than omitting a duration.
  static const instant = Duration.zero;

  /// Micro-interactions: press/release feedback, small state toggles.
  static const fast = Duration(milliseconds: 150);

  /// The default for most transitions — tab switches, expanding sections,
  /// list-item reveals.
  static const standard = Duration(milliseconds: 260);

  /// Sheets, dialogs, and other emphasis-level reveals that should read as
  /// more deliberate than a standard transition.
  static const emphasis = Duration(milliseconds: 380);

  /// Rare, celebratory moments only — e.g. a request reaching Approved/Paid.
  /// Not for routine navigation; overusing this duration would make the app
  /// feel sluggish.
  static const celebration = Duration(milliseconds: 600);

  static const standardEase = Curves.easeInOut;
  static const enterEase = Curves.easeOutCubic;
  static const exitEase = Curves.easeInCubic;

  /// Material's "emphasized" easing — for the few moments (modal entries,
  /// the nav center-launcher expansion) that should feel weighted rather
  /// than mechanical.
  static const emphasizedEase = Cubic(0.2, 0.0, 0.0, 1.0);

  /// True when the platform/OS accessibility setting for reduced motion is
  /// on. Every non-trivial animated widget should check this before
  /// choosing a duration — see [resolve].
  static bool reducedMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

  /// Returns [fast] under reduced motion, otherwise [full] — the one place
  /// call sites should go to pick a duration, rather than branching on
  /// [reducedMotion] themselves everywhere.
  static Duration resolve(BuildContext context, Duration full) => reducedMotion(context) ? fast : full;
}
