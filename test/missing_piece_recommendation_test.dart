import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/recommendation_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test('local gap analysis recommends missing required categories', () {
    final recommendations = localMissingPieces([
      const ClothingItem(
        id: 'top',
        name: 'Top',
        category: ClothingCategory.top,
        imageUrl: '',
      ),
    ]);

    expect(
      recommendations.map((entry) => entry.category),
      containsAll(['pants', 'shoes']),
    );
  });

  test(
    'local gap analysis suggests accessory after base wardrobe is complete',
    () {
      final recommendations = localMissingPieces([
        _item('top', ClothingCategory.top),
        _item('pants', ClothingCategory.pants),
        _item('shoes', ClothingCategory.shoes),
      ]);

      expect(recommendations.single.category, 'accessory');
    },
  );
}

ClothingItem _item(String id, ClothingCategory category) =>
    ClothingItem(id: id, name: id, category: category, imageUrl: '');
