class Outfit {
  final String id;
  final String name;
  final List<String> itemIds;
  final String? style;
  final DateTime? wornOn;
  final String? reason;
  final double? score;
  final List<String> selectionFactors;

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.style,
    this.wornOn,
    this.reason,
    this.score,
    this.selectionFactors = const [],
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    final rawItemIds = json['item_ids'] ?? json['itemIds'];
    final rawFactors = json['selection_factors'] ?? json['selectionFactors'];
    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Generated outfit',
      itemIds:
          (rawItemIds as List?)?.whereType<String>().toList() ??
          const <String>[],
      style: json['style'] as String?,
      wornOn: json['worn_on'] != null
          ? DateTime.tryParse(json['worn_on'] as String)
          : null,
      reason: json['reason'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      selectionFactors: _parseSelectionFactors(rawFactors),
    );
  }

  static List<String> _parseSelectionFactors(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    if (value is Map) {
      return value.entries
          .where((entry) => entry.value == true || entry.value is num)
          .map((entry) => entry.key)
          .whereType<String>()
          .toList();
    }
    return const [];
  }
}
