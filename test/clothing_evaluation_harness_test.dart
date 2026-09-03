import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_evaluation_harness.dart';
import 'package:mix_match_mood/shared/models/clothing_analysis.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test('reports incomplete category coverage', () {
    final fixtures = [
      for (var index = 0; index < 5; index++)
        ClothingEvaluationFixture(
          name: 'top-$index.jpg',
          path: 'top-$index.jpg',
          expectedCategory: 'top',
        ),
    ];

    expect(
      ClothingEvaluationHarness.missingCoverage(fixtures),
      contains('pants: 0/5'),
    );
  });

  test('records local review state and optional server result', () async {
    final directory = await Directory.systemTemp.createTemp('mmm-eval-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/fixture.jpg';
    await File(path).writeAsBytes([1, 2, 3]);
    final fixture = ClothingEvaluationFixture(
      name: 'fixture.jpg',
      path: path,
      expectedCategory: 'top',
      conditions: ['low_light'],
    );

    final records = await ClothingEvaluationHarness().evaluate(
      [fixture],
      localAnalyzer: (_) async => const ClothingAnalysisResult(
        colorHexes: [],
        colorNames: [],
        confidence: .2,
      ),
      serverAnalyzer: (_) async => const ClothingAnalysisResult(
        category: ClothingCategory.top,
        colorHexes: [],
        colorNames: [],
        confidence: .91,
        source: AnalysisSource.serverAI,
      ),
    );

    final json = records.single.toJson();
    expect(json['expected_category'], 'top');
    expect(json['local_predicted_category'], isNull);
    expect(json['local_confidence'], .2);
    expect(json['server_predicted_category'], 'top');
    expect(json['server_confidence'], .91);
    expect(json['user_review_requested'], isTrue);
  });
}
