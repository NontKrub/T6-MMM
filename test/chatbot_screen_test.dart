import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/ai_consent_provider.dart';
import 'package:mix_match_mood/core/providers/session_provider.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/chatbot/chatbot_screen.dart';

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
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
  });
}
