import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import 'clothing_analysis_service.dart';

String combinationKey(Iterable<String> itemIds) =>
    (itemIds.toSet().toList()..sort()).join('|');

int repeatCount(Iterable<String> itemIds, Iterable<Iterable<String>> history) {
  final key = combinationKey(itemIds);
  return history.where((entry) => combinationKey(entry) == key).length;
}

class OutfitRecommendationService {
  const OutfitRecommendationService();

  List<Outfit> generate(
    List<ClothingItem> wardrobe, {
    required String style,
    List<List<String>> history = const [],
    bool rush = false,
    String? targetHex,
  }) {
    final tops = _category(wardrobe, ClothingCategory.top);
    final pants = _category(wardrobe, ClothingCategory.pants);
    final shoes = _category(wardrobe, ClothingCategory.shoes);
    if (tops.isEmpty || pants.isEmpty || shoes.isEmpty) {
      throw StateError('Add at least one top, pants, and shoes first.');
    }
    final extras = <ClothingItem?>[
      null,
      ..._category(wardrobe, ClothingCategory.hat),
      ..._category(wardrobe, ClothingCategory.accessory),
    ];
    final candidates = <Outfit>[];
    for (final top in tops) {
      for (final bottom in pants) {
        for (final shoe in shoes) {
          for (final extra in extras) {
            final items = [top, bottom, shoe, ?extra];
            candidates.add(_score(items, style, history, rush, targetHex));
          }
        }
      }
    }
    candidates.sort((a, b) {
      final byScore = (b.score ?? 0).compareTo(a.score ?? 0);
      return byScore != 0
          ? byScore
          : combinationKey(a.itemIds).compareTo(combinationKey(b.itemIds));
    });
    return candidates.take(rush ? 1 : 3).toList();
  }

  double visualScore(List<ClothingItem> items) {
    var score = 0.0;
    final colors = items
        .map((item) => item.colorHexes.firstOrNull)
        .whereType<String>()
        .toList();
    if (colors.length > 1) {
      var total = 0.0;
      var pairs = 0;
      for (var i = 0; i < colors.length; i++) {
        for (var j = i + 1; j < colors.length; j++) {
          total += colorDistance(colors[i], colors[j]);
          pairs++;
        }
      }
      final average = total / pairs;
      if (average <= 80) {
        score += 8;
      } else if (average <= 180) {
        score += 4;
      }
    }
    final loudPatterns = items.where((item) {
      return item.pattern != ClothingPattern.unknown &&
          item.pattern != ClothingPattern.solid;
    }).length;
    if (loudPatterns > 1) score -= 4;

    final silhouettes = items
        .map((item) => item.silhouette)
        .where((value) => value != ClothingSilhouette.unknown)
        .toList();
    if (silhouettes.length > 1 && silhouettes.toSet().length > 1) score += 2;
    return score;
  }

  double targetColorScore(List<ClothingItem> items, String targetHex) {
    final distances = items
        .expand((item) => item.colorHexes)
        .map((hex) => colorDistance(hex, targetHex))
        .toList();
    if (distances.isEmpty) return 0;
    final closest = distances.reduce((a, b) => a < b ? a : b);
    if (closest <= 80) return 8;
    if (closest <= 180) return 4;
    return 0;
  }

  Outfit _score(
    List<ClothingItem> items,
    String style,
    List<List<String>> history,
    bool rush,
    String? targetHex,
  ) {
    var score = 50.0;
    final factors = <String>[];
    if (items.any((item) => item.tags.contains(style))) {
      score += 12;
      factors.add('style_match');
    }
    final visual = visualScore(items);
    score += visual;
    if (visual > 0) factors.add('color_cohesion');
    if (targetHex != null) {
      final targetScore = targetColorScore(items, targetHex);
      score += targetScore;
      if (targetScore > 0) factors.add('target_color');
    }

    final averageWear =
        items.fold<int>(0, (sum, item) => sum + item.wearCount) / items.length;
    score -= averageWear.clamp(0, 10);
    final repeats = repeatCount(items.map((item) => item.id), history);
    score -= repeats * (rush ? 16 : 10);
    if (repeats == 0) factors.add('low_repetition');

    if (rush) {
      final neutralCount = items.where(_isSimple).length;
      score += neutralCount * 4;
      if (neutralCount >= 2) factors.add('simple_colors');
    }
    final ids = items.map((item) => item.id).toList();
    return Outfit(
      id: 'local_${style}_${combinationKey(ids)}',
      name: rush ? 'Rush Outfit' : '${_title(style)} Outfit',
      itemIds: ids,
      style: style,
      reason: factors.isEmpty
          ? 'Balanced from your wardrobe.'
          : factors.map((value) => value.replaceAll('_', ' ')).join(', '),
      score: score.clamp(0, 100),
      selectionFactors: factors,
    );
  }

  List<ClothingItem> _category(
    List<ClothingItem> items,
    ClothingCategory category,
  ) => items.where((item) => item.category == category).toList();

  bool _isSimple(ClothingItem item) {
    const neutralNames = {'black', 'white', 'gray', 'brown', 'beige'};
    final simplePattern =
        item.pattern == ClothingPattern.unknown ||
        item.pattern == ClothingPattern.solid;
    return simplePattern &&
        (neutralNames.contains(item.color) ||
            item.colorHexes.any((hex) {
              final closest = coarseColorName(hex);
              return neutralNames.contains(closest);
            }));
  }

  String _title(String value) => value.isEmpty
      ? 'Everyday'
      : '${value[0].toUpperCase()}${value.substring(1)}';
}
