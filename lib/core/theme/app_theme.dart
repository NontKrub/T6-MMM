import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static ThemeData _build() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accentGold,
      onPrimary: AppColors.backgroundBase,
      secondary: AppColors.accentGold,
      onSecondary: AppColors.backgroundBase,
      surface: AppColors.backgroundSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundElevated,
      outline: AppColors.borderSubtle,
      onSurfaceVariant: AppColors.textSecondary,
      brightness: Brightness.dark,
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundBase,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.backgroundBase,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderMedium, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.accentGold
                : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.accentGoldFaint
                : AppColors.backgroundElevated),
        trackOutlineColor:
            const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(),
        backgroundColor: AppColors.backgroundSurface,
        side: BorderSide(color: AppColors.borderSubtle, width: 1),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSurface,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
      ),
    );
  }
}
