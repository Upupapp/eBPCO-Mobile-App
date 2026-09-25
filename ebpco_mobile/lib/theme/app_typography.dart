import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles built on **Gothic A1**, the one font family both eBPCO web
/// portals use (`styles.scss`: `font-family: 'Gothic A1', -apple-system,
/// ...`). Unlike the design reference (Teresa-Rizal-Mobile), which pairs a
/// sans body face with a separate serif display face, eBPCO's own web
/// design has no second family — so there is no "display" face to port,
/// and introducing one here would be inventing a typographic identity the
/// LGU's own portals don't have. `display` below is kept only as a role
/// name for call sites that want a slightly heavier ceremonial weight; it
/// still resolves to Gothic A1.
class AppTypography {
  AppTypography._();

  static TextStyle _gothic({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.gothicA1(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle get h1 => _gothic(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3);
  static TextStyle get h2 => _gothic(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2);
  static TextStyle get h3 => _gothic(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get body => _gothic(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textBody, height: 1.45);
  static TextStyle get bodyMedium => _gothic(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textBody);
  static TextStyle get caption => _gothic(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);

  static TextStyle get label => _gothic(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textBody);
  static TextStyle get labelStrong => _gothic(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get cardTitle => _gothic(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get cardSubtitle => _gothic(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.3);

  static TextStyle get hero => _gothic(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.18);

  static TextStyle get overline => _gothic(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.6);

  static TextStyle get button => _gothic(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle get buttonMuted => _gothic(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray400);

  static TextStyle get fieldLabel => _gothic(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textBody);
  static TextStyle get fieldValue => _gothic(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get hint => _gothic(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static TextStyle get error => _gothic(fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.danger, height: 1.35);

  /// The one ceremonial role that recurs across entry screens (splash,
  /// onboarding, sign-in): "eBPCO" beside the municipal seal.
  static TextStyle get wordmark => _gothic(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white);
}
