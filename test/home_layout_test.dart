import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';
import 'package:mix_match_mood/features/shell/main_shell.dart';
import 'package:mix_match_mood/shared/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('home leads with wardrobe styling and settings', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final home = tester.getRect(find.byType(HomeScreen));
    final settings = tester.getRect(find.byTooltip('Settings'));
    expect(settings.right, greaterThan(home.right - 48));
    expect(find.text('What are we wearing today?'), findsOneWidget);
    expect(find.text('Your wardrobe starts here.'), findsOneWidget);
    expect(find.text('Add clothing'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });
}
