import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/outfit_intelligence.dart';
import 'clothing_analysis_service.dart';
import 'local_account_repository.dart';
import 'outfit_candidate_generator.dart';
import 'outfit_scoring_service.dart';

String combinationKey(Iterable<String> itemIds) =>
    (itemIds.toSet().toList()..sort()).join('|');

int repeatCount(Iterable<String> itemIds, Iterable<Iterable<String>> history) {
  final key = combinationKey(itemIds);
  return history.where((entry) => combinationKey(entry) == key).length;
}

class OutfitRecommendationService {
  const OutfitRecommendationService({
    this.candidateGenerator = const OutfitCandidateGenerator(),
    this.scoringService = const OutfitScoringService(),
  });

  final OutfitCandidateGenerator candidateGenerator;
  final OutfitScoringService scoringService;

  List<Outfit> generate(
    List<ClothingItem> wardrobe, {
    required String style,
    List<List<String>> history = const [],
    bool rush = false,
    String? targetHex,
    List<LocalPreferenceEvent> preferences = const [],
    OutfitContext? context,
  }) {
    final effectiveContext =
        context ??
        _legacyContext(
          style: style,
          history: history,
          rush: rush,
          targetHex: targetHex,
          preferences: preferences,
        );
    final ranked =
        generateCandidates(wardrobe, context: effectiveContext)
            .map(
              (candidate) => (
                candidate: candidate,
                score: scoreCandidate(candidate, context: effectiveContext),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byScore = b.score.total.compareTo(a.score.total);
            return byScore != 0
                ? byScore
                : a.candidate.id.compareTo(b.candidate.id);
          });
    return ranked.take(rush ? 1 : 3).map((entry) {
      final factors = entry.score.reasons.map((reason) => reason.code).toList();
      if (effectiveContext.styleProfile.behavioralWeights.isNotEmpty &&
          entry.score.preference > 50) {
        factors.add('learned_preference');
      }
      if (rush && entry.candidate.items.where(_isSimple).length >= 2) {
        factors.add('simple_colors');
      }
      final itemIds = entry.candidate.itemIds;
      return Outfit(
        id: 'local_${style}_${combinationKey(itemIds)}',
        name: rush ? 'Rush Outfit' : '${_title(style)} Outfit',
        itemIds: itemIds,
        style: style,
        reason: entry.score.reasons.isEmpty
            ? 'Balanced from your wardrobe.'
            : entry.score.reasons.map((reason) => reason.text).join(' '),
        score: entry.score.total,
        selectionFactors: factors.toSet().toList(),
      );
    }).toList();
  }

  List<OutfitCandidate> generateCandidates(
    List<ClothingItem> wardrobe, {
    OutfitContext? context,
  }) => candidateGenerator.generate(wardrobe, context: context);

  OutfitScore scoreCandidate(
    OutfitCandidate candidate, {
    OutfitContext context = const OutfitContext(),
  }) => scoringService.score(candidate, context: context);

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

  OutfitContext _legacyContext({
    required String style,
    required List<List<String>> history,
    required bool rush,
    required String? targetHex,
    required List<LocalPreferenceEvent> preferences,
  }) {
    final now = DateTime.now();
    final wearHistory = history.indexed
        .map(
          (entry) => WearEvent(
            itemIds: entry.$2,
            wornAt: now.subtract(Duration(days: history.length - entry.$1)),
          ),
        )
        .toList();
    final behavioral = <String, double>{};
    for (final event in preferences) {
      for (final value in [...event.tags, ...event.colors]) {
        behavioral[value.toLowerCase()] = 1;
      }
    }
    return OutfitContext(
      desiredStyle: style,
      styleProfile: UserStyleProfile(
        explicitStyles: [style],
        behavioralWeights: behavioral,
      ),
      history: wearHistory,
      inARush: rush,
      targetHex: targetHex,
    );
  }

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
