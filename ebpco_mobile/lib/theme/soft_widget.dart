import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft-widget tokens — the design reference's (Teresa-Rizal-Mobile)
/// `theme/soft_widget.dart`, ported with ONE change, per the owner's
/// instruction ("design only and overall look... the color only"): every
/// blue in that file is replaced by eBPCO's red from the web portals' own
/// token set ([AppColors]). Radii, shadow geometry (blur/offset), the type
/// scale and weights are the reference's own numbers, unchanged.
///
/// Mapping, so a future reader can check it against the reference:
///   blue #2F6CF0      → primary500 #C81E2C
///   blueDeep #1E4FC4  → primary600 #A5182A
///   blueSoft #E8F0FF  → primary100 #FDECEB
///   blueWash #F3F7FF  → primary50  #FDF6F6
///   headerGlow        → primary100 (the page's soft top wash)
///   ink/muted/line/page → the portals' gray900/gray500/gray200/background
///   blue-tinted shadows → primary500 at the same alpha; neutral shadows →
///   the portals' own rgba(20,20,40) shadow tint.
class SoftColors {
  SoftColors._();

  static const primary = AppColors.primary500;
  static const primaryDeep = AppColors.primary600;
  static const primarySoft = AppColors.primary100;
  static const primaryWash = AppColors.primary50;

  static const gold = AppColors.gold500;
  static const goldSoft = AppColors.gold100;
  static const goldInk = AppColors.gold700;

  static const ink = AppColors.gray900;
  static const muted = AppColors.gray500;
  static const line = AppColors.gray200;
  static const page = AppColors.background;
  static const white = Color(0xFFFFFFFF);
  static const clear = Color(0x00000000);

  static const headerGlow = AppColors.primary100;

  /// Same glow at alpha 0 — fading toward [Colors.transparent] would gray
  /// the wash (premultiplied alpha), same note as the reference.
  static const headerGlowClear = Color(0x00FDECEB);

  static const danger = AppColors.danger500;
  static const dangerSoft = AppColors.danger100;
  static const verifiedSoft = AppColors.success100;
  static const verifiedInk = AppColors.successText;
  static const pendingCream = AppColors.warning100;
  static const pendingInk = AppColors.warningText;
  static const chipWash = AppColors.gray100;
  static const disabledFill = AppColors.gray100;
  static const disabledInk = AppColors.gray400;
  static const chevron = AppColors.gray300;

  /// `rgba(255,255,255,.94)` — floating pill fill.
  static const navFill = Color(0xF0FFFFFF);

  /// White widget hairline.
  static const lineSoft = Color(0xE6EEEEF2);

  static const sheetScrim = Color(0x6B1F2430);

  /// Neutral card shadows — the portals' rgba(20,20,40) tint at the
  /// reference's alphas (0.08 / 0.06 / 0.10 / 0.16).
  static const cardShadow = Color(0x14141428);
  static const cardShadowSm = Color(0x0F141428);
  static const navShadow = Color(0x1A141428);
  static const sealShadow = Color(0x29141428);

  /// Red-tinted shadows — primary500 at the reference's blue alphas.
  static const apertureShadow = Color(0x59C81E2C);
  static const primaryShadow = Color(0x40C81E2C);
  static const avatarShadow = Color(0x40C81E2C);
  static const featureShadow = Color(0x42A5182A);

  /// The reference's primary gradient (blue → lighter blue), in red.
  static const primaryGradient = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [primaryDeep, primary],
  );
}

class SoftRadius {
  SoftRadius._();

  static const double xl = 28;
  static const double lg = 22;
  static const double md = 16;
  static const double sm = 12;
  static const double pill = 999;
}

class SoftShadows {
  SoftShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: SoftColors.cardShadow, blurRadius: 28, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> cardSm = [
    BoxShadow(color: SoftColors.cardShadowSm, blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> feature = [
    BoxShadow(color: SoftColors.featureShadow, blurRadius: 28, offset: Offset(0, 12)),
  ];

  /// Soft glow under a primary pill — `0 8px 20px` at 25%.
  static const List<BoxShadow> primary = [
    BoxShadow(color: SoftColors.primaryShadow, blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> aperture = [
    BoxShadow(color: SoftColors.apertureShadow, blurRadius: 14, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> nav = [
    BoxShadow(color: SoftColors.navShadow, blurRadius: 30, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> avatar = [
    BoxShadow(color: SoftColors.avatarShadow, blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> seal = [
    BoxShadow(color: SoftColors.sealShadow, blurRadius: 12, offset: Offset(0, 4)),
  ];
}

/// Inter 400 / 500 / 600 — the reference's inside-screen type, verbatim.
class SoftType {
  SoftType._();

  static const String family = 'Inter';

  /// Static SemiBold face for the big headlines (see pubspec).
  static const String familySemi = 'InterSemi';

  static const List<FontFeature> features = [
    FontFeature.enable('ss01'),
    FontFeature.enable('cv11'),
  ];

  static const TextStyle hero = TextStyle(
    fontFamily: familySemi,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: 1.12,
    color: SoftColors.ink,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: familySemi,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.9,
    height: 1.15,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle greetingHi = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.12,
    color: SoftColors.muted,
    fontFeatures: features,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.425,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle section = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.32,
    color: SoftColors.ink,
  );

  static const TextStyle sectionLink = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.12,
    color: SoftColors.primary,
    fontFeatures: features,
  );

  static const TextStyle cellLabel = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
    fontFeatures: features,
  );

  static const TextStyle cellValue = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.14,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle tileTitle = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.25,
    color: SoftColors.ink,
  );

  static const TextStyle tileSub = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: SoftColors.muted,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: SoftColors.muted,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
  );

  static const TextStyle nav = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.1,
    color: SoftColors.muted,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: SoftColors.white,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.ink,
  );

  static const TextStyle field = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: SoftColors.ink,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
  );
}
