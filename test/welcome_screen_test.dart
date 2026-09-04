import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/welcome/welcome_screen.dart';

void main() {
  testWidgets('welcome shows a guest-first path and a sign-in path', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Create my wardrobe'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byTooltip('Choose language'), findsOneWidget);
  });
}
