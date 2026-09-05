import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/core/theme/app_radii.dart';
import 'package:mix_match_mood/shared/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('shell navigation exposes four labeled destinations', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        for (final path in ['/home', '/wardrobe', '/missing', '/chat'])
          GoRoute(
            path: path,
            builder: (_, __) => Scaffold(
              body: Text(path),
              bottomNavigationBar: const FloatingNavBar(),
            ),
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      AppRadii.heroBorder,
    );
    expect(
      tester
          .widgetList<Material>(find.byType(Material))
          .any(
            (material) =>
                material.borderRadius == AppRadii.emphasizedCardBorder,
          ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('nav-/wardrobe')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/wardrobe');
  });
}
