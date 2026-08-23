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
}

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
