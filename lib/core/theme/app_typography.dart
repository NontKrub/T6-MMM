import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color color, {Locale? locale}) {
    final useThai = locale?.languageCode == 'th';
    // Thai fallback glyph boxes are optically larger on iOS. A small optical
    // adjustment preserves the same hierarchy while MediaQuery text scaling
    // remains fully respected.
    final typeScale = useThai ? 0.9 : 1.0;

    TextStyle style({
      required double fontSize,
      required double height,
      FontWeight? fontWeight,
    }) {
      final base = TextStyle(
        fontSize: fontSize * typeScale,
        height: height,
        fontWeight: fontWeight,
        color: color,
      );
      final plusJakarta = GoogleFonts.plusJakartaSans(textStyle: base);
      return useThai
          ? plusJakarta.copyWith(
              // Keep Plus Jakarta Sans for Latin while giving Thai glyphs a
              // stable, explicit fallback before the platform default.
              fontFamilyFallback: const [
                'Noto Sans Thai',
                'Sarabun',
                'Plus Jakarta Sans',
              ],
            )
          : plusJakarta;
    }

    final baseTheme = GoogleFonts.plusJakartaSansTextTheme();
    return baseTheme
        .apply(bodyColor: color, displayColor: color)
        .copyWith(
          displaySmall: style(
            fontSize: 32,
            height: 38 / 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: style(
            fontSize: 28,
            height: 34 / 28,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: style(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: style(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: style(fontSize: 16, height: 23 / 16),
          bodyMedium: style(fontSize: 14, height: 20 / 14),
          bodySmall: style(fontSize: 12, height: 16 / 12),
          labelLarge: style(
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: style(
            fontSize: 11,
            height: 16 / 11,
            fontWeight: FontWeight.w500,
          ),
        );
  }
}
