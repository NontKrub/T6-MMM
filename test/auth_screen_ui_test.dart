import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/auth/auth_entry.dart';
import 'package:mix_match_mood/features/auth/auth_screen.dart';
import 'package:go_router/go_router.dart';

void _expectNoFlutterError(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

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

    expect(find.text('Sign in to MMM'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Back to welcome'), findsOneWidget);
    expect(
      tester.getSize(find.text('Continue with Apple')).height,
      greaterThan(0),
    );
  });

  testWidgets(
    'guest chat auth uses contextual copy and no duplicate wardrobe CTA',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
            home: const AuthScreen(
              entry: AuthEntry(
                intent: AuthIntent.unlockAi,
                returnLocation: '/chat',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sign in to use Fashion AI'), findsOneWidget);
      expect(
        find.text(
          'Connect an account to use MMM Stylist with cloud AI features.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to Chat'), findsOneWidget);
      expect(find.text('Create a wardrobe'), findsNothing);
      final googleLabel = tester.widget<Text>(
        find.text('Continue with Google'),
      );
      expect(googleLabel.style?.fontSize, closeTo(18.92, 0.01));
    },
  );

  testWidgets('auth back from chat returns to the originating route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        GoRoute(
          path: '/chat',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(
                '/auth',
                extra: const AuthEntry(
                  intent: AuthIntent.unlockAi,
                  returnLocation: '/chat',
                ),
              ),
              child: const Text('Open auth'),
            ),
          ),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(
            entry: AuthEntry(
              intent: AuthIntent.unlockAi,
              returnLocation: '/chat',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(
      '/auth',
      extra: const AuthEntry(
        intent: AuthIntent.unlockAi,
        returnLocation: '/chat',
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/auth');
    await tester.tap(find.text('Back to Chat'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/chat');
    _expectNoFlutterError(tester);
  });
}
