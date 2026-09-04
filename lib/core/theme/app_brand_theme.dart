import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class MmmBrandTheme extends ThemeExtension<MmmBrandTheme> {
  const MmmBrandTheme({
    required this.primaryGradient,
    required this.primaryGradientReversed,
    required this.neutralSurface,
    required this.raisedSurface,
    required this.subtleAccentSurface,
    required this.subtleBorder,
    required this.success,
    required this.warning,
    required this.destructive,
  });

  final LinearGradient primaryGradient;
  final LinearGradient primaryGradientReversed;
  final Color neutralSurface;
  final Color raisedSurface;
  final Color subtleAccentSurface;
  final Color subtleBorder;
  final Color success;
  final Color warning;
  final Color destructive;

  static MmmBrandTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<MmmBrandTheme>() ??
        (theme.brightness == Brightness.dark ? dark() : light());
  }

  static MmmBrandTheme light() => const MmmBrandTheme(
    primaryGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [AppColors.brandBlue, AppColors.brandViolet, AppColors.brandPink],
    ),
    primaryGradientReversed: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [AppColors.brandBlue, AppColors.brandViolet, AppColors.brandPink],
    ),
    neutralSurface: AppColors.surfaceLight,
    raisedSurface: AppColors.surfaceRaisedLight,
    subtleAccentSurface: Color(0x14317DFD),
    subtleBorder: AppColors.borderLight,
    success: AppColors.success,
    warning: AppColors.warning,
    destructive: AppColors.destructive,
  );

  static MmmBrandTheme dark() => const MmmBrandTheme(
    primaryGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [AppColors.brandBlue, AppColors.brandViolet, AppColors.brandPink],
    ),
    primaryGradientReversed: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [AppColors.brandBlue, AppColors.brandViolet, AppColors.brandPink],
    ),
    neutralSurface: AppColors.surfaceDark,
    raisedSurface: AppColors.surfaceRaisedDark,
    subtleAccentSurface: Color(0x1F317DFD),
    subtleBorder: AppColors.borderDark,
    success: Color(0xFF5AD29A),
    warning: Color(0xFFFFB957),
    destructive: Color(0xFFFF8794),
  );

  @override
  MmmBrandTheme copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? primaryGradientReversed,
    Color? neutralSurface,
    Color? raisedSurface,
    Color? subtleAccentSurface,
    Color? subtleBorder,
    Color? success,
    Color? warning,
    Color? destructive,
  }) => MmmBrandTheme(
    primaryGradient: primaryGradient ?? this.primaryGradient,
    primaryGradientReversed:
        primaryGradientReversed ?? this.primaryGradientReversed,
    neutralSurface: neutralSurface ?? this.neutralSurface,
    raisedSurface: raisedSurface ?? this.raisedSurface,
    subtleAccentSurface: subtleAccentSurface ?? this.subtleAccentSurface,
    subtleBorder: subtleBorder ?? this.subtleBorder,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    destructive: destructive ?? this.destructive,
  );

  @override
  MmmBrandTheme lerp(MmmBrandTheme? other, double t) {
    if (other is! MmmBrandTheme) return this;
    return MmmBrandTheme(
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      primaryGradientReversed: LinearGradient.lerp(
        primaryGradientReversed,
        other.primaryGradientReversed,
        t,
      )!,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t)!,
      raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,
      subtleAccentSurface: Color.lerp(
        subtleAccentSurface,
        other.subtleAccentSurface,
        t,
      )!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}
