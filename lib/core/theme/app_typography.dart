import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color color) =>
      GoogleFonts.plusJakartaSansTextTheme()
          .apply(bodyColor: color, displayColor: color)
          .copyWith(
            displaySmall: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              height: 38 / 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            headlineMedium: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              height: 34 / 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            titleMedium: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            bodyLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              height: 23 / 16,
              color: color,
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 20 / 14,
              color: color,
            ),
            labelLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              height: 20 / 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          );
}
