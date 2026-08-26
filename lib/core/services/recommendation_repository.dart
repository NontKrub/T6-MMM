import '../../shared/models/clothing_item.dart';
import 'clothing_analysis_service.dart';
import 'local_account_repository.dart';
import 'supabase_service.dart';

class RepetitionInsight {
  final bool alert;
  final String? dominantColor;
  final int dominantColorCount;
  final String? dominantStyle;
  final int dominantStyleCount;

  const RepetitionInsight({
    required this.alert,
    this.dominantColor,
    required this.dominantColorCount,
    this.dominantStyle,
    required this.dominantStyleCount,
  });

  factory RepetitionInsight.fromJson(Map<String, dynamic> json) {
    return RepetitionInsight(
      alert: json['alert'] == true,
      dominantColor: json['dominant_color'] as String?,
      dominantColorCount: json['dominant_color_count'] as int? ?? 0,
      dominantStyle: json['dominant_style'] as String?,
      dominantStyleCount: json['dominant_style_count'] as int? ?? 0,
    );
  }
}

class MissingPieceRecommendation {
  final String id;
  final String category;
  final String title;
  final String reason;
  final String suggestion;
  final String priority;

  const MissingPieceRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.reason,
    required this.suggestion,
    required this.priority,
  });

  factory MissingPieceRecommendation.fromJson(Map<String, dynamic> json) {
    return MissingPieceRecommendation(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'accessory',
      title: json['title'] as String? ?? 'Wardrobe piece',
      reason: json['reason'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      priority: json['priority'] as String? ?? 'nice_to_have',
    );
  }
}

class RecommendationRepository {
  final _local = LocalAccountRepository();

  Future<List<MissingPieceRecommendation>> generateMissingPieces({
    ClothingItem? top,
    ClothingItem? pants,
  }) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      final items = await _local.fetchItems();
      return top != null && pants != null
          ? localMissingPiecesForSelection(items, top: top, pants: pants)
          : localMissingPieces(items);
    }

    final response = await client.functions.invoke(
      'missing-pieces',
      body: {
        if (top != null && pants != null)
          'selected_item_ids': [top.id, pants.id],
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['recommendations'] as List? ?? const [])
        .map(
          (row) => MissingPieceRecommendation.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> dismissMissingPiece(String recommendationId) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return;

    await client.functions.invoke(
      'missing-pieces',
      body: {'action': 'dismiss', 'id': recommendationId},
    );
  }

  Future<RepetitionInsight?> repetitionInsights() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return null;
    final response = await client.functions.invoke(
      'repetition-insights',
      body: const {},
    );
    return RepetitionInsight.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<String>> dailyLuckyColors({
    String method = 'birth_profile',
  }) async {
    if (method == 'random_daily') {
      return _randomDailyLuckyColors(DateTime.now());
    }

    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return const [];
    final response = await client.functions.invoke(
      'daily-lucky-colors',
      body: const {},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['colors'] as List? ?? const []).whereType<String>().toList();
  }

  List<String> _randomDailyLuckyColors(DateTime date) {
    const palettes = [
      ['white', 'silver', 'sky blue'],
      ['yellow', 'cream', 'gold'],
      ['pink', 'coral', 'rose'],
      ['green', 'olive', 'mint'],
      ['orange', 'tan', 'brown'],
      ['blue', 'navy', 'teal'],
      ['purple', 'black', 'charcoal'],
    ];
    final daySeed = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(2024)).inDays;
    return palettes[daySeed % palettes.length];
  }
}

List<MissingPieceRecommendation> localMissingPiecesForSelection(
  List<ClothingItem> items, {
  required ClothingItem top,
  required ClothingItem pants,
}) {
  final shoes = items
      .where((item) => item.category == ClothingCategory.shoes)
      .toList();
  if (shoes.isEmpty) {
    return const [
      MissingPieceRecommendation(
        id: 'local-selection-shoes',
        category: 'shoes',
        title: 'Add neutral shoes',
        reason:
            'Your selected top and pants need shoes to complete the outfit.',
        suggestion: 'Try white, black, gray, beige, or brown footwear.',
        priority: 'essential',
      ),
    ];
  }

  final base = [top, pants];
  final loudBase = base.where(_isLoudPattern).length;
  final candidates =
      items
          .where(
            (item) =>
                item.category == ClothingCategory.shoes ||
                item.category == ClothingCategory.accessory,
          )
          .map(
            (item) =>
                (item: item, score: _missingPieceScore(item, base, loudBase)),
          )
          .toList()
        ..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          return byScore != 0 ? byScore : a.item.id.compareTo(b.item.id);
        });
  if (candidates.isEmpty) return localMissingPieces(items);
  final best = candidates.first.item;
  final neutral = best.colorHexes.any(_isNeutralHex);
  return [
    MissingPieceRecommendation(
      id: 'local-item-${best.id}',
      category: best.category.name,
      title: 'Try ${best.name}',
      reason: loudBase > 1
          ? 'A simple piece balances the selected patterns.'
          : 'Its colors and style fit the selected top and pants.',
      suggestion: neutral
          ? 'This neutral piece keeps the outfit balanced.'
          : 'Use this piece as the outfit accent.',
      priority: 'recommended',
    ),
  ];
}

double _missingPieceScore(
  ClothingItem candidate,
  List<ClothingItem> base,
  int loudBase,
) {
  var score = candidate.category == ClothingCategory.shoes ? 3.0 : 0.0;
  final candidateHex = candidate.colorHexes.firstOrNull;
  if (candidateHex != null) {
    if (_isNeutralHex(candidateHex)) score += 3;
    if (base
        .expand((item) => item.colorHexes)
        .any((hex) => colorDistance(hex, candidateHex) <= 180)) {
      score += 2;
    }
  }
  final baseTags = base.expand((item) => item.tags).toSet();
  score += candidate.tags.where(baseTags.contains).length * 2;
  if (loudBase > 1) {
    score += _isLoudPattern(candidate) ? -5 : 4;
  }
  score -= candidate.wearCount.clamp(0, 5);
  return score;
}

bool _isLoudPattern(ClothingItem item) =>
    item.pattern != ClothingPattern.unknown &&
    item.pattern != ClothingPattern.solid;

bool _isNeutralHex(String hex) => const {
  'black',
  'white',
  'gray',
  'brown',
  'beige',
}.contains(coarseColorName(hex));

List<MissingPieceRecommendation> localMissingPieces(List<ClothingItem> items) {
  const required = [
    ClothingCategory.top,
    ClothingCategory.pants,
    ClothingCategory.shoes,
  ];
  final gaps = required.where(
    (category) => !items.any((item) => item.category == category),
  );
  final recommendations = gaps
      .map(
        (category) => MissingPieceRecommendation(
          id: 'local-${category.name}',
          category: category.name,
          title: 'Add ${category.label.toLowerCase()}',
          reason: 'Your wardrobe needs this category for complete outfits.',
          suggestion: 'Choose a versatile neutral piece you will wear often.',
          priority: 'essential',
        ),
      )
      .toList();
  if (recommendations.isNotEmpty) return recommendations;
  if (!items.any((item) => item.category == ClothingCategory.accessory)) {
    return const [
      MissingPieceRecommendation(
        id: 'local-accessory',
        category: 'accessory',
        title: 'Add a versatile accessory',
        reason: 'Your base wardrobe is complete but has no finishing piece.',
        suggestion: 'Try a neutral belt, bag, watch, or scarf.',
        priority: 'nice_to_have',
      ),
    ];
  }
  return const [];
}
