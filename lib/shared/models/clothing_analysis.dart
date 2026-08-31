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
    this.tags = const [],
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
  final List<String> tags;
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

  factory ClothingAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawColors = _stringList(json['dominant_colors']);
    final hexes = rawColors.map(_normalizeHex).whereType<String>().toList();
    final colorNames = rawColors
        .where((color) => _normalizeHex(color) == null)
        .toList();
    final primaryColor = _stringValue(json['primary_color']);
    final rawStyles = _stringList(json['styles']);
    return ClothingAnalysisResult(
      category: clothingCategoryFromString(_stringValue(json['category'])),
      subtype: _stringValue(json['subtype']),
      primaryColor: primaryColor,
      colorHexes: hexes,
      colorNames: colorNames.isNotEmpty
          ? colorNames
          : primaryColor == null || _normalizeHex(primaryColor) != null
          ? const []
          : [primaryColor],
      styles: rawStyles,
      clothingStyles: rawStyles
          .map(clothingStyleFromString)
          .where((style) => style != ClothingStyle.unknown)
          .toSet()
          .toList(),
      pattern: clothingPatternFromString(_stringValue(json['pattern'])),
      material: clothingMaterialFromString(_stringValue(json['material'])),
      fit: clothingFitFromString(_stringValue(json['fit'])),
      silhouette: clothingSilhouetteFromString(
        _stringValue(json['silhouette']),
      ),
      formality: clothingFormalityFromString(_stringValue(json['formality'])),
      seasons: _stringList(json['seasons'])
          .map(seasonFromString)
          .where((season) => season != Season.unknown)
          .toSet()
          .toList(),
      weatherSuitability: _stringList(json['weather_suitability'])
          .map(weatherSuitabilityFromString)
          .where((value) => value != WeatherSuitability.unknown)
          .toSet()
          .toList(),
      warmthLevel: _boundedDouble(json['warmth_level']),
      tags: _stringList(json['tags']),
      confidence: _boundedDouble(json['confidence']),
      source: json.containsKey('analysis_source')
          ? analysisSourceFromString(_stringValue(json['analysis_source']))
          : AnalysisSource.serverAI,
      status: json.containsKey('analysis_status')
          ? analysisStatusFromString(_stringValue(json['analysis_status']))
          : AnalysisStatus.complete,
      analysisVersion:
          _stringValue(json['analysis_version']) ?? currentAnalysisVersion,
    );
  }
}

class ClothingAnalysisCorrections {
  const ClothingAnalysisCorrections({
    required this.correctedFields,
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

  final Set<String> correctedFields;
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

  bool contains(String field) => correctedFields.contains(field);

  factory ClothingAnalysisCorrections.fromItem(
    ClothingItem item,
    Set<String> correctedFields,
  ) {
    final fields = correctedFields.intersection(clothingAnalysisFieldNames);
    return ClothingAnalysisCorrections(
      correctedFields: fields,
      category: fields.contains('category') ? item.category : null,
      subtype: fields.contains('subtype') ? item.subtype : null,
      primaryColor: fields.contains('primary_color') ? item.color : null,
      colorHexes: fields.contains('dominant_colors') ? item.colorHexes : null,
      pattern: fields.contains('pattern') ? item.pattern : null,
      material: fields.contains('material') ? item.material : null,
      fit: fields.contains('fit') ? item.fit : null,
      silhouette: fields.contains('silhouette') ? item.silhouette : null,
      clothingStyles: fields.contains('styles') ? item.styles : null,
      formality: fields.contains('formality') ? item.formality : null,
      seasons: fields.contains('seasons') ? item.seasons : null,
      weatherSuitability: fields.contains('weather_suitability')
          ? item.weatherSuitability
          : null,
      warmthLevel: fields.contains('warmth_level') ? item.warmthLevel : null,
      tags: fields.contains('tags') ? item.tags : null,
    );
  }
}

// The analyzer result keeps predictions only for the current run; it is not persisted.
class ImageLabelPrediction {
  const ImageLabelPrediction({required this.text, required this.confidence});

  final String text;
  final double confidence;
}

String? _stringValue(Object? value) => value is String ? value : null;

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().map((entry) => entry.trim()).where((entry) {
    return entry.isNotEmpty;
  }).toList();
}

double? _boundedDouble(Object? value) {
  final number = value is num ? value.toDouble() : null;
  if (number == null || number.isNaN) return null;
  return number.clamp(0, 1).toDouble();
}

String? _normalizeHex(String value) {
  final normalized = value.trim().toUpperCase();
  final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash) ? withHash : null;
}
