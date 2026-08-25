import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test('old persisted clothing items load with safe visual defaults', () {
    final item = ClothingItem.fromJson({
      'id': 'old',
      'name': 'Old item',
      'category': 'top',
      'image_url': '/managed/old.jpg',
    });

    expect(item.colorHexes, isEmpty);
    expect(item.pattern, ClothingPattern.unknown);
    expect(item.silhouette, ClothingSilhouette.unknown);
    expect(item.analysisConfidence, isNull);
    expect(item.classificationSource, isNull);
    expect(item.colorSource, isNull);
  });

  test('visual metadata survives JSON round trip', () {
    const item = ClothingItem(
      id: 'new',
      name: 'Blue jeans',
      category: ClothingCategory.pants,
      imageUrl: '/managed/new.jpg',
      color: 'blue',
      colorHexes: ['#3366FF'],
      pattern: ClothingPattern.solid,
      silhouette: ClothingSilhouette.slim,
      analysisConfidence: 0.9,
      classificationSource: 'ios_vision',
      colorSource: 'pixel_palette',
    );

    final restored = ClothingItem.fromJson(item.toJson());

    expect(restored.colorHexes, ['#3366FF']);
    expect(restored.pattern, ClothingPattern.solid);
    expect(restored.silhouette, ClothingSilhouette.slim);
    expect(restored.analysisConfidence, 0.9);
    expect(restored.classificationSource, 'ios_vision');
    expect(restored.colorSource, 'pixel_palette');
  });
}
