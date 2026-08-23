import '../../shared/models/clothing_item.dart';
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

  Future<List<MissingPieceRecommendation>> generateMissingPieces() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      return localMissingPieces(await _local.fetchItems());
    }

    final response = await client.functions.invoke(
      'missing-pieces',
      body: const {},
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
