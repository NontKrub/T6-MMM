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

  test('selected top and pants rank suitable neutral shoes first', () {
    final top = _item(
      'top',
      ClothingCategory.top,
      hex: '#3366FF',
      tags: const ['casual'],
    );
    final pants = _item(
      'pants',
      ClothingCategory.pants,
      hex: '#224488',
      tags: const ['casual'],
    );
    final neutral = _item(
      'neutral-shoes',
      ClothingCategory.shoes,
      hex: '#FFFFFF',
      tags: const ['casual'],
    );
    final loud = _item(
      'loud-shoes',
      ClothingCategory.shoes,
      hex: '#FF00FF',
      pattern: ClothingPattern.graphic,
    );

    final result = localMissingPiecesForSelection(
      [top, pants, neutral, loud],
      top: top,
      pants: pants,
    );

    expect(result.single.id, 'local-item-neutral-shoes');
  });

  test('two loud base patterns prefer a solid neutral candidate', () {
    final top = _item(
      'top',
      ClothingCategory.top,
      pattern: ClothingPattern.floral,
    );
    final pants = _item(
      'pants',
      ClothingCategory.pants,
      pattern: ClothingPattern.graphic,
    );
    final neutral = _item(
      'neutral',
      ClothingCategory.shoes,
      hex: '#111111',
      pattern: ClothingPattern.solid,
    );
    final graphic = _item(
      'graphic',
      ClothingCategory.shoes,
      hex: '#FF0000',
      pattern: ClothingPattern.graphic,
    );

    final result = localMissingPiecesForSelection(
      [top, pants, neutral, graphic],
      top: top,
      pants: pants,
    );
    expect(result.single.id, 'local-item-neutral');
  });

  test('selected analysis recommends missing shoes category', () {
    final top = _item('top', ClothingCategory.top);
    final pants = _item('pants', ClothingCategory.pants);
    final result = localMissingPiecesForSelection(
      [top, pants],
      top: top,
      pants: pants,
    );
    expect(result.single.category, 'shoes');
    expect(result.single.title, contains('shoes'));
  });
}

ClothingItem _item(
  String id,
  ClothingCategory category, {
  String? hex,
  List<String> tags = const [],
  ClothingPattern pattern = ClothingPattern.unknown,
}) => ClothingItem(
  id: id,
  name: id,
  category: category,
  imageUrl: '',
  colorHexes: hex == null ? const [] : [hex],
  tags: tags,
  pattern: pattern,
);
