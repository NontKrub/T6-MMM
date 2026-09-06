import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_brand_theme.dart';
import 'package:mix_match_mood/core/theme/app_colors.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/shared/widgets/mmm_choice_chip.dart';
import 'package:mix_match_mood/shared/widgets/mmm_gradient_button.dart';

void main() {
  test('Thai theme uses an explicit Thai fallback family', () {
    final theme = AppTheme.light(locale: const Locale('th'));
    final english = AppTheme.light().textTheme.headlineMedium!.fontSize!;
    final thai = theme.textTheme.headlineMedium!.fontSize!;

    expect(
      theme.textTheme.headlineMedium?.fontFamilyFallback,
      contains('Noto Sans Thai'),
    );
    expect(thai, closeTo(english * 0.9, 0.01));
  });

  testWidgets('MMM theme exposes documented gradient in both appearances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            final brand = MmmBrandTheme.of(context);
            return Text('${brand.primaryGradient.colors.length}');
          },
        ),
      ),
    );

    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(theme.theme!.extension<MmmBrandTheme>()!.primaryGradient.colors, [
      AppColors.brandBlue,
      AppColors.brandViolet,
      AppColors.brandPink,
    ]);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('gradient button and choice chip meet minimum target semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              MmmGradientButton(label: 'Continue', onPressed: () {}),
              MmmChoiceChip(
                label: 'Casual',
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MmmGradientButton)).height, 52);
    expect(
      tester.getSize(find.byType(MmmChoiceChip)).height,
      greaterThanOrEqualTo(48),
    );
    final button = tester.getSemantics(find.byType(MmmGradientButton));
    final chip = tester.getSemantics(find.byType(MmmChoiceChip));
    expect(button.label, 'Continue');
    expect(button.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(chip.label, 'Casual');
    expect(chip.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });
}
