enum GarmentTextureKind {
  solid,
  repeatingPattern,
  frontGraphic,
  photoApproximation,
}

class GarmentVisualFingerprint {
  final GarmentTextureKind kind;
  final String? primaryColorHex;
  final List<String> secondaryColorHexes;
  final double confidence;
  final String? sourceDigest;
  final bool usedSegmentation;
  final String? fallbackReason;
  final List<double>? frontGraphicRect;

  const GarmentVisualFingerprint({
    required this.kind,
    this.primaryColorHex,
    this.secondaryColorHexes = const [],
    this.confidence = 0,
    this.sourceDigest,
    this.usedSegmentation = false,
    this.fallbackReason,
    this.frontGraphicRect,
  });

  GarmentTextureKind get textureKind => kind;

  String get stableKey => [
    kind.name,
    primaryColorHex ?? '',
    ...secondaryColorHexes,
    sourceDigest ?? '',
    frontGraphicRect?.join(',') ?? '',
  ].join('|');

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'primaryColorHex': primaryColorHex,
    'secondaryColorHexes': secondaryColorHexes,
    'confidence': confidence,
    'sourceDigest': sourceDigest,
    'usedSegmentation': usedSegmentation,
    'fallbackReason': fallbackReason,
    'frontGraphicRect': frontGraphicRect,
  };

  factory GarmentVisualFingerprint.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String?;
    final kind = GarmentTextureKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => GarmentTextureKind.photoApproximation,
    );
    final secondary = json['secondaryColorHexes'];
    final rect = json['frontGraphicRect'];
    return GarmentVisualFingerprint(
      kind: kind,
      primaryColorHex: json['primaryColorHex'] as String?,
      secondaryColorHexes: secondary is List
          ? secondary.whereType<String>().toList(growable: false)
          : const [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      sourceDigest: json['sourceDigest'] as String?,
      usedSegmentation: json['usedSegmentation'] as bool? ?? false,
      fallbackReason: json['fallbackReason'] as String?,
      frontGraphicRect: rect is List
          ? rect.whereType<num>().map((value) => value.toDouble()).toList()
          : null,
    );
  }
}
