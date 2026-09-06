import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('guest onboarding starts with one focused question', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(isGuest: true),
        ),
      ),
    );

    expect(find.text('Tell us about you'), findsOneWidget);
    expect(find.text('1 of 5'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.getSize(find.text('Continue')).height, greaterThan(0));
  });
}
