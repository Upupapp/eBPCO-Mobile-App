import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow colours, derived from the palette rather than written as hex.
///
/// These lived as raw `Color(0x...)` literals at their call sites, which is
/// how one of them drifted: `teresa_rizal_curved_navbar.dart` carried
/// `Color(0x1A0B1B4A)` commented "AppColors.navy900 @ 10%", but `0B1B4A` is
/// **not** `navy900` (`0B1730`). The comment asserted a relationship to a token
/// that had never been true, and nothing could notice — that is exactly the
/// drift the "no colour outside the theme" rule exists to prevent.
///
/// Deriving with `withValues` means a change to the palette reaches the shadows,
/// and a claim like "navy at 10%" is executable rather than aspirational.
class AppElevation {
  AppElevation._();

  /// The curved navbar's lift. Was `Color(0x1A0B1B4A)` — alpha 0x1A ≈ 10%.
  ///
  /// **This is a deliberate, tiny visual change**: the old hex was a slightly
  /// bluer, lighter navy than the token. Correcting it to the real navy900 is
  /// the point of the fix; keeping the drifted value would have preserved a bug
  /// for the sake of an unchanged screenshot.
  static final Color navbarShadow = AppColors.navy900.withValues(alpha: 0.10);

  /// The segmented-tab selected pill's shadow. Was `Color(0x140F172A)` —
  /// alpha 0x14 ≈ 8% of Tailwind slate-900, a colour the Teresa, Rizal palette
  /// does not carry. Mapped onto navy900, the nearest palette equivalent and
  /// the app's own darkest ink.
  static final Color tabPillShadow = AppColors.navy900.withValues(alpha: 0.08);
}

/// Third-party brand colours.
///
/// **Not part of the Teresa, Rizal palette, and never to be used for app UI.**
/// They are here only because they must live somewhere the "no raw colour
/// outside `lib/theme/`" gate can see, and because a share sheet that draws
/// each target in a colour other than its own brand mark looks broken.
///
/// Adding to this list means adding a share target. It is never the place to
/// put a colour you want in the app — that is `AppColors`, and adding there is
/// a cross-surface decision shared with the web platform.
class ThirdPartyBrandColors {
  ThirdPartyBrandColors._();

  static const facebook = Color(0xFF1877F2);
  static const messenger = Color(0xFF00B2FF);
  static const viber = Color(0xFF7360F2);
  static const whatsapp = Color(0xFF25D366);
}
