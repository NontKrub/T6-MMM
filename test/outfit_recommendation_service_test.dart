import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/outfit_recommendation_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  const service = OutfitRecommendationService();

  test('combination keys and repeat counts are order independent', () {
    expect(combinationKey(['top', 'pants']), combinationKey(['pants', 'top']));
    expect(
      repeatCount(
        ['pants', 'top'],
        [
          ['top', 'pants'],
          ['other'],
          ['pants', 'top'],
        ],
      ),
      2,
    );
  });

  test('close HEX colors score above distant colors', () {
    final close = service.visualScore([
      _item('a', ClothingCategory.top, hex: '#112233'),
      _item('b', ClothingCategory.pants, hex: '#182A3A'),
    ]);
    final distant = service.visualScore([
      _item('a', ClothingCategory.top, hex: '#FF0000'),
      _item('b', ClothingCategory.pants, hex: '#00FFFF'),
    ]);

    expect(close, greaterThan(distant));
  });

  test(
    'unknown metadata is neutral and loud pattern pairs get small penalty',
    () {
      final unknown = service.visualScore([
        _item('a', ClothingCategory.top),
        _item('b', ClothingCategory.pants),
      ]);
      final loud = service.visualScore([
        _item('a', ClothingCategory.top, pattern: ClothingPattern.floral),
        _item('b', ClothingCategory.pants, pattern: ClothingPattern.graphic),
      ]);

      expect(unknown, 0);
      expect(loud, -4);
    },
  );

  test('custom HEX gives moderate bonus to close colors', () {
    expect(
      service.targetColorScore([
        _item('blue', ClothingCategory.top, hex: '#3366FF'),
      ], '#3360F0'),
      8,
    );
    expect(
      service.targetColorScore([
        _item('unknown', ClothingCategory.top),
      ], '#3366FF'),
      0,
    );
  });

  test('rush mode prefers neutral simple pieces and avoids repeats', () {
    final wardrobe = [
      _item('neutral-top', ClothingCategory.top, hex: '#111111'),
      _item(
        'loud-top',
        ClothingCategory.top,
        hex: '#FF00FF',
        pattern: ClothingPattern.graphic,
      ),
      _item('pants', ClothingCategory.pants, hex: '#222222'),
      _item('shoes', ClothingCategory.shoes, hex: '#333333'),
    ];

    final result = service.generate(
      wardrobe,
      style: 'rush',
      history: [
        ['loud-top', 'pants', 'shoes'],
      ],
      rush: true,
    );

    expect(result.first.itemIds, contains('neutral-top'));
    expect(result.first.selectionFactors, contains('simple_colors'));
  });
}

ClothingItem _item(
  String id,
  ClothingCategory category, {
  String? hex,
  ClothingPattern pattern = ClothingPattern.unknown,
}) {
  return ClothingItem(
    id: id,
    name: id,
    category: category,
    imageUrl: '',
    colorHexes: hex == null ? const [] : [hex],
    pattern: pattern,
  );
}
