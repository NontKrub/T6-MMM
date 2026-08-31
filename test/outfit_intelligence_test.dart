import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/color_compatibility_service.dart';
import 'package:mix_match_mood/core/services/outfit_candidate_generator.dart';
import 'package:mix_match_mood/core/services/outfit_scoring_service.dart';
import 'package:mix_match_mood/core/services/style_compatibility_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/outfit_intelligence.dart';

void main() {
  const generator = OutfitCandidateGenerator();

  test(
    'candidate generation returns valid structures and no exception for gaps',
    () {
      expect(generator.generate(const []), isEmpty);
      expect(
        generator.generate([
          _item('top', ClothingCategory.top),
          _item('bottom', ClothingCategory.pants),
        ]),
        isEmpty,
      );

      final candidates = generator.generate([
        _item('top', ClothingCategory.top),
        _item('bottom', ClothingCategory.pants),
        _item('shoes', ClothingCategory.shoes),
        _item('dress', ClothingCategory.dress),
        _item('jacket', ClothingCategory.outerwear),
      ]);

      expect(candidates, isNotEmpty);
      expect(candidates.every((candidate) => candidate.isComplete), isTrue);
      expect(
        candidates.every(
          (candidate) => candidate.onePiece == null
              ? candidate.top != null && candidate.bottom != null
              : candidate.top == null && candidate.bottom == null,
        ),
        isTrue,
      );
    },
  );

  test(
    'color compatibility handles neutral, analogous, and contrast pairs',
    () {
      const service = ColorCompatibilityService();

      expect(service.compatibility('#111111', '#FFFFFF'), greaterThan(80));
      expect(service.compatibility('#3366FF', '#4477EE'), greaterThan(70));
      expect(service.compatibility('#FF0000', '#00FFFF'), greaterThan(55));
      expect(
        service.compatibility('#111111', '#FFFFFF'),
        greaterThan(service.compatibility('#FF00FF', '#FF7F00')),
      );
    },
  );

  test('style compatibility recognizes useful mixed-style pairs', () {
    const service = StyleCompatibilityService();
    final casualStreetwear = [
      _item('tee', ClothingCategory.top, styles: [ClothingStyle.streetwear]),
      _item('jeans', ClothingCategory.pants, styles: [ClothingStyle.casual]),
    ];
    final formalStreetwear = [
      _item('blazer', ClothingCategory.top, styles: [ClothingStyle.formal]),
      _item(
        'jeans',
        ClothingCategory.pants,
        styles: [ClothingStyle.streetwear],
      ),
    ];

    expect(
      service.score(casualStreetwear, desiredStyle: 'streetwear'),
      greaterThan(service.score(formalStreetwear, desiredStyle: 'streetwear')),
    );
  });

  test('scoring weights weather, preferences, repetition, and reasons', () {
    const scoring = OutfitScoringService();
    final good = OutfitCandidate(
      id: 'good',
      top: _item(
        'tee',
        ClothingCategory.top,
        color: 'black',
        hex: '#111111',
        warmth: .2,
        styles: [ClothingStyle.streetwear, ClothingStyle.casual],
      ),
      bottom: _item(
        'jeans',
        ClothingCategory.pants,
        color: 'blue',
        hex: '#3366FF',
        warmth: .35,
        styles: [ClothingStyle.casual],
      ),
      shoes: _item(
        'sneakers',
        ClothingCategory.shoes,
        color: 'white',
        hex: '#FFFFFF',
        warmth: .2,
        styles: [ClothingStyle.casual],
      ),
    );
    final heavy = OutfitCandidate(
      id: 'heavy',
      top: _item(
        'sweater',
        ClothingCategory.top,
        color: 'red',
        hex: '#FF0000',
        warmth: .9,
        styles: [ClothingStyle.formal],
      ),
      bottom: _item(
        'trousers',
        ClothingCategory.pants,
        color: 'green',
        hex: '#00FF00',
        warmth: .5,
        styles: [ClothingStyle.formal],
      ),
      shoes: _item(
        'loafers',
        ClothingCategory.shoes,
        color: 'green',
        hex: '#00FF00',
        warmth: .2,
        styles: [ClothingStyle.formal],
      ),
    );
    const context = OutfitContext(
      weather: WeatherContext(temperatureC: 33),
      desiredStyle: 'streetwear',
      styleProfile: UserStyleProfile(
        explicitStyles: ['streetwear'],
        explicitColors: ['black', 'white', 'blue'],
        explicitFits: [ClothingFit.oversized],
      ),
    );

    final goodScore = scoring.score(good, context: context);
    final heavyScore = scoring.score(heavy, context: context);

    expect(goodScore.total, inInclusiveRange(0, 100));
    expect(goodScore.weather, greaterThan(heavyScore.weather));
    expect(goodScore.style, greaterThan(heavyScore.style));
    expect(goodScore.total, greaterThan(heavyScore.total));
    expect(
      goodScore.reasons.map((reason) => reason.code),
      containsAll(['style_preference_match', 'weather_hot_match']),
    );
  });

  test('recent exact outfits are penalized but not banned', () {
    const scoring = OutfitScoringService();
    final candidate = OutfitCandidate(
      id: 'same',
      top: _item('top', ClothingCategory.top, hex: '#111111'),
      bottom: _item('bottom', ClothingCategory.pants, hex: '#FFFFFF'),
      shoes: _item('shoes', ClothingCategory.shoes, hex: '#FFFFFF'),
    );
    final now = DateTime.utc(2026, 8, 31);
    final fresh = scoring.score(candidate, context: OutfitContext(date: now));
    final repeated = scoring.score(
      candidate,
      context: OutfitContext(
        date: now,
        history: [
          WearEvent(
            itemIds: candidate.itemIds,
            wornAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );

    expect(repeated.total, lessThan(fresh.total));
    expect(repeated.total, greaterThan(0));
  });

  test('identical inputs produce identical candidate and score ordering', () {
    final wardrobe = [
      _item('top-b', ClothingCategory.top),
      _item('top-a', ClothingCategory.top),
      _item('bottom', ClothingCategory.pants),
      _item('shoes', ClothingCategory.shoes),
    ];
    final first = generator.generate(wardrobe);
    final second = generator.generate(wardrobe);
    const scoring = OutfitScoringService();
    final firstScores = first
        .map((candidate) => scoring.score(candidate).total)
        .toList();
    final secondScores = second
        .map((candidate) => scoring.score(candidate).total)
        .toList();

    expect(
      first.map((candidate) => candidate.id).toList(),
      second.map((candidate) => candidate.id).toList(),
    );
    expect(firstScores, secondScores);
  });

  test('core scenario ranks a casual hot-weather outfit first', () {
    final wardrobe = [
      _item(
        'black-tee',
        ClothingCategory.top,
        color: 'black',
        hex: '#111111',
        warmth: .2,
        styles: [ClothingStyle.casual, ClothingStyle.streetwear],
      ),
      _item(
        'blue-jeans',
        ClothingCategory.pants,
        color: 'blue',
        hex: '#3366FF',
        warmth: .35,
        styles: [ClothingStyle.casual, ClothingStyle.streetwear],
      ),
      _item(
        'white-sneakers',
        ClothingCategory.shoes,
        color: 'white',
        hex: '#FFFFFF',
        warmth: .2,
        styles: [ClothingStyle.casual, ClothingStyle.streetwear],
      ),
      _item(
        'formal-shirt',
        ClothingCategory.top,
        color: 'white',
        hex: '#FFFFFF',
        warmth: .4,
        styles: [ClothingStyle.formal],
      ),
      _item(
        'black-blazer',
        ClothingCategory.outerwear,
        color: 'black',
        hex: '#111111',
        warmth: .95,
        styles: [ClothingStyle.formal, ClothingStyle.business],
      ),
      _item(
        'formal-trousers',
        ClothingCategory.pants,
        color: 'black',
        hex: '#111111',
        warmth: .55,
        styles: [ClothingStyle.formal, ClothingStyle.business],
      ),
      _item(
        'formal-shoes',
        ClothingCategory.shoes,
        color: 'black',
        hex: '#111111',
        warmth: .2,
        styles: [ClothingStyle.formal, ClothingStyle.business],
      ),
    ];
    const context = OutfitContext(
      weather: WeatherContext(temperatureC: 32),
      desiredStyle: 'streetwear',
      styleProfile: UserStyleProfile(
        explicitStyles: ['casual', 'streetwear'],
        explicitColors: ['black', 'white', 'blue'],
      ),
    );
    const scoring = OutfitScoringService();
    final ranked =
        generator
            .generate(wardrobe, context: context)
            .map(
              (candidate) => (
                candidate: candidate,
                score: scoring.score(candidate, context: context),
              ),
            )
            .toList()
          ..sort((a, b) => b.score.total.compareTo(a.score.total));

    final best = ranked.first;
    expect(best.candidate.itemIds, containsAll(['black-tee', 'blue-jeans']));
    expect(best.candidate.itemIds, contains('white-sneakers'));
    expect(best.score.reasons, isNotEmpty);
    final formal = ranked.firstWhere(
      (entry) => entry.candidate.itemIds.toSet().containsAll([
        'formal-shirt',
        'black-blazer',
        'formal-trousers',
        'formal-shoes',
      ]),
    );
    expect(best.score.total, greaterThan(formal.score.total));
  });
}

ClothingItem _item(
  String id,
  ClothingCategory category, {
  String? color,
  String? hex,
  double? warmth,
  List<ClothingStyle> styles = const [],
}) => ClothingItem(
  id: id,
  name: id,
  category: category,
  imageUrl: '',
  color: color,
  colorHexes: hex == null ? const [] : [hex],
  warmthLevel: warmth,
  styles: styles,
);
