import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/splash/splash_screen.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';

GoRouter _routerFor(SplashScreen splash) => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => splash),
    GoRoute(path: '/language', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/welcome', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/onboarding', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
  ],
);

Future<GoRouter> _pumpSplash(
  WidgetTester tester, {
  required bool signedIn,
  Future<UserProfile?> Function()? loadProfile,
  Future<bool> Function()? hasChosenLanguage,
  Duration profileTimeout = const Duration(seconds: 1),
}) async {
  final router = _routerFor(
    SplashScreen(
      signedIn: signedIn,
      loadProfile: loadProfile,
      hasChosenLanguage: hasChosenLanguage ?? () async => true,
      profileTimeout: profileTimeout,
    ),
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('new install routes to language before loading profile', (
    tester,
  ) async {
    var called = false;
    final router = await _pumpSplash(
      tester,
      signedIn: false,
      hasChosenLanguage: () async => false,
      loadProfile: () async {
        called = true;
        return null;
      },
    );

    expect(router.state.uri.path, '/language');
    expect(called, isFalse);
  });

  testWidgets('language state failure has a deterministic language fallback', (
    tester,
  ) async {
    final router = await _pumpSplash(
      tester,
      signedIn: false,
      hasChosenLanguage: () =>
          Future<bool>.error(StateError('storage unavailable')),
      loadProfile: () async => null,
    );

    expect(router.state.uri.path, '/language');
  });

  testWidgets('completed local guest profile enters home', (tester) async {
    final router = await _pumpSplash(
      tester,
      signedIn: false,
      loadProfile: () async => const UserProfile(
        id: 'local_guest',
        name: 'Guest',
        onboardingComplete: true,
      ),
    );

    expect(router.state.uri.path, '/home');
  });

  testWidgets('signed-in incomplete profile enters onboarding', (tester) async {
    final router = await _pumpSplash(
      tester,
      signedIn: true,
      loadProfile: () async => const UserProfile(id: 'user', name: 'User'),
    );

    expect(router.state.uri.path, '/onboarding');
  });

  testWidgets('signed-in profile failure still enters a usable home', (
    tester,
  ) async {
    final router = await _pumpSplash(
      tester,
      signedIn: true,
      loadProfile: () => Future<UserProfile?>.error(StateError('offline')),
    );

    expect(router.state.uri.path, '/home');
  });

  testWidgets('signed-in profile timeout does not leave splash mounted', (
    tester,
  ) async {
    final pending = Completer<UserProfile?>();
    final router = await _pumpSplash(
      tester,
      signedIn: true,
      loadProfile: () => pending.future,
      profileTimeout: const Duration(milliseconds: 20),
    );

    expect(router.state.uri.path, '/home');
  });
}
