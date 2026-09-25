import 'package:flutter/material.dart';

/// Design tokens copied verbatim from the two eBPCO web portals' own
/// `:root` token block (`ebpco-user-portal/src/styles.scss`, itself copied
/// from the Admin Portal's `_tokens.scss` — "shared institutional
/// identity", per that file's own comment). Do not invent a color here: if
/// something is needed that isn't below, it should come from that token
/// file first, the same rule the design reference (Teresa-Rizal-Mobile,
/// a different client's app kept only for its shell/layout shape) enforced
/// for its own palette.
///
/// This app has no "navy" scale — the reference did, for its own dark
/// hero/sidebar surfaces. eBPCO's own design system has no separate dark
/// scale; where a dark surface is needed, [gray900]/[gray800] is the real
/// token to reach for, not an invented one.
class AppColors {
  AppColors._();

  // Primary — brand red.
  static const primary50 = Color(0xFFFDF6F6);
  static const primary100 = Color(0xFFFDECEB);
  static const primary500 = Color(0xFFC81E2C);
  static const primary600 = Color(0xFFA5182A);
  static const primary700 = Color(0xFFA5182A);

  // Gold — the municipal seal's accent, used sparingly (same rule as web).
  static const gold50 = Color(0xFFFDF8EE);
  static const gold100 = Color(0xFFFAEFD6);
  static const gold500 = Color(0xFFCC9A2E);
  static const gold600 = Color(0xFFB8860F);
  static const gold700 = Color(0xFF8C6210);
  static const goldBorder = Color(0xFFECD9A8);

  static const secondary50 = Color(0xFFFAFAFC);
  static const secondary100 = Color(0xFFF4F4F7);
  static const secondary500 = Color(0xFF6B7080);

  static const success100 = Color(0xFFE7FBEF);
  static const success500 = Color(0xFF16A34A);
  static const successText = Color(0xFF166534);

  static const warning100 = Color(0xFFFEF8EA);
  static const warning500 = Color(0xFFB45309);
  static const warningText = Color(0xFFB45309);

  static const danger100 = Color(0xFFFDECEB);
  static const danger500 = Color(0xFFDC2626);
  static const dangerText = Color(0xFFA5182A);

  static const info100 = Color(0xFFE8F1FF);
  static const info500 = Color(0xFF2563EB);
  static const infoText = Color(0xFF1D4ED8);

  // Gray — neutrals, used throughout for text/background/border.
  static const gray50 = Color(0xFFFAFAFC);
  static const gray100 = Color(0xFFF4F4F7);
  static const gray200 = Color(0xFFE6E6EC);
  static const gray300 = Color(0xFF9A9EA8);
  static const gray400 = Color(0xFF8B8F9B);
  static const gray500 = Color(0xFF6B7080);
  static const gray600 = Color(0xFF565C6B);
  static const gray700 = Color(0xFF454A58);
  static const gray800 = Color(0xFF2B2F3A);
  static const gray900 = Color(0xFF1F2430);

  static const background = Color(0xFFF4F5F7);
  static const surface = Colors.white;
  static const surfaceSecondary = Color(0xFFF4F4F7);
  static const borderLight = Color(0xFFEEEEF2);
  static const borderMedium = Color(0xFFE6E6EC);

  // Semantic aliases used across screens/widgets.
  static const success = success500;
  static const warning = warning500;
  static const danger = danger500;
  static const info = info500;

  static const textPrimary = gray900;
  static const textBody = gray700;
  static const textMuted = gray500;
}
