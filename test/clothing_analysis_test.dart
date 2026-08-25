import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClothingAnalysisService', () {
    const service = ClothingAnalysisService();

    test('extracts deterministic HEX from solid pixels', () async {
      final bytes = await _png([(color: const ui.Color(0xFFFF0000), width: 8)]);

      final first = await service.analyze(bytes);
      final second = await service.analyze(bytes);

      expect(first.colorHexes, ['#FF0000']);
      expect(second.colorHexes, first.colorHexes);
      expect(first.pattern, ClothingPattern.unknown);
      expect(first.silhouette, ClothingSilhouette.unknown);
      expect(first.confidence, isNull);
    });

    test('ranks equal red and blue regions deterministically', () async {
      final result = await service.analyze(
        await _png([
          (color: const ui.Color(0xFFFF0000), width: 4),
          (color: const ui.Color(0xFF0000FF), width: 4),
        ]),
      );

      expect(result.colorHexes, ['#FF0000', '#0000FF']);
    });

    test('groups close beige shades', () async {
      final result = await service.analyze(
        await _png([
          (color: const ui.Color(0xFFE6D5B8), width: 4),
          (color: const ui.Color(0xFFE2D1B4), width: 4),
        ]),
      );

      expect(result.colorHexes, hasLength(1));
      expect(result.colorNames, ['beige']);
    });

    test(
      'combines pixel palette with classifier labels and confidence',
      () async {
        final service = ClothingAnalysisService(
          classifier: (_) async => [_label('shirt', .93)],
        );
        final result = await service.analyze(
          await _png([(color: const ui.Color(0xFF3366FF), width: 8)]),
        );

        expect(result.colorHexes, ['#3366FF']);
        expect(result.category, ClothingCategory.top);
        expect(result.confidence, .93);
        expect(result.rawLabels, ['shirt']);
        expect(result.rawPredictions.single.confidence, .93);
      },
    );
  });

  group('HEX helpers', () {
    test('normalizes valid values and rejects invalid values', () {
      expect(normalizeHexColor('ff0000'), '#FF0000');
      expect(normalizeHexColor('#FFFFFF'), '#FFFFFF');
      expect(normalizeHexColor('#12'), isNull);
      expect(normalizeHexColor('#GGGGGG'), isNull);
      expect(normalizeHexColor('hello'), isNull);
    });

    test('computes RGB distance', () {
      expect(colorDistance('#000000', '#000000'), 0);
      expect(colorDistance('#000000', '#FFFFFF'), closeTo(441.67, 0.01));
    });
  });

  group('Vision label mapping', () {
    test('maps supported clothing categories conservatively', () {
      expect(
        mapClothingLabels([_label('shirt', .91)]).category,
        ClothingCategory.top,
      );
      expect(
        mapClothingLabels([_label('jeans', .88)]).category,
        ClothingCategory.pants,
      );
      expect(
        mapClothingLabels([_label('shoe', .84)]).category,
        ClothingCategory.shoes,
      );
      expect(
        mapClothingLabels([_label('baseball cap', .79)]).category,
        ClothingCategory.hat,
      );
      expect(
        mapClothingLabels([_label('handbag', .82)]).category,
        ClothingCategory.accessory,
      );
    });

    test('rejects unknown and low-confidence category labels', () {
      expect(mapClothingLabels([_label('furniture', .99)]).category, isNull);
      expect(mapClothingLabels([_label('shirt', .39)]).category, isNull);
    });

    test('keeps generic labels unknown and maps explicit patterns', () {
      for (final label in ['textile', 'fabric', 'clothing']) {
        final result = mapClothingLabels([_label(label, .99)]);
        expect(result.category, isNull, reason: label);
        expect(result.pattern, ClothingPattern.unknown, reason: label);
        expect(result.silhouette, ClothingSilhouette.unknown, reason: label);
      }

      expect(
        mapClothingLabels([_label('striped', .9)]).pattern,
        ClothingPattern.striped,
      );
      expect(
        mapClothingLabels([_label('plaid', .9)]).pattern,
        ClothingPattern.checked,
      );
      expect(
        mapClothingLabels([_label('knitted', .9)]).pattern,
        ClothingPattern.textured,
      );
    });

    test('propagates genuine confidence, styles, pattern, and raw labels', () {
      final result = mapClothingLabels([
        _label('blazer', .87),
        _label('businesswear', .72),
        _label('striped', .66),
      ]);

      expect(result.category, ClothingCategory.top);
      expect(result.confidence, .87);
      expect(result.styles, containsAll(['formal', 'work']));
      expect(result.pattern, ClothingPattern.striped);
      expect(result.silhouette, ClothingSilhouette.unknown);
      expect(result.rawLabels, ['blazer', 'businesswear', 'striped']);
      expect(result.rawPredictions, hasLength(3));
    });
  });
}

ImageLabelPrediction _label(String text, double confidence) =>
    ImageLabelPrediction(text: text, confidence: confidence);

Future<Uint8List> _png(List<({ui.Color color, int width})> bands) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  var left = 0.0;
  for (final band in bands) {
    canvas.drawRect(
      ui.Rect.fromLTWH(left, 0, band.width.toDouble(), 8),
      ui.Paint()..color = band.color,
    );
    left += band.width;
  }
  final image = await recorder.endRecording().toImage(left.toInt(), 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
