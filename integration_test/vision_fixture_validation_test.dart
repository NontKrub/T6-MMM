import 'dart:convert';
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

    final metadataFile = File('$fixtureDirectory/metadata.json');
    final metadata = metadataFile.existsSync()
        ? (jsonDecode(await metadataFile.readAsString()) as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              Map<String, dynamic>.from(value as Map),
            ),
          )
        : const <String, Map<String, dynamic>>{};
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
      final path = entry.value['path'];
      if (path is String && !fixtures.any((file) => file.path == path)) {
        final file = File(path);
        if (file.existsSync()) fixtures.add(file);
      }
    }
    fixtures.sort((a, b) => a.path.compareTo(b.path));
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
      final expected = metadata[fixture.uri.pathSegments.last];
      if (expected?['category'] is String) {
        expect(result.category?.name, expected!['category']);
      }
      if (expected?['primaryColor'] is String) {
        expect(result.primaryColor, expected!['primaryColor']);
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
  });
}
