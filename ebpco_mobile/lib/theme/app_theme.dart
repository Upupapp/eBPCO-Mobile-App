import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'soft_widget.dart';

/// The app's single [ThemeData] — the design reference's soft-widget look
/// (pill inputs, pill buttons, white surfaces on a washed page), in eBPCO
/// red. Built from tokens, never scattered `Color(0x...)` literals.
class AppTheme {
  AppTheme._();

  static const _pill = StadiumBorder();

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light, fontFamily: SoftType.family);
    return base.copyWith(
      scaffoldBackgroundColor: SoftColors.page,
      colorScheme: base.colorScheme.copyWith(
        primary: SoftColors.primary,
        onPrimary: Colors.white,
        secondary: SoftColors.gold,
        onSecondary: Colors.white,
        error: SoftColors.danger,
        surface: SoftColors.white,
        onSurface: SoftColors.ink,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SoftColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: SoftType.pageTitle,
        iconTheme: const IconThemeData(color: SoftColors.ink),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: SoftType.family,
        bodyColor: AppColors.textBody,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: SoftColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoftColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: SoftColors.disabledFill,
          disabledForegroundColor: SoftColors.disabledInk,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _pill,
          textStyle: SoftType.button,
          elevation: 0,
          shadowColor: SoftColors.primaryShadow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SoftColors.primary,
          backgroundColor: SoftColors.white,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: SoftColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: _pill,
          textStyle: SoftType.button.copyWith(color: SoftColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SoftColors.primary,
          shape: _pill,
          textStyle: SoftType.sectionLink.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoftColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: _inputBorder(SoftColors.line),
        enabledBorder: _inputBorder(SoftColors.line),
        disabledBorder: _inputBorder(SoftColors.chipWash),
        focusedBorder: _inputBorder(SoftColors.primary, width: 1.5),
        errorBorder: _inputBorder(SoftColors.danger),
        focusedErrorBorder: _inputBorder(SoftColors.danger, width: 1.5),
        labelStyle: SoftType.fieldLabel,
        hintStyle: SoftType.hint,
        errorStyle: AppTypography.error,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : SoftColors.muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SoftColors.primary : SoftColors.chipWash),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SoftColors.primary : SoftColors.line),
      ),
      chipTheme: base.chipTheme.copyWith(shape: _pill),
      dividerTheme: const DividerThemeData(color: SoftColors.line, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SoftColors.white,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: SoftColors.sheetScrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(SoftRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SoftColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.lg)),
        titleTextStyle: SoftType.section.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: SoftColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.md)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SoftColors.ink,
        contentTextStyle: SoftType.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SoftRadius.md)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: SoftColors.primary),
    );
  }
}
