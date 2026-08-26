import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ClothingCategory { hat, top, pants, shoes, accessory }

enum ClothingPattern {
  solid,
  striped,
  checked,
  floral,
  graphic,
  textured,
  unknown,
}

enum ClothingSilhouette {
  fitted,
  regular,
  relaxed,
  oversized,
  cropped,
  wideLeg,
  slim,
  unknown,
}

extension ClothingSilhouetteValue on ClothingSilhouette {
  String get value => this == ClothingSilhouette.wideLeg ? 'wide-leg' : name;
}

ClothingPattern clothingPatternFromString(String? value) =>
    ClothingPattern.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => ClothingPattern.unknown,
    );

ClothingSilhouette clothingSilhouetteFromString(String? value) =>
    ClothingSilhouette.values.firstWhere(
      (entry) => entry.value == value,
      orElse: () => ClothingSilhouette.unknown,
    );

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
      case ClothingCategory.accessory:
        return 'Accessory';
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
      case ClothingCategory.accessory:
        return Icons.watch;
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
      case ClothingCategory.accessory:
        return AppColors.colorAccessories;
    }
  }
}

ClothingCategory clothingCategoryFromString(String value) {
  return ClothingCategory.values.firstWhere(
    (category) => category.name == value,
    orElse: () => ClothingCategory.accessory,
  );
}

class ClothingItem {
  final String id;
  final String name;
  final String? brand;
  final ClothingCategory category;
  final String imageUrl;
  final List<String> tags;
  final String? color;
  final List<String> colorHexes;
  final ClothingPattern pattern;
  final ClothingSilhouette silhouette;
  final double? analysisConfidence;
  final String? classificationSource;
  final String? colorSource;
  final int wearCount;
  final DateTime? lastWorn;

  const ClothingItem({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.imageUrl,
    this.tags = const [],
    this.color,
    this.colorHexes = const [],
    this.pattern = ClothingPattern.unknown,
    this.silhouette = ClothingSilhouette.unknown,
    this.analysisConfidence,
    this.classificationSource,
    this.colorSource,
    this.wearCount = 0,
    this.lastWorn,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final colors =
        (json['dominant_colors'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    final attributes = json['detected_attributes'] is Map
        ? Map<String, dynamic>.from(json['detected_attributes'] as Map)
        : const <String, dynamic>{};
    final hexes = colors
        .map((color) => color.trim().toUpperCase())
        .where((color) => RegExp(r'^#[0-9A-F]{6}$').hasMatch(color))
        .toList();
    return ClothingItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed item',
      brand: json['brand'] as String?,
      category: clothingCategoryFromString(
        json['category'] as String? ?? 'accessory',
      ),
      imageUrl: json['image_url'] as String? ?? '',
      tags:
          (json['tags'] as List?)?.whereType<String>().toList() ??
          const <String>[],
      color:
          json['primary_color'] as String? ??
          (colors.isNotEmpty ? colors.first : null),
      colorHexes: hexes,
      pattern: clothingPatternFromString(attributes['pattern'] as String?),
      silhouette: clothingSilhouetteFromString(
        attributes['silhouette'] as String?,
      ),
      analysisConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      classificationSource: attributes['classification_source'] as String?,
      colorSource: attributes['color_source'] as String?,
      wearCount: json['wear_count'] as int? ?? 0,
      lastWorn: json['last_worn'] != null
          ? DateTime.tryParse(json['last_worn'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category.value,
      'image_url': imageUrl,
      'tags': tags,
      'primary_color': color,
      'dominant_colors': colorHexes,
      'detected_attributes': {
        'pattern': pattern.name,
        'silhouette': silhouette.value,
        'classification_source': classificationSource,
        'color_source': colorSource,
      },
      'ai_confidence': analysisConfidence,
      'wear_count': wearCount,
      'last_worn': lastWorn?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson({
    required String userId,
    required String imagePath,
  }) {
    return {
      'user_id': userId,
      'name': name,
      'brand': brand,
      'category': category.value,
      'image_path': imagePath,
      'image_url': imageUrl,
      'tags': tags,
      'dominant_colors': colorHexes,
      'primary_color': color,
      'detected_attributes': {
        'pattern': pattern.name,
        'silhouette': silhouette.value,
        'classification_source': classificationSource,
        'color_source': colorSource,
      },
      'ai_confidence': analysisConfidence,
      'wear_count': wearCount,
      'last_worn': lastWorn?.toIso8601String(),
    };
  }

  ClothingItem copyWith({
    String? name,
    String? brand,
    ClothingCategory? category,
    String? imageUrl,
    List<String>? tags,
    String? color,
    List<String>? colorHexes,
    ClothingPattern? pattern,
    ClothingSilhouette? silhouette,
    double? analysisConfidence,
    String? classificationSource,
    String? colorSource,
    int? wearCount,
    DateTime? lastWorn,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      colorHexes: colorHexes ?? this.colorHexes,
      pattern: pattern ?? this.pattern,
      silhouette: silhouette ?? this.silhouette,
      analysisConfidence: analysisConfidence ?? this.analysisConfidence,
      classificationSource: classificationSource ?? this.classificationSource,
      colorSource: colorSource ?? this.colorSource,
      wearCount: wearCount ?? this.wearCount,
      lastWorn: lastWorn ?? this.lastWorn,
    );
  }
}
