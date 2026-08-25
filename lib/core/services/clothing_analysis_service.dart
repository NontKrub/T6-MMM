import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/models/clothing_item.dart';

const _visionChannel = MethodChannel('mmm/clothing_analysis');

class ImageLabelPrediction {
  const ImageLabelPrediction({required this.text, required this.confidence});

  final String text;
  final double confidence;
}

typedef ImageClassifier =
    Future<List<ImageLabelPrediction>> Function(Uint8List bytes);

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
    this.rawPredictions = const [],
    this.classificationSource,
    this.colorSource,
  });

  final ClothingCategory? category;
  final List<String> colorHexes;
  final List<String> colorNames;
  final List<String> styles;
  final ClothingPattern pattern;
  final ClothingSilhouette silhouette;
  final double? confidence;
  final List<String> rawLabels;
  final List<ImageLabelPrediction> rawPredictions;
  final String? classificationSource;
  final String? colorSource;
}

class ClothingAnalysisService {
  const ClothingAnalysisService({
    ImageClassifier? classifier,
    String? classificationSource,
  }) : _classifier = classifier,
       _classificationSource = classificationSource;

  final ImageClassifier? _classifier;
  final String? _classificationSource;

  Future<ClothingAnalysisResult> analyze(Uint8List bytes) async {
    final labelsFuture = (_classifier ?? _classifyOnDevice)(bytes);
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
    final predictions = await labelsFuture;
    final labelResult = mapClothingLabels(predictions);
    return ClothingAnalysisResult(
      category: labelResult.category,
      colorHexes: hexes,
      colorNames: hexes.map(coarseColorName).toList(),
      styles: labelResult.styles,
      pattern: labelResult.pattern,
      silhouette: labelResult.silhouette,
      confidence: labelResult.confidence,
      rawLabels: labelResult.rawLabels,
      rawPredictions: predictions,
      classificationSource: predictions.isEmpty
          ? null
          : (_classificationSource ?? _platformClassificationSource),
      colorSource: 'pixel_palette',
    );
  }
}

Future<List<ImageLabelPrediction>> _classifyOnDevice(Uint8List bytes) async {
  if (!Platform.isIOS && !Platform.isAndroid) return const [];
  final result = await _visionChannel.invokeListMethod<Object?>(
    'classifyImage',
    bytes,
  );
  final predictions = (result ?? const [])
      .whereType<Map>()
      .map((row) => Map<String, Object?>.from(row))
      .where((row) => row['label'] is String && row['confidence'] is num)
      .map(
        (row) => ImageLabelPrediction(
          text: row['label']! as String,
          confidence: (row['confidence']! as num).toDouble(),
        ),
      )
      .toList();
  if (kDebugMode) {
    for (final prediction in predictions.take(20)) {
      debugPrint(
        'Clothing analysis: ${prediction.text} '
        '${prediction.confidence.toStringAsFixed(4)}',
      );
    }
  }
  return predictions;
}

String? get _platformClassificationSource => Platform.isIOS
    ? 'ios_vision'
    : Platform.isAndroid
    ? 'android_mlkit'
    : null;

ClothingAnalysisResult mapClothingLabels(
  List<ImageLabelPrediction> labels, {
  double categoryThreshold = .5,
}) {
  const categories = <ClothingCategory, Set<String>>{
    ClothingCategory.top: {
      'shirt',
      't shirt',
      't-shirt',
      'blouse',
      'sweater',
      'jacket',
      'hoodie',
      'blazer',
      'cardigan',
      'coat',
      'top',
      'jersey',
    },
    ClothingCategory.pants: {
      'pants',
      'trousers',
      'jeans',
      'shorts',
      'skirt',
      'leggings',
      'bottoms',
    },
    ClothingCategory.shoes: {
      'shoe',
      'shoes',
      'footwear',
      'sneaker',
      'sneakers',
      'boot',
      'boots',
      'loafer',
      'loafers',
      'sandal',
      'sandals',
    },
    ClothingCategory.hat: {'hat', 'cap', 'baseball cap', 'beanie', 'headwear'},
    ClothingCategory.accessory: {
      'accessory',
      'fashion accessory',
      'bag',
      'handbag',
      'belt',
      'watch',
      'scarf',
      'jewelry',
      'necklace',
      'bracelet',
      'tie',
    },
  };
  ClothingCategory? category;
  double? confidence;
  for (final label in labels) {
    if (label.confidence < categoryThreshold) continue;
    final normalized = _normalizeLabel(label.text);
    for (final entry in categories.entries) {
      if (_matchesAny(normalized, entry.value) &&
          (confidence == null || label.confidence > confidence)) {
        category = entry.key;
        confidence = label.confidence;
      }
    }
  }

  final styles = <String>{};
  for (final label in labels.where((label) => label.confidence >= .45)) {
    final value = _normalizeLabel(label.text);
    if (_matchesAny(value, const {
      't shirt',
      't-shirt',
      'jeans',
      'denim',
      'hoodie',
      'casual wear',
    })) {
      styles.add('casual');
    }
    if (_matchesAny(value, const {
      'suit',
      'blazer',
      'dress shoe',
      'businesswear',
      'formal wear',
      'tie',
    })) {
      styles.addAll(const ['formal', 'work']);
    }
    if (_matchesAny(value, const {
      'sportswear',
      'sports uniform',
      'sneaker',
      'jersey',
      'athletic shoe',
    })) {
      styles.add('sport');
    }
  }

  var pattern = ClothingPattern.unknown;
  var patternConfidence = 0.0;
  const patterns = <ClothingPattern, Set<String>>{
    ClothingPattern.solid: {'solid', 'plain'},
    ClothingPattern.striped: {'stripe', 'striped'},
    ClothingPattern.checked: {'check', 'checked', 'plaid'},
    ClothingPattern.floral: {'floral', 'flower pattern'},
    ClothingPattern.graphic: {'graphic', 'graphic design', 'printed t shirt'},
    ClothingPattern.textured: {
      'texture',
      'textured',
      'knit',
      'knitted',
      'ribbed',
    },
  };
  for (final label in labels.where((label) => label.confidence >= .6)) {
    final value = _normalizeLabel(label.text);
    for (final entry in patterns.entries) {
      if (_matchesAny(value, entry.value) &&
          label.confidence > patternConfidence) {
        pattern = entry.key;
        patternConfidence = label.confidence;
      }
    }
  }

  var silhouette = ClothingSilhouette.unknown;
  var silhouetteConfidence = 0.0;
  const silhouettes = <ClothingSilhouette, Set<String>>{
    ClothingSilhouette.fitted: {'fitted', 'bodycon'},
    ClothingSilhouette.regular: {'regular fit'},
    ClothingSilhouette.relaxed: {'relaxed fit'},
    ClothingSilhouette.oversized: {'oversized'},
    ClothingSilhouette.cropped: {'cropped'},
    ClothingSilhouette.wideLeg: {'wide leg'},
    ClothingSilhouette.slim: {'slim fit', 'skinny jeans'},
  };
  for (final label in labels.where((label) => label.confidence >= .6)) {
    final value = _normalizeLabel(label.text);
    for (final entry in silhouettes.entries) {
      if (_matchesAny(value, entry.value) &&
          label.confidence > silhouetteConfidence) {
        silhouette = entry.key;
        silhouetteConfidence = label.confidence;
      }
    }
  }

  return ClothingAnalysisResult(
    category: category,
    colorHexes: const [],
    colorNames: const [],
    styles: styles.toList(),
    pattern: pattern,
    silhouette: silhouette,
    confidence: confidence,
    rawLabels: labels.map((label) => label.text).toList(),
    rawPredictions: labels,
  );
}

String _normalizeLabel(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[_/]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _matchesAny(String label, Set<String> terms) => terms.any((term) {
  if (label == term) return true;
  return RegExp('(^|[^a-z])${RegExp.escape(term)}([^a-z]|\$)').hasMatch(label);
});

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
