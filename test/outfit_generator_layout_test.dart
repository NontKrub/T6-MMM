import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';

void main() {
  testWidgets('empty home directs people to add clothing before generation', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add clothing'), findsOneWidget);
    expect(find.text('Generate Outfit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
