class Outfit {
  final String id;
  final String name;
  final List<String> itemIds;
  final String? style;
  final DateTime? wornOn;
  final String? reason;
  final double? score;

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.style,
    this.wornOn,
    this.reason,
    this.score,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    final rawItemIds = json['item_ids'] ?? json['itemIds'];
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
    );
  }
}
