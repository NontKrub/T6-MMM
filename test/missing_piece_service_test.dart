import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/missing_piece_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  const service = MissingPieceService();

  test('finds a missing required category', () {
    final result = service.analyze([
      _item('top', ClothingCategory.top),
      _item('pants', ClothingCategory.pants),
    ]);

    expect(result.single.category, ClothingCategory.shoes);
    expect(result.single.priority, MissingPiecePriority.high);
    expect(result.single.reason, MissingPieceReason.missingRequiredCategory);
  });

  test('detects a strongly imbalanced wardrobe', () {
    final result = service.analyze([
      for (var index = 0; index < 18; index++)
        _item('top-$index', ClothingCategory.top),
      _item('pants-a', ClothingCategory.pants),
      _item('pants-b', ClothingCategory.pants),
      _item('shoes', ClothingCategory.shoes),
    ]);

    expect(result.single.category, ClothingCategory.pants);
    expect(result.single.reason, MissingPieceReason.wardrobeImbalance);
  });

  test(
    'reports low compatibility coverage when no complete candidate exists',
    () {
      final result = service.analyze([
        _item('top', ClothingCategory.top),
        _item('pants', ClothingCategory.pants),
        _item('shoes', ClothingCategory.shoes),
      ], candidates: const []);

      expect(result.single.category, ClothingCategory.shoes);
      expect(result.single.reason, MissingPieceReason.lowCompatibilityCoverage);
    },
  );
}

ClothingItem _item(String id, ClothingCategory category) =>
    ClothingItem(id: id, name: id, category: category, imageUrl: '');
