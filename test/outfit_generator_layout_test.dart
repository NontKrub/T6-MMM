import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';
import 'package:mix_match_mood/features/outfit_generator/outfit_generator_sheet.dart';

void main() {
  testWidgets('generator sheet ends shortly after its primary action', (
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
    await tester.tap(find.text('Generate Outfit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final sheet = tester.getRect(find.byType(OutfitGeneratorSheet));
    final action = tester.getRect(find.text('Generate outfit'));
    expect(sheet.height, lessThan(760));
    expect(sheet.bottom - action.bottom, lessThanOrEqualTo(60));
    expect(tester.takeException(), isNull);
  });
}
