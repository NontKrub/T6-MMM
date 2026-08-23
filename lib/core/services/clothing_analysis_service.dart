import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../shared/models/clothing_item.dart';

class ClothingAnalysisResult {
  const ClothingAnalysisResult({
    this.category,
    required this.colorHexes,
    required this.colorNames,
    this.styles = const [],
    this.pattern = ClothingPattern.unknown,
    this.silhouette = ClothingSilhouette.unknown,
    this.confidence,
    this.rawLabels = const [],
  });

  final ClothingCategory? category;
  final List<String> colorHexes;
  final List<String> colorNames;
  final List<String> styles;
  final ClothingPattern pattern;
  final ClothingSilhouette silhouette;
  final double? confidence;
  final List<String> rawLabels;
}

class ClothingAnalysisService {
  const ClothingAnalysisService();

  Future<ClothingAnalysisResult> analyze(Uint8List bytes) async {
    var codec = await ui.instantiateImageCodec(bytes);
    var frame = await codec.getNextFrame();
    if (frame.image.width > 64) {
      frame.image.dispose();
      codec.dispose();
      codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      frame = await codec.getNextFrame();
    }
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    frame.image.dispose();
    codec.dispose();
    if (data == null) throw StateError('Unable to read image pixels.');

    final buckets = <int, _ColorBucket>{};
    final pixels = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    for (var i = 0; i < pixels.length; i += 4) {
      final alpha = pixels[i + 3];
      if (alpha < 32) continue;
      final red = pixels[i];
      final green = pixels[i + 1];
      final blue = pixels[i + 2];
      final key = (red ~/ 32 << 16) | (green ~/ 32 << 8) | (blue ~/ 32);
      (buckets[key] ??= _ColorBucket(i)).add(red, green, blue);
    }
    final ranked = buckets.values.toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.firstPixel.compareTo(b.firstPixel);
      });
    final hexes = ranked.take(3).map((bucket) => bucket.hex).toList();
    return ClothingAnalysisResult(
      colorHexes: hexes,
      colorNames: hexes.map(coarseColorName).toList(),
    );
  }
}

class _ColorBucket {
  _ColorBucket(this.firstPixel);

  final int firstPixel;
  var count = 0;
  var red = 0;
  var green = 0;
  var blue = 0;

  void add(int r, int g, int b) {
    count++;
    red += r;
    green += g;
    blue += b;
  }

  String get hex => _rgbToHex(red ~/ count, green ~/ count, blue ~/ count);
}

String? normalizeHexColor(String value) {
  final normalized = value.trim().toUpperCase();
  final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash) ? withHash : null;
}

double colorDistance(String first, String second) {
  final a = _hexToRgb(first);
  final b = _hexToRgb(second);
  return math.sqrt(
    math.pow(a.$1 - b.$1, 2) +
        math.pow(a.$2 - b.$2, 2) +
        math.pow(a.$3 - b.$3, 2),
  );
}

String coarseColorName(String hex) {
  const references = <String, String>{
    'black': '#111111',
    'white': '#F5F5F5',
    'gray': '#808080',
    'red': '#D32F2F',
    'blue': '#1976D2',
    'green': '#388E3C',
    'brown': '#795548',
    'beige': '#DFCCAA',
    'yellow': '#FBC02D',
    'orange': '#F57C00',
    'purple': '#7B1FA2',
    'pink': '#E91E63',
  };
  return references.entries.reduce((best, entry) {
    return colorDistance(hex, entry.value) < colorDistance(hex, best.value)
        ? entry
        : best;
  }).key;
}

(int, int, int) _hexToRgb(String value) {
  final hex = normalizeHexColor(value);
  if (hex == null) throw FormatException('Invalid HEX color: $value');
  return (
    int.parse(hex.substring(1, 3), radix: 16),
    int.parse(hex.substring(3, 5), radix: 16),
    int.parse(hex.substring(5, 7), radix: 16),
  );
}

String _rgbToHex(int red, int green, int blue) =>
    '#${red.toRadixString(16).padLeft(2, '0')}'
            '${green.toRadixString(16).padLeft(2, '0')}'
            '${blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
