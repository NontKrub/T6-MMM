import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/shared/widgets/mmm_choice_chip.dart';
import 'package:mix_match_mood/shared/widgets/mmm_gradient_button.dart';

void main() {
  testWidgets('primary controls expose labels and minimum tap targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              MmmGradientButton(label: 'Continue', onPressed: () {}),
              MmmChoiceChip(
                label: 'Casual',
                selected: false,
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
    expect(
      tester.getSemantics(find.byType(MmmGradientButton)).label,
      'Continue',
    );
    expect(tester.getSemantics(find.byType(MmmChoiceChip)).label, 'Casual');
  });
}
