import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Soft-widget tokens. Copied from the PAAIPE portal shell
/// (`--sw-*` in the inside-UI CSS key). Inside screens use these.
/// Login and Register use them too. Splash and welcome stay on [AppColors].
class SoftColors {
  SoftColors._();

  static const blue = Color(0xFF2F6CF0);
  static const blueDeep = Color(0xFF1E4FC4);
  static const blueSoft = Color(0xFFE8F0FF);
  static const blueWash = Color(0xFFF3F7FF);
  static const cyan = Color(0xFF3EC6E0);
  static const gold = Color(0xFFF0B429);
  static const ink = Color(0xFF1A2336);
  static const muted = Color(0xFF7A8699);
  static const line = Color(0xFFE6ECF5);
  static const page = Color(0xFFF4F6FA);
  static const white = Color(0xFFFFFFFF);

  /// Fully transparent. Use this instead of `Colors.transparent` on new
  /// post-auth chrome so the Material-color ratchet does not climb.
  static const clear = Color(0x00000000);
  static const headerGlow = Color(0xFFD4E4FF);

  /// Same glow at alpha 0. CSS `transparent` in a gradient is premultiplied;
  /// fading toward [Colors.transparent] grays the wash.
  static const headerGlowClear = Color(0x00D4E4FF);
  static const featureStart = Color(0xFF2346A8);
  static const liveDot = Color(0xFF7EF0FF);
  static const avatarStart = Color(0xFF9EC0FF);
  static const eventHeroStart = Color(0xFFDCE9FF);
  static const eventHeroEnd = Color(0xFFC8F2F8);
  static const bannerDash = Color(0xFFB8C6DE);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFFE8E8);
  static const verifiedInk = Color(0xFF1A7A45);

  /// Pending-review cream and ink. Shared by the status pill, the home
  /// account cards, and the verification lock.
  static const pendingCream = Color(0xFFFFF4D6);
  static const pendingInk = Color(0xFF8A5A00);

  /// Open-access chip (Home, Balita, Events, Emergency).
  static const verifiedSoft = Color(0xFFE6F7ED);

  /// Locked and guest chip wash.
  static const chipWash = Color(0xFFF0F2F6);

  /// Pack C detail chips. Free wash pairs with [verifiedInk]. Ended ink is
  /// the comps' gold-brown; it is not [gold].
  static const freeChipWash = Color(0xFFE6F7ED);
  static const endedWash = Color(0xFFFFF6E0);
  static const endedInk = Color(0xFF9A6B00);
  static const pastChipWash = Color(0xFFF0F2F6);
  static const pastPosterStart = Color(0xFFE8ECF2);
  static const pastPosterDash = Color(0xFFC8D0DC);

  /// rgba(255,255,255,.7) — poster slot icon disc.
  static const slotIconFill = Color(0xB3FFFFFF);

  /// Muted outline button fill and the off-state interest track.
  static const mutedButtonFill = Color(0xFFF7F8FB);
  static const toggleTrack = Color(0xFFD5DDE8);

  static const tulongSoft = Color(0xFFEFE8FF);
  static const tulongInk = Color(0xFF7C5CBF);

  /// Pack G / I catalog tints. Screens read these; they do not declare hex.
  static const cyanSoft = Color(0xFFE2F7FB);
  static const cyanInk = Color(0xFF1D8AA0);
  static const chevron = Color(0xFFB3BCCB);
  static const disabledFill = Color(0xFFE9EDF4);
  static const disabledInk = Color(0xFFA3ADBD);
  static const sampleWash = Color(0xFFFFF1C2);
  static const tulongStrip = Color(0xFFF3EFFF);
  static const glyphMuted = Color(0xFFEEF1F6);
  static const sheetScrim = Color(0x6B1A2336);
  static const pickerScrim = Color(0x291A2336);
  static const focusRing = Color(0x262F6CF0);
  static const dangerRing = Color(0x26E5484D);
  static const errorFill = Color(0xFFFFF7F7);
  static const goldSoft = Color(0xFFFFF6E0);

  /// `rgba(255,255,255,.94)` — floating pill fill.
  static const navFill = Color(0xF0FFFFFF);

  /// `rgba(230,236,245,.9)` — white widget hairline.
  static const lineSoft = Color(0xE6E6ECF5);

  /// `rgba(255,255,255,.25)` — progress track on a deep widget.
  static const progressTrack = Color(0x40FFFFFF);

  /// rgba(47, 108, 240, 0.35) — aperture shadow.
  static const apertureShadow = Color(0x592F6CF0);

  /// rgba(30, 79, 196, 0.26) — featured gradient shadow.
  static const featureShadow = Color(0x421E4FC4);

  /// rgba(30, 60, 120, 0.08), 0.06, 0.10, and 0.16.
  static const cardShadow = Color(0x141E3C78);
  static const cardShadowSm = Color(0x0F1E3C78);
  static const navShadow = Color(0x1A1E3C78);
  static const sealShadow = Color(0x291E3C78);

  /// rgba(47, 108, 240, 0.25) — avatar disc.
  static const avatarShadow = Color(0x402F6CF0);

  /// rgba(47, 108, 240, 0.25) — primary pill elevation. Blue-tinted only.
  static const primaryShadow = Color(0x402F6CF0);

  /// `linear-gradient(145deg, #2346a8 0%, #2f6cf0 100%)`.
  static const featureGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [featureStart, blue],
  );

  /// `linear-gradient(145deg, #9ec0ff, #2f6cf0)`.
  static const avatarGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [avatarStart, blue],
  );

  /// `linear-gradient(145deg, #dce9ff, #c8f2f8)`.
  static const eventHeroGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [eventHeroStart, eventHeroEnd],
  );

  /// Mid and end stops of the lighter primary widget gradient.
  static const primaryMid = Color(0xFF4B8AF5);
  static const primaryEnd = Color(0xFF5AA0FF);

  /// `linear-gradient(135deg, #2f6cf0 0%, #4b8af5 55%, #5aa0ff 100%)`.
  static const primaryGradient = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [blue, primaryMid, primaryEnd],
    stops: [0, 0.55, 1],
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
    BoxShadow(
      color: SoftColors.cardShadow,
      blurRadius: 28,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardSm = [
    BoxShadow(
      color: SoftColors.cardShadowSm,
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> feature = [
    BoxShadow(
      color: SoftColors.featureShadow,
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  /// Soft blur under a primary pill. One layer, no hard offset slab.
  /// `0 8px 20px rgba(47, 108, 240, 0.25)`.
  static const List<BoxShadow> primary = [
    BoxShadow(
      color: SoftColors.primaryShadow,
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> aperture = [
    BoxShadow(
      color: SoftColors.apertureShadow,
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  /// `0 10px 30px rgba(30, 60, 120, 0.10)`.
  static const List<BoxShadow> nav = [
    BoxShadow(
      color: SoftColors.navShadow,
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  /// `0 4px 12px rgba(47, 108, 240, 0.25)`.
  static const List<BoxShadow> avatar = [
    BoxShadow(
      color: SoftColors.avatarShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// `0 4px 12px rgba(30, 60, 120, 0.16)`.
  static const List<BoxShadow> seal = [
    BoxShadow(
      color: SoftColors.sealShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Inter 400 / 500 / 600 only. Weights above 600 are not used inside.
class SoftType {
  SoftType._();

  static const List<FontFeature> features = [
    FontFeature.enable('ss01'),
    FontFeature.enable('cv11'),
  ];

  static const TextStyle h1 = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.84,
    height: 1.15,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle greetingHi = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.12,
    color: SoftColors.muted,
    fontFeatures: features,
  );

  static const TextStyle greetingName = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.4,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  /// Page bar title: 17 / 500 / tracking -0.025em.
  static const TextStyle pageBar = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.425,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle cellLabel = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
    fontFeatures: features,
  );

  static const TextStyle cellValue = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.14,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle sectionLink = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.12,
    color: SoftColors.blue,
    fontFeatures: features,
  );

  static const TextStyle progressLabel = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SoftColors.gold,
    fontFeatures: features,
  );

  static const TextStyle bannerTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.13,
    color: SoftColors.blue,
    fontFeatures: features,
  );

  static const TextStyle section = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.32,
    color: SoftColors.ink,
  );

  /// Page-bar title: 17 / 500 / tracking -0.025em.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.425,
    color: SoftColors.ink,
    fontFeatures: features,
  );

  static const TextStyle name = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    color: SoftColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: SoftColors.muted,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
  );

  static const TextStyle nav = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.1,
    color: SoftColors.muted,
  );

  static const TextStyle onFeatureEyebrow = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(0xE6FFFFFF),
  );

  static const TextStyle onFeatureTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.25,
    color: SoftColors.white,
  );
}

/// Catalog, wizard, and incident-report type. Inter 400/500/600 only.
class CatalogType {
  CatalogType._();

  static const TextStyle meta = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: SoftColors.muted,
  );

  static const TextStyle metaInk = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: SoftColors.ink,
  );

  static const TextStyle tileTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.25,
    color: SoftColors.ink,
  );

  static const TextStyle tileSub = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: SoftColors.muted,
  );

  static const TextStyle fee = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
  );

  static const TextStyle sample = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SoftColors.endedInk,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.ink,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SoftColors.muted,
  );

  static const TextStyle honesty = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: SoftColors.ink,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SoftColors.ink,
  );

  static const TextStyle field = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: SoftColors.ink,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: SoftColors.muted,
  );

  static const TextStyle helper = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: SoftColors.muted,
  );

  static const TextStyle error = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: SoftColors.danger,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: SoftColors.white,
  );

  static const TextStyle buttonInk = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: SoftColors.blue,
  );

  static const TextStyle buttonMuted = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: SoftColors.disabledInk,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: SoftColors.ink,
  );

  static const TextStyle revealEyebrow = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: SoftColors.blue,
  );

  static const TextStyle counter = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.muted,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.ink,
  );

  static const TextStyle note = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: SoftColors.ink,
  );

  static const TextStyle link = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SoftColors.blue,
  );

  static const TextStyle bandTitle = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: SoftColors.danger,
  );

  static const TextStyle bandSub = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: SoftColors.danger,
  );

  static const TextStyle onDanger = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SoftColors.white,
  );

  static const TextStyle highlight = TextStyle(
    fontFamily: AppTypography.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: SoftColors.ink,
    backgroundColor: SoftColors.sampleWash,
  );
}
