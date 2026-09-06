import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/providers/ai_consent_provider.dart';
import 'package:mix_match_mood/core/providers/chat_provider.dart';
import 'package:mix_match_mood/core/providers/session_provider.dart';
import 'package:mix_match_mood/core/theme/app_spacing.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/chatbot/chatbot_screen.dart';
import 'package:mix_match_mood/features/shell/main_shell.dart';
import 'package:mix_match_mood/shared/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('chat composer uses one surface and a full-size send target', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            (ref) async => const AppSession(
              hasGuestAccount: false,
              isSupabaseAuthenticated: true,
            ),
          ),
          aiConsentProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const ChatbotScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.decoration?.filled, isFalse);
    expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)), const Size(44, 44));
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-composer'))).height,
      52,
    );
  });

  testWidgets('chat shows an accessible three-dot typing bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            (ref) async => const AppSession(
              hasGuestAccount: false,
              isSupabaseAuthenticated: true,
            ),
          ),
          aiConsentProvider.overrideWith((ref) async => true),
          chatTypingProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const ChatbotScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-typing-indicator')), findsOneWidget);
    expect(find.bySemanticsLabel('MMM is thinking…'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-typing-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-typing-dot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-typing-dot-2')), findsOneWidget);
  });

  testWidgets('chat composer clears the floating navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(686, 418));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/chat', builder: (_, _) => const ChatbotScreen()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(
            (ref) async => const AppSession(
              hasGuestAccount: false,
              isSupabaseAuthenticated: true,
            ),
          ),
          aiConsentProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.getRect(
      find.byKey(const ValueKey('chat-composer')),
    );
    final navigation = tester.getRect(find.byType(FloatingNavBar));
    expect(
      composer.bottom,
      lessThanOrEqualTo(navigation.top - AppSpacing.xxl - 5),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final keyboardTop = 418 - 180.0;
    final keyboardComposer = tester.getRect(
      find.byKey(const ValueKey('chat-composer')),
    );
    expect(
      keyboardTop - keyboardComposer.bottom,
      lessThanOrEqualTo(AppSpacing.md),
    );
  });
}
