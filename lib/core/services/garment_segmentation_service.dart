import 'package:flutter/services.dart';

class GarmentSegmentationResult {
  final int width;
  final int height;
  final Uint8List alpha;
  final double confidence;
  final List<double> boundingBox;

  const GarmentSegmentationResult({
    required this.width,
    required this.height,
    required this.alpha,
    this.confidence = 0,
    this.boundingBox = const [0, 0, 1, 1],
  });

  bool get isUsable =>
      width > 0 && height > 0 && alpha.length >= width * height;
}

class GarmentSegmentationService {
  GarmentSegmentationService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('mmm/clothing_analysis');

  final MethodChannel _channel;

  Future<GarmentSegmentationResult?> segment(Uint8List bytes) async {
    if (bytes.isEmpty) return null;
    try {
      final raw = await _channel.invokeMethod<Object?>('segmentForeground', {
        'bytes': bytes,
      });
      if (raw is! Map) return null;
      final width = (raw['width'] as num?)?.toInt() ?? 0;
      final height = (raw['height'] as num?)?.toInt() ?? 0;
      final mask = _bytes(raw['mask'] ?? raw['alpha']);
      if (mask == null || width <= 0 || height <= 0) return null;
      final box = raw['boundingBox'];
      final boundingBox = box is List && box.length >= 4
          ? box
                .take(4)
                .whereType<num>()
                .map((value) => value.toDouble())
                .toList()
          : const [0.0, 0.0, 1.0, 1.0];
      return GarmentSegmentationResult(
        width: width,
        height: height,
        alpha: mask,
        confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
        boundingBox: boundingBox.length == 4
            ? boundingBox
            : const [0.0, 0.0, 1.0, 1.0],
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Uint8List? _bytes(Object? value) {
    if (value is Uint8List) return value;
    if (value is List) {
      final values = value.whereType<num>().map((entry) => entry.toInt());
      return Uint8List.fromList(values.toList());
    }
    return null;
  }
}
