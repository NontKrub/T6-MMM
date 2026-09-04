import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/shared/widgets/mmm_brand_mark.dart';

void main() {
  testWidgets('renders the approved mark with an accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: MmmBrandMark(size: 64))),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/mmm_mark.png',
    );
    expect(find.bySemanticsLabel('MMM logo mark'), findsOneWidget);
  });

  testWidgets('uses the dark supplied mark variant in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Center(child: MmmBrandMark(size: 64)),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/mmm_mark_dark.png',
    );
  });
}
