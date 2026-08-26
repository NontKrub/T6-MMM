import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import 'clothing_analysis_service.dart';
import 'local_account_repository.dart';

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
    List<LocalPreferenceEvent> preferences = const [],
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
            candidates.add(
              _score(items, style, history, rush, targetHex, preferences),
            );
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
    final palettes = items.map(_representativePalette).toList();
    for (var i = 0; i < palettes.length; i++) {
      for (var j = i + 1; j < palettes.length; j++) {
        final pair = _closestColorPair(palettes[i], palettes[j]);
        if (pair == null) continue;
        final firstNeutral = _isNeutralHex(pair.$1);
        final secondNeutral = _isNeutralHex(pair.$2);
        if (firstNeutral && secondNeutral) {
          score += 3;
        } else if (firstNeutral != secondNeutral) {
          score += 2;
        } else if (pair.$3 <= 80) {
          score += 2;
        } else if (pair.$3 >= 300) {
          score -= 1;
        }
      }
    }
    final loudPatterns = items.where((item) {
      return item.pattern != ClothingPattern.unknown &&
          item.pattern != ClothingPattern.solid;
    }).length;
    if (loudPatterns > 1) {
      score -= 5;
    } else if (loudPatterns == 1 &&
        items.any((item) => item.pattern == ClothingPattern.solid)) {
      score += 1;
    }

    final top = items
        .where((item) => item.category == ClothingCategory.top)
        .firstOrNull;
    final pants = items
        .where((item) => item.category == ClothingCategory.pants)
        .firstOrNull;
    if (top != null && pants != null) {
      if ((top.silhouette == ClothingSilhouette.oversized &&
              pants.silhouette == ClothingSilhouette.slim) ||
          (top.silhouette == ClothingSilhouette.fitted &&
              pants.silhouette == ClothingSilhouette.wideLeg)) {
        score += 2;
      } else if (top.silhouette == ClothingSilhouette.oversized &&
          pants.silhouette == ClothingSilhouette.wideLeg) {
        score -= 1;
      }
    }
    return score;
  }

  double targetColorScore(List<ClothingItem> items, String targetHex) {
    final distances = items
        .expand(_representativePalette)
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
    List<LocalPreferenceEvent> preferences,
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
    final learned = _learnedPreferenceScore(items, style, preferences);
    score += learned;
    if (learned > 0) factors.add('learned_preference');

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

  double _learnedPreferenceScore(
    List<ClothingItem> items,
    String style,
    List<LocalPreferenceEvent> events,
  ) {
    if (events.isEmpty) return 0;
    final tags = items
        .expand((item) => item.tags)
        .map((tag) => tag.toLowerCase())
        .toSet();
    final colors = items
        .expand(
          (item) => [
            if (item.color != null) item.color!.toLowerCase(),
            ...item.colorHexes.map(coarseColorName),
          ],
        )
        .toSet();
    var tagWeight = 0.0;
    var colorWeight = 0.0;
    var styleWeight = 0.0;
    final now = DateTime.now();
    for (final event in events) {
      final recency = now.difference(event.selectedAt).inDays <= 90 ? 1.0 : .5;
      if (event.tags.any((tag) => tags.contains(tag.toLowerCase()))) {
        tagWeight += recency;
      }
      if (event.colors.any((color) => colors.contains(color.toLowerCase()))) {
        colorWeight += recency;
      }
      if (event.style?.toLowerCase() == style.toLowerCase()) {
        styleWeight += recency;
      }
    }
    return (tagWeight * 3).clamp(0, 6) +
        (colorWeight * 2).clamp(0, 2) +
        styleWeight.clamp(0, 2);
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

  bool _isNeutralHex(String hex) => const {
    'black',
    'white',
    'gray',
    'brown',
    'beige',
  }.contains(coarseColorName(hex));

  String _title(String value) => value.isEmpty
      ? 'Everyday'
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

List<String> _representativePalette(ClothingItem item) =>
    item.colorHexes.map(normalizeHexColor).whereType<String>().take(3).toList();

(String, String, double)? _closestColorPair(
  List<String> first,
  List<String> second,
) {
  (String, String, double)? closest;
  for (final a in first) {
    for (final b in second) {
      final distance = colorDistance(a, b);
      if (closest == null || distance < closest.$3) {
        closest = (a, b, distance);
      }
    }
  }
  return closest;
}
