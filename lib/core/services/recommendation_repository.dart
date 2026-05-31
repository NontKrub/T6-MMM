import 'supabase_service.dart';

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
  Future<List<MissingPieceRecommendation>> generateMissingPieces() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return const [];

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

  Future<Map<String, dynamic>?> repetitionInsights() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return null;
    final response = await client.functions.invoke(
      'repetition-insights',
      body: const {},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<String>> dailyLuckyColors() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return const [];
    final response = await client.functions.invoke(
      'daily-lucky-colors',
      body: const {},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['colors'] as List? ?? const []).whereType<String>().toList();
  }
}
