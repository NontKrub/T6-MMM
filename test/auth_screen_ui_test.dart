import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/auth/auth_screen.dart';

void main() {
  testWidgets('auth presents equal provider choices and a guest-first exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
          home: const AuthScreen(),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('New to MMM? Create a wardrobe'), findsOneWidget);
    expect(
      tester.getSize(find.text('Continue with Apple')).height,
      greaterThan(0),
    );
  });
}
