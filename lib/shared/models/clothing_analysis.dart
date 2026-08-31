import 'clothing_item.dart';

class ClothingAnalysisResult {
  const ClothingAnalysisResult({
    this.category,
    this.subtype,
    required this.colorHexes,
    required this.colorNames,
    this.primaryColor,
    this.styles = const [],
    this.clothingStyles = const [],
    this.pattern = ClothingPattern.unknown,
    this.material = ClothingMaterial.unknown,
    this.fit = ClothingFit.unknown,
    this.silhouette = ClothingSilhouette.unknown,
    this.formality = ClothingFormality.unknown,
    this.seasons = const [],
    this.weatherSuitability = const [],
    this.warmthLevel,
    this.confidence,
    this.rawLabels = const [],
    this.rawPredictions = const [],
    this.classificationSource,
    this.colorSource,
    this.source = AnalysisSource.unknown,
    this.status = AnalysisStatus.complete,
    this.analysisVersion = currentAnalysisVersion,
  });

  final ClothingCategory? category;
  final String? subtype;
  final String? primaryColor;
  final List<String> colorHexes;
  final List<String> colorNames;

  // `styles` remains string-based for compatibility with the existing picker UI.
  final List<String> styles;
  final List<ClothingStyle> clothingStyles;
  final ClothingPattern pattern;
  final ClothingMaterial material;
  final ClothingFit fit;
  final ClothingSilhouette silhouette;
  final ClothingFormality formality;
  final List<Season> seasons;
  final List<WeatherSuitability> weatherSuitability;
  final double? warmthLevel;
  final double? confidence;
  final List<String> rawLabels;
  final List<ImageLabelPrediction> rawPredictions;
  final String? classificationSource;
  final String? colorSource;
  final AnalysisSource source;
  final AnalysisStatus status;
  final String analysisVersion;

  List<String> get dominantColors => colorHexes;

  List<ClothingStyle> get resolvedStyles {
    final values = <ClothingStyle>[
      ...clothingStyles,
      ...styles.map(clothingStyleFromString),
    ];
    return values.toSet().toList();
  }
}

class ClothingAnalysisCorrections {
  const ClothingAnalysisCorrections({
    this.category,
    this.subtype,
    this.primaryColor,
    this.colorHexes,
    this.pattern,
    this.material,
    this.fit,
    this.silhouette,
    this.clothingStyles,
    this.formality,
    this.seasons,
    this.weatherSuitability,
    this.warmthLevel,
    this.tags,
  });

  final ClothingCategory? category;
  final String? subtype;
  final String? primaryColor;
  final List<String>? colorHexes;
  final ClothingPattern? pattern;
  final ClothingMaterial? material;
  final ClothingFit? fit;
  final ClothingSilhouette? silhouette;
  final List<ClothingStyle>? clothingStyles;
  final ClothingFormality? formality;
  final List<Season>? seasons;
  final List<WeatherSuitability>? weatherSuitability;
  final double? warmthLevel;
  final List<String>? tags;

  factory ClothingAnalysisCorrections.fromItem(
    ClothingItem item,
  ) => ClothingAnalysisCorrections(
    category: item.category == ClothingCategory.unknown ? null : item.category,
    subtype: item.subtype,
    primaryColor: item.color,
    colorHexes: item.colorHexes.isEmpty ? null : item.colorHexes,
    pattern: item.pattern == ClothingPattern.unknown ? null : item.pattern,
    material: item.material == ClothingMaterial.unknown ? null : item.material,
    fit: item.fit == ClothingFit.unknown ? null : item.fit,
    silhouette: item.silhouette == ClothingSilhouette.unknown
        ? null
        : item.silhouette,
    clothingStyles: item.styles.isEmpty ? null : item.styles,
    formality: item.formality == ClothingFormality.unknown
        ? null
        : item.formality,
    seasons: item.seasons.isEmpty ? null : item.seasons,
    weatherSuitability: item.weatherSuitability.isEmpty
        ? null
        : item.weatherSuitability,
    warmthLevel: item.warmthLevel,
    tags: item.tags.isEmpty ? null : item.tags,
  );
}

// The analyzer result keeps predictions only for the current run; it is not persisted.
class ImageLabelPrediction {
  const ImageLabelPrediction({required this.text, required this.confidence});

  final String text;
  final double confidence;
}
