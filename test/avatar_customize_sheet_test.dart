import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';

void main() {
  testWidgets(
    'avatar customisation keeps choice targets usable and dismisses by drag',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byTooltip('Customize'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Your Avatar'), findsOneWidget);
      final humanCard = find.ancestor(
        of: find.text('Human'),
        matching: find.byType(AnimatedContainer),
      );
      expect(humanCard, findsOneWidget);
      expect(tester.getSize(humanCard).width, greaterThan(80));

      final tousledY = tester.getTopLeft(find.text('Tousled')).dy;
      final sideSweptY = tester.getTopLeft(find.text('Side Swept')).dy;
      expect(sideSweptY, closeTo(tousledY, 0.1));

      await tester.drag(find.text('Your Avatar'), const Offset(0, 700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Your Avatar'), findsNothing);
    },
  );
}
