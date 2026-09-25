import 'package:flutter/material.dart';

/// Motion tokens — durations/curves named by *intent* rather than left as
/// raw `Duration(milliseconds: ...)` literals at each call site, so
/// independently-written screens still feel coordinated. Values kept as-is
/// from the design reference (Teresa-Rizal-Mobile) per the owner's
/// "design/look only" instruction — nothing here is color, and a
/// government-services app used briskly and often benefits from the same
/// calibration regardless of which LGU it serves.
class AppMotion {
  AppMotion._();

  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 260);
  static const emphasis = Duration(milliseconds: 380);
  static const celebration = Duration(milliseconds: 600);

  static const standardEase = Curves.easeInOut;
  static const enterEase = Curves.easeOutCubic;
  static const exitEase = Curves.easeInCubic;
  static const emphasizedEase = Cubic(0.2, 0.0, 0.0, 1.0);

  static bool reducedMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

  static Duration resolve(BuildContext context, Duration full) => reducedMotion(context) ? fast : full;
}
