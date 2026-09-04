import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_brand_theme.dart';
import 'package:mix_match_mood/core/theme/app_colors.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/welcome/welcome_screen.dart';

void main() {
  testWidgets('welcome keeps a neutral dark canvas and vivid brand gradient', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const WelcomeScreen()),
    );

    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(theme.scaffoldBackgroundColor, AppColors.surfaceDark);
    expect(theme.extension<MmmBrandTheme>()!.primaryGradient.colors, [
      AppColors.brandBlue,
      AppColors.brandViolet,
      AppColors.brandPink,
    ]);
    expect(find.text('Create my wardrobe'), findsOneWidget);
  });
}
