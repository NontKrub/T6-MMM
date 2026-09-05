import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';
import 'package:mix_match_mood/features/shell/main_shell.dart';
import 'package:mix_match_mood/shared/widgets/floating_nav_bar.dart';
import 'package:mix_match_mood/shared/widgets/mmm_secondary_button.dart';

void main() {
  testWidgets('home actions sit directly above the floating dock', (
    tester,
  ) async {
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

    final dockTop = tester.getTopLeft(find.byType(FloatingNavBar)).dy;
    final rushButton = find.ancestor(
      of: find.text('In a Rush'),
      matching: find.byType(MmmSecondaryButton),
    );
    final rushBottom = tester.getRect(rushButton).bottom;
    expect(dockTop - rushBottom, lessThanOrEqualTo(40));
  });
}
