import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/outfit_recommendation_service.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
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
      expect(loud, -5);
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

  test(
    'neutral plus accent is positive and extreme clash is small penalty',
    () {
      expect(
        service.visualScore([
          _item('neutral', ClothingCategory.top, hex: '#111111'),
          _item('accent', ClothingCategory.pants, hex: '#3366FF'),
        ]),
        greaterThan(0),
      );
      expect(
        service.visualScore([
          _item('red', ClothingCategory.top, hex: '#FF0000'),
          _item('cyan', ClothingCategory.pants, hex: '#00FFFF'),
        ]),
        lessThanOrEqualTo(0),
      );
    },
  );

  test('uses only obvious silhouette balance rules', () {
    final balanced = service.visualScore([
      _item(
        'top',
        ClothingCategory.top,
        silhouette: ClothingSilhouette.oversized,
      ),
      _item(
        'pants',
        ClothingCategory.pants,
        silhouette: ClothingSilhouette.slim,
      ),
    ]);
    final wide = service.visualScore([
      _item(
        'top',
        ClothingCategory.top,
        silhouette: ClothingSilhouette.oversized,
      ),
      _item(
        'pants',
        ClothingCategory.pants,
        silhouette: ClothingSilhouette.wideLeg,
      ),
    ]);
    expect(balanced, 2);
    expect(wide, -1);
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

  test('learned guest tags and colors modestly improve matching outfits', () {
    final wardrobe = [
      _item(
        'learned-top',
        ClothingCategory.top,
        hex: '#3366FF',
        tags: const ['denim'],
      ),
      _item('other-top', ClothingCategory.top, hex: '#FF0000'),
      _item('pants', ClothingCategory.pants),
      _item('shoes', ClothingCategory.shoes),
    ];
    final events = [
      LocalPreferenceEvent(
        style: 'casual',
        itemIds: const ['old'],
        tags: const ['denim'],
        colors: const ['blue'],
        source: 'generated',
        selectedAt: DateTime.now(),
      ),
    ];

    final result = service.generate(
      wardrobe,
      style: 'casual',
      preferences: events,
    );

    expect(result.first.itemIds, contains('learned-top'));
    expect(result.first.selectionFactors, contains('learned_preference'));
  });

  test('unseen learned metadata remains neutral', () {
    final items = [
      _item('top', ClothingCategory.top),
      _item('pants', ClothingCategory.pants),
      _item('shoes', ClothingCategory.shoes),
    ];
    final baseline = service.generate(items, style: 'casual').single.score;
    final learned = service
        .generate(
          items,
          style: 'casual',
          preferences: [
            LocalPreferenceEvent(
              style: 'formal',
              itemIds: const [],
              tags: const ['wool'],
              colors: const ['purple'],
              source: 'generated',
              selectedAt: DateTime.now(),
            ),
          ],
        )
        .single
        .score;
    expect(learned, baseline);
  });
}

ClothingItem _item(
  String id,
  ClothingCategory category, {
  String? hex,
  ClothingPattern pattern = ClothingPattern.unknown,
  List<String> tags = const [],
  ClothingSilhouette silhouette = ClothingSilhouette.unknown,
}) {
  return ClothingItem(
    id: id,
    name: id,
    category: category,
    imageUrl: '',
    colorHexes: hex == null ? const [] : [hex],
    color: hex == null ? null : coarseColorName(hex),
    pattern: pattern,
    tags: tags,
    silhouette: silhouette,
  );
}
