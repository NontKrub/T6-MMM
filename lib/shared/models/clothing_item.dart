import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ClothingCategory { hat, top, pants, shoes, accessory }

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
        return Icons.safety_divider;
      case ClothingCategory.top:
        return Icons.dry_cleaning;
      case ClothingCategory.pants:
        return Icons.man;
      case ClothingCategory.shoes:
        return Icons.ice_skating;
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
    this.wearCount = 0,
    this.lastWorn,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final colors =
        (json['dominant_colors'] as List?)?.whereType<String>().toList() ??
        const <String>[];
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
      wearCount: json['wear_count'] as int? ?? 0,
      lastWorn: json['last_worn'] != null
          ? DateTime.tryParse(json['last_worn'] as String)
          : null,
    );
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
      'dominant_colors': color == null ? <String>[] : <String>[color!],
      'primary_color': color,
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
      wearCount: wearCount ?? this.wearCount,
      lastWorn: lastWorn ?? this.lastWorn,
    );
  }
}
