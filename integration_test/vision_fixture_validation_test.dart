import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records native labels for local validation fixtures', (
    tester,
  ) async {
    const fixtureDirectory = String.fromEnvironment('VISION_FIXTURE_DIR');
    if (fixtureDirectory.isEmpty) {
      markTestSkipped(
        'Set VISION_FIXTURE_DIR to run local fixture validation.',
      );
      return;
    }

    final fixtures =
        Directory(fixtureDirectory)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(fixtures, isNotEmpty);

    for (final fixture in fixtures) {
      final result = await const ClothingAnalysisService().analyze(
        await fixture.readAsBytes(),
      );
      final labels = result.rawPredictions
          .take(20)
          .map(
            (prediction) =>
                '${prediction.text}=${prediction.confidence.toStringAsFixed(4)}',
          )
          .join(', ');
      // Debug-only output; raw predictions are never persisted.
      // ignore: avoid_print
      print(
        '${fixture.uri.pathSegments.last}: '
        'palette=${result.colorHexes.join('/')} labels=$labels',
      );
      expect(result.rawPredictions, isNotEmpty);
      expect(
        result.rawPredictions.every(
          (prediction) =>
              prediction.confidence >= 0 && prediction.confidence <= 1,
        ),
        isTrue,
      );
    }
  });
}
