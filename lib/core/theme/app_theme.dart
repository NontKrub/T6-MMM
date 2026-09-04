import 'package:flutter/material.dart';
import 'app_brand_theme.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandIndigo,
      brightness: Brightness.light,
      surface: AppColors.surfaceRaisedLight,
    );
    return _build(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandIndigo,
      brightness: Brightness.dark,
      surface: AppColors.surfaceRaisedDark,
    );
    return _build(scheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final textColor = isLight
        ? AppColors.textPrimaryLight
        : AppColors.textPrimaryDark;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isLight
          ? AppColors.surfaceLight
          : AppColors.surfaceDark,
      textTheme: AppTypography.textTheme(textColor),
      extensions: [isLight ? MmmBrandTheme.light() : MmmBrandTheme.dark()],
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardBorder),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: AppTypography.textTheme(textColor).titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.surfaceSecondaryLight
            : AppColors.surfaceSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: AppRadii.controlBorder,
          borderSide: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.controlBorder),
          textStyle: AppTypography.textTheme(textColor).labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
