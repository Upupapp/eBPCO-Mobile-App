import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'soft_widget.dart';

/// Text styles on **Inter**, bundled — the design reference's own face
/// (Teresa-Rizal-Mobile). Owner decision: take that app's design and look,
/// change only the color, so the type follows the reference rather than
/// the web portals' Gothic A1. Headlines use the static SemiBold instance
/// with the reference's tight negative tracking.
class AppTypography {
  AppTypography._();

  static const String _sans = SoftType.family;
  static const String _semi = SoftType.familySemi;

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    bool semi = false,
  }) =>
      TextStyle(
        fontFamily: semi ? _semi : _sans,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle get h1 => _inter(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.9, height: 1.15, semi: true);
  static TextStyle get h2 => _inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.5, semi: true);
  static TextStyle get h3 => _inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.32);

  static TextStyle get body => _inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textBody, height: 1.45);
  static TextStyle get bodyMedium => _inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get caption => _inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);

  static TextStyle get label => _inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textBody);
  static TextStyle get labelStrong => _inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get cardTitle => _inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.25);
  static TextStyle get cardSubtitle => _inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.3);

  static TextStyle get hero => _inter(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -1.2, height: 1.12, semi: true);

  static TextStyle get overline => _inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.2);

  static TextStyle get button => _inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle get buttonMuted => _inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray400);

  static TextStyle get fieldLabel => _inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get fieldValue => _inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get hint => _inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static TextStyle get error => _inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.danger, height: 1.35);

  static TextStyle get wordmark => _inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, semi: true);
}
