import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/session_provider.dart';
import 'package:mix_match_mood/core/providers/user_profile_provider.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/auth/auth_entry.dart';
import 'package:mix_match_mood/features/auth/auth_screen.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _DelayedProfileRepository extends ProfileRepository {
  _DelayedProfileRepository(this.profile);

  final UserProfile profile;
  final load = Completer<UserProfile?>();
  var fetchCount = 0;

  @override
  Future<UserProfile?> fetchProfile() {
    fetchCount++;
    return fetchCount == 1 ? Future.value(profile) : load.future;
  }
}

void _expectNoFlutterError(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('signed-in callback refreshes the cached app session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const profile = UserProfile(
      id: 'user-id',
      name: 'MMM User',
      onboardingComplete: true,
    );
    final authState = Completer<AuthState>();
    final repository = _DelayedProfileRepository(profile);
    final notifier = UserProfileNotifier(null, repository);
    var signedIn = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((_) => notifier),
          sessionProvider.overrideWith(
            (_) async => AppSession(
              hasGuestAccount: false,
              isSupabaseAuthenticated: signedIn,
            ),
          ),
        ],
        child: MaterialApp(
          home: Stack(
            children: [
              AuthScreen(authStateChanges: authState.future.asStream()),
              Positioned(
                child: Consumer(
                  builder: (_, ref, _) {
                    final signedIn = ref
                        .watch(sessionProvider)
                        .maybeWhen(
                          data: (session) => session.isSupabaseAuthenticated,
                          orElse: () => false,
                        );
                    return Text(signedIn ? 'signed-in' : 'signed-out');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('signed-out'), findsOneWidget);

    signedIn = true;
    authState.complete(const AuthState(AuthChangeEvent.signedIn, null));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('signed-in'), findsOneWidget);
  });

  testWidgets('ignores a signed-in callback after auth is unmounted', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const profile = UserProfile(
      id: 'user-id',
      name: 'MMM User',
      onboardingComplete: true,
    );
    final authState = Completer<AuthState>();
    final repository = _DelayedProfileRepository(profile);
    final notifier = UserProfileNotifier(null, repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [userProfileProvider.overrideWith((_) => notifier)],
        child: MaterialApp(
          home: AuthScreen(authStateChanges: authState.future.asStream()),
        ),
      ),
    );
    await tester.pump();

    authState.complete(const AuthState(AuthChangeEvent.signedIn, null));
    await tester.pump();
    expect(repository.fetchCount, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    repository.load.complete(profile);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    _expectNoFlutterError(tester);
  });

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
