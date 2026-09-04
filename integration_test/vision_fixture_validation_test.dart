import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/core/services/clothing_evaluation_harness.dart';

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

    final metadataFile = File('$fixtureDirectory/metadata.json');
    final metadata = metadataFile.existsSync()
        ? (jsonDecode(await metadataFile.readAsString()) as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              ClothingEvaluationFixture.fromJson(
                key.toString(),
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          )
        : const <String, ClothingEvaluationFixture>{};
    final fixtures = Directory(fixtureDirectory)
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'\.(png|jpe?g)$',
            caseSensitive: false,
          ).hasMatch(file.path),
        )
        .toList();
    for (final entry in metadata.entries) {
      final path = entry.value.path;
      if (!fixtures.any((file) => file.path == path)) {
        final file = File(path);
        if (file.existsSync()) fixtures.add(file);
      }
    }
    fixtures.sort((a, b) => a.path.compareTo(b.path));
    expect(fixtures, isNotEmpty);

    final evaluationFixtures = fixtures.map((file) {
      final name = file.uri.pathSegments.last;
      final fixture = metadata[name];
      return ClothingEvaluationFixture(
        name: name,
        path: file.path,
        expectedCategory: fixture?.expectedCategory ?? 'unknown',
        expectedPrimaryColor: fixture?.expectedPrimaryColor,
        conditions: fixture?.conditions ?? const [],
      );
    }).toList();
    final missingCoverage = ClothingEvaluationHarness.missingCoverage(
      evaluationFixtures,
    );
    expect(
      missingCoverage,
      isEmpty,
      reason: 'Evaluation set is incomplete: ${missingCoverage.join(', ')}',
    );

    final records = await ClothingEvaluationHarness().evaluate(
      evaluationFixtures,
      localAnalyzer: (bytes) => const ClothingAnalysisService().analyze(bytes),
    );
    for (final record in records) {
      final result = record.local;
      final fixture = File(record.fixture.path);
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
      final expected = record.fixture.expectedCategory;
      if (expected != 'unknown') {
        expect(result.category?.name, expected);
      }
      if (record.fixture.expectedPrimaryColor != null) {
        expect(result.primaryColor, record.fixture.expectedPrimaryColor);
      }
      expect(result.rawPredictions, isNotEmpty);
      expect(
        result.rawPredictions.every(
          (prediction) =>
              prediction.confidence >= 0 && prediction.confidence <= 1,
        ),
        isTrue,
      );
    }

    const outputPath = String.fromEnvironment('VISION_EVALUATION_OUTPUT');
    if (outputPath.isNotEmpty) {
      await File(
        outputPath,
      ).writeAsString(ClothingEvaluationHarness.encodeResults(records));
    }
  });
}
