import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const currentAnalysisVersion = 'visual-v3';
const _legacyAnalysisVersion = 'legacy';

enum ClothingCategory {
  hat,
  top,
  pants,
  shoes,
  outerwear,
  dress,
  bag,
  accessory,
  unknown,
}

enum ClothingFit { slim, regular, relaxed, oversized, cropped, wide, unknown }

enum ClothingPattern {
  solid,
  striped,
  checked,
  floral,
  graphic,
  textured,
  other,
  unknown,
}

enum ClothingMaterial {
  cotton,
  linen,
  denim,
  wool,
  leather,
  synthetic,
  knit,
  silk,
  other,
  unknown,
}

enum ClothingStyle {
  casual,
  streetwear,
  formal,
  business,
  sport,
  minimal,
  vintage,
  preppy,
  smartCasual,
  unknown,
}

enum ClothingFormality {
  veryCasual,
  casual,
  smartCasual,
  business,
  formal,
  unknown,
}

enum Season { spring, summer, autumn, winter, unknown }

enum WeatherSuitability {
  veryHot,
  hot,
  warm,
  mild,
  cool,
  cold,
  dry,
  rainy,
  unknown,
}

enum AnalysisSource { localVision, serverAI, merged, manual, unknown }

enum AnalysisStatus { pending, analyzing, complete, partial, failed }

enum ClothingSilhouette {
  fitted,
  regular,
  relaxed,
  oversized,
  cropped,
  wideLeg,
  slim,
  aLine,
  straight,
  unknown,
}

String _enumKey(String? value) =>
    (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[_\s-]+'), '');

T _enumValue<T extends Enum>(Iterable<T> values, String? value, T fallback) {
  final key = _enumKey(value);
  return values.firstWhere(
    (entry) => _enumKey(entry.name) == key,
    orElse: () => fallback,
  );
}

ClothingCategory clothingCategoryFromString(String? value) {
  if (_enumKey(value) == 'bottom') return ClothingCategory.pants;
  return _enumValue(ClothingCategory.values, value, ClothingCategory.unknown);
}

ClothingFit clothingFitFromString(String? value) =>
    _enumValue(ClothingFit.values, value, ClothingFit.unknown);

ClothingPattern clothingPatternFromString(String? value) =>
    _enumValue(ClothingPattern.values, value, ClothingPattern.unknown);

ClothingMaterial clothingMaterialFromString(String? value) =>
    _enumValue(ClothingMaterial.values, value, ClothingMaterial.unknown);

ClothingStyle clothingStyleFromString(String? value) =>
    _enumValue(ClothingStyle.values, value, ClothingStyle.unknown);

ClothingFormality clothingFormalityFromString(String? value) =>
    _enumValue(ClothingFormality.values, value, ClothingFormality.unknown);

ClothingSilhouette clothingSilhouetteFromString(String? value) =>
    _enumValue(ClothingSilhouette.values, value, ClothingSilhouette.unknown);

Season seasonFromString(String? value) =>
    _enumValue(Season.values, value, Season.unknown);

WeatherSuitability weatherSuitabilityFromString(String? value) =>
    _enumValue(WeatherSuitability.values, value, WeatherSuitability.unknown);

AnalysisSource analysisSourceFromString(String? value) {
  switch (_enumKey(value)) {
    case 'localvision':
    case 'iosvision':
    case 'androidmlkit':
      return AnalysisSource.localVision;
    case 'serverai':
    case 'server':
      return AnalysisSource.serverAI;
    case 'merged':
      return AnalysisSource.merged;
    case 'manual':
      return AnalysisSource.manual;
    default:
      return AnalysisSource.unknown;
  }
}

AnalysisStatus analysisStatusFromString(String? value) =>
    _enumValue(AnalysisStatus.values, value, AnalysisStatus.pending);

extension ClothingCategoryExt on ClothingCategory {
  String get value => name;

  String get label {
    switch (this) {
      case ClothingCategory.hat:
        return 'Hat';
      case ClothingCategory.top:
        return 'Top';
      case ClothingCategory.pants:
        return 'Pants';
      case ClothingCategory.shoes:
        return 'Shoes';
      case ClothingCategory.outerwear:
        return 'Outerwear';
      case ClothingCategory.dress:
        return 'Dress';
      case ClothingCategory.bag:
        return 'Bag';
      case ClothingCategory.accessory:
        return 'Accessory';
      case ClothingCategory.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case ClothingCategory.hat:
        return Icons.sports_baseball;
      case ClothingCategory.top:
        return Icons.dry_cleaning;
      case ClothingCategory.pants:
        return Icons.straighten;
      case ClothingCategory.shoes:
        return Icons.hiking;
      case ClothingCategory.outerwear:
        return Icons.checkroom;
      case ClothingCategory.dress:
        return Icons.woman;
      case ClothingCategory.bag:
        return Icons.shopping_bag;
      case ClothingCategory.accessory:
        return Icons.watch;
      case ClothingCategory.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case ClothingCategory.hat:
        return AppColors.colorHats;
      case ClothingCategory.top:
        return AppColors.colorTops;
      case ClothingCategory.pants:
        return AppColors.colorPants;
      case ClothingCategory.shoes:
        return AppColors.colorShoes;
      case ClothingCategory.outerwear:
        return AppColors.seedColor;
      case ClothingCategory.dress:
        return AppColors.gradientEnd;
      case ClothingCategory.bag:
        return AppColors.accentGold;
      case ClothingCategory.accessory:
        return AppColors.colorAccessories;
      case ClothingCategory.unknown:
        return AppColors.textSecondaryLight;
    }
  }
}

extension ClothingSilhouetteValue on ClothingSilhouette {
  String get value {
    switch (this) {
      case ClothingSilhouette.wideLeg:
        return 'wide-leg';
      case ClothingSilhouette.aLine:
        return 'a-line';
      default:
        return name;
    }
  }
}

class ClothingItem {
  final String id;
  final String? userId;
  final String name;
  final String? brand;
  final ClothingCategory category;
  final String? subtype;
  final String imageUrl;
  final String? imagePath;
  final List<String> tags;
  final String? color;
  final List<String> colorHexes;
  final ClothingPattern pattern;
  final ClothingMaterial material;
  final ClothingFit fit;
  final ClothingSilhouette silhouette;
  final List<ClothingStyle> styles;
  final ClothingFormality formality;
  final List<Season> seasons;
  final List<WeatherSuitability> weatherSuitability;
  final double? warmthLevel;
  final double? analysisConfidence;
  final String? classificationSource;
  final String? colorSource;
  final AnalysisSource analysisSource;
  final AnalysisStatus analysisStatus;
  final String analysisVersion;
  final bool userCorrected;
  final DateTime? analyzedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int wearCount;
  final DateTime? lastWorn;

  const ClothingItem({
    required this.id,
    this.userId,
    this.name = 'Wardrobe item',
    this.brand,
    required this.category,
    required this.imageUrl,
    this.imagePath,
    this.tags = const [],
    String? color,
    String? primaryColor,
    List<String> colorHexes = const [],
    List<String>? dominantColors,
    this.subtype,
    this.pattern = ClothingPattern.unknown,
    this.material = ClothingMaterial.unknown,
    this.fit = ClothingFit.unknown,
    this.silhouette = ClothingSilhouette.unknown,
    this.styles = const [],
    this.formality = ClothingFormality.unknown,
    this.seasons = const [],
    this.weatherSuitability = const [],
    this.warmthLevel,
    this.analysisConfidence,
    this.classificationSource,
    this.colorSource,
    this.analysisSource = AnalysisSource.unknown,
    this.analysisStatus = AnalysisStatus.pending,
    this.analysisVersion = currentAnalysisVersion,
    this.userCorrected = false,
    this.analyzedAt,
    this.createdAt,
    this.updatedAt,
    this.wearCount = 0,
    this.lastWorn,
  }) : color = color ?? primaryColor,
       colorHexes = dominantColors ?? colorHexes;

  String? get primaryColor => color;

  List<String> get dominantColors => colorHexes;

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final attributes = _mapValue(json['detected_attributes']);
    final rawColors = _stringList(json['dominant_colors']);
    final hexes = rawColors.map(_normalizeHex).whereType<String>().toList();
    final rawStyles = json['styles'] ?? attributes['styles'];
    final rawSeasons = json['seasons'] ?? attributes['seasons'];
    final rawWeather =
        json['weather_suitability'] ?? attributes['weather_suitability'];
    final sourceValue =
        json['analysis_source'] ??
        attributes['analysis_source'] ??
        attributes['classification_source'];
    final confidence = _boundedDouble(
      json['analysis_confidence'] ?? json['ai_confidence'],
    );

    return ClothingItem(
      id: _stringValue(json['id']) ?? '',
      userId: _stringValue(json['user_id']),
      name: _stringValue(json['name']) ?? 'Unnamed item',
      brand: _stringValue(json['brand']),
      category: clothingCategoryFromString(_stringValue(json['category'])),
      subtype:
          _stringValue(json['subtype']) ?? _stringValue(attributes['subtype']),
      imageUrl: _stringValue(json['image_url']) ?? '',
      imagePath: _stringValue(json['image_path']),
      tags: _stringList(json['tags']),
      color:
          _stringValue(json['primary_color']) ??
          (rawColors.isNotEmpty ? rawColors.first : null),
      colorHexes: hexes,
      pattern: clothingPatternFromString(
        _stringValue(json['pattern']) ?? _stringValue(attributes['pattern']),
      ),
      material: clothingMaterialFromString(
        _stringValue(json['material']) ?? _stringValue(attributes['material']),
      ),
      fit: clothingFitFromString(
        _stringValue(json['fit']) ?? _stringValue(attributes['fit']),
      ),
      silhouette: clothingSilhouetteFromString(
        _stringValue(json['silhouette']) ??
            _stringValue(attributes['silhouette']),
      ),
      styles: _enumList(
        rawStyles,
        clothingStyleFromString,
        unknownWhenPresent: rawStyles != null,
      ),
      formality: clothingFormalityFromString(
        _stringValue(json['formality']) ??
            _stringValue(attributes['formality']),
      ),
      seasons: _enumList(
        rawSeasons,
        seasonFromString,
        unknownWhenPresent: rawSeasons != null,
      ),
      weatherSuitability: _enumList(
        rawWeather,
        weatherSuitabilityFromString,
        unknownWhenPresent: rawWeather != null,
      ),
      warmthLevel: _boundedDouble(json['warmth_level']),
      analysisConfidence: confidence,
      classificationSource:
          _stringValue(json['classification_source']) ??
          _stringValue(attributes['classification_source']),
      colorSource:
          _stringValue(json['color_source']) ??
          _stringValue(attributes['color_source']),
      analysisSource: analysisSourceFromString(_stringValue(sourceValue)),
      analysisStatus: analysisStatusFromString(
        _stringValue(json['analysis_status']),
      ),
      analysisVersion:
          _stringValue(json['analysis_version']) ?? _legacyAnalysisVersion,
      userCorrected: json['user_corrected'] == true,
      analyzedAt: _dateValue(json['analyzed_at']),
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
      wearCount: _nonNegativeInt(json['wear_count']),
      lastWorn: _dateValue(json['last_worn']),
    );
  }

  Map<String, dynamic> toJson() => _json();

  Map<String, dynamic> toInsertJson({
    required String userId,
    required String imagePath,
  }) => _json(userId: userId, imagePath: imagePath, includeIdentity: false);

  Map<String, dynamic> _json({
    String? userId,
    String? imagePath,
    bool includeIdentity = true,
  }) {
    final legacyAttributes = <String, dynamic>{
      'pattern': pattern.name,
      'material': material.name,
      'fit': fit.name,
      'silhouette': silhouette.value,
      'styles': styles.map((style) => style.name).toList(),
      'formality': formality.name,
      'seasons': seasons.map((season) => season.name).toList(),
      'weather_suitability': weatherSuitability
          .map((value) => value.name)
          .toList(),
      'subtype': subtype,
      'classification_source': classificationSource,
      'color_source': colorSource,
      'analysis_source': analysisSource.name,
    };
    return {
      if (includeIdentity) 'id': id,
      'user_id': userId ?? this.userId,
      'name': name,
      'brand': brand,
      'category': category.value,
      'image_url': imageUrl,
      'image_path': imagePath ?? this.imagePath,
      'subtype': subtype,
      'tags': tags,
      'primary_color': color,
      'dominant_colors': colorHexes,
      'pattern': pattern.name,
      'material': material.name,
      'fit': fit.name,
      'silhouette': silhouette.value,
      'styles': styles.map((style) => style.name).toList(),
      'formality': formality.name,
      'seasons': seasons.map((season) => season.name).toList(),
      'weather_suitability': weatherSuitability
          .map((value) => value.name)
          .toList(),
      'warmth_level': warmthLevel,
      'analysis_confidence': analysisConfidence,
      'analysis_source': analysisSource.name,
      'analysis_status': analysisStatus.name,
      'analysis_version': analysisVersion,
      'user_corrected': userCorrected,
      'analyzed_at': analyzedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'detected_attributes': legacyAttributes,
      'ai_confidence': analysisConfidence,
      'wear_count': wearCount,
      'last_worn': lastWorn?.toIso8601String(),
    };
  }

  ClothingItem copyWith({
    String? userId,
    String? name,
    String? brand,
    ClothingCategory? category,
    String? subtype,
    String? imageUrl,
    String? imagePath,
    List<String>? tags,
    String? color,
    String? primaryColor,
    List<String>? colorHexes,
    List<String>? dominantColors,
    ClothingPattern? pattern,
    ClothingMaterial? material,
    ClothingFit? fit,
    ClothingSilhouette? silhouette,
    List<ClothingStyle>? styles,
    ClothingFormality? formality,
    List<Season>? seasons,
    List<WeatherSuitability>? weatherSuitability,
    double? warmthLevel,
    double? analysisConfidence,
    String? classificationSource,
    String? colorSource,
    AnalysisSource? analysisSource,
    AnalysisStatus? analysisStatus,
    String? analysisVersion,
    bool? userCorrected,
    DateTime? analyzedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wearCount,
    DateTime? lastWorn,
  }) {
    return ClothingItem(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      color: color ?? primaryColor ?? this.color,
      colorHexes: dominantColors ?? colorHexes ?? this.colorHexes,
      pattern: pattern ?? this.pattern,
      material: material ?? this.material,
      fit: fit ?? this.fit,
      silhouette: silhouette ?? this.silhouette,
      styles: styles ?? this.styles,
      formality: formality ?? this.formality,
      seasons: seasons ?? this.seasons,
      weatherSuitability: weatherSuitability ?? this.weatherSuitability,
      warmthLevel: warmthLevel ?? this.warmthLevel,
      analysisConfidence: analysisConfidence ?? this.analysisConfidence,
      classificationSource: classificationSource ?? this.classificationSource,
      colorSource: colorSource ?? this.colorSource,
      analysisSource: analysisSource ?? this.analysisSource,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      userCorrected: userCorrected ?? this.userCorrected,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wearCount: wearCount ?? this.wearCount,
      lastWorn: lastWorn ?? this.lastWorn,
    );
  }
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String? _stringValue(Object? value) => value is String ? value : null;

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().map((entry) => entry.trim()).where((entry) {
    return entry.isNotEmpty;
  }).toList();
}

List<T> _enumList<T extends Enum>(
  Object? value,
  T Function(String?) parse, {
  required bool unknownWhenPresent,
}) {
  if (value is! List) return const [];
  final parsed = value.whereType<String>().map(parse).toList();
  if (parsed.isNotEmpty) return parsed;
  return unknownWhenPresent ? [parse('unknown')] : const [];
}

String? _normalizeHex(String value) {
  final normalized = value.trim().toUpperCase();
  final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash) ? withHash : null;
}

double? _boundedDouble(Object? value) {
  final number = value is num ? value.toDouble() : null;
  if (number == null || number.isNaN) return null;
  return number.clamp(0, 1).toDouble();
}

int _nonNegativeInt(Object? value) {
  final number = value is num ? value.toInt() : 0;
  return number < 0 ? 0 : number;
}

DateTime? _dateValue(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
