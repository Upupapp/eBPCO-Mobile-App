import 'package:flutter/material.dart';
import 'promotional_banner_dialog.dart';

/// The post-entry promotional pop-up shown once Home has loaded — the
/// municipal welcome/services poster, never a normal card inside the Home
/// feed. Deliberately a plain `showDialog` (its default barrier already
/// dims the screen behind it) rather than a bespoke overlay: this is
/// informational/promotional content the user must be free to dismiss
/// immediately, never a blocking gate in front of Home.
///
/// Kept as its own named widget/type (rather than calling
/// [PromotionalBannerDialog.show] directly from HomeScreen) purely so
/// existing call sites/tests that key off `HomeWelcomeBanner` specifically
/// keep working — the actual presentation is [PromotionalBannerDialog],
/// the shared implementation every other tab's promotional popup also
/// uses.
class HomeWelcomeBanner extends StatelessWidget {
  const HomeWelcomeBanner({super.key});

  /// Shows the banner once. Callers are responsible for only invoking
  /// this once per session (see HomeScreen's `_bannerOffered` flag) — this
  /// method itself has no "already shown" memory, by design, so it stays
  /// a simple, reusable presentation widget rather than owning session
  /// state that belongs to its caller.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: PromotionalBannerDialog.barrierColor,
      builder: (_) => const HomeWelcomeBanner(),
    );
  }

  @override
  Widget build(BuildContext context) => const PromotionalBannerDialog(label: 'Home');
}
