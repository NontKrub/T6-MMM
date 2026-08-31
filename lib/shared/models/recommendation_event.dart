enum RecommendationEventType {
  generated,
  shown,
  accepted,
  skipped,
  regenerated,
  liked,
  disliked,
  worn,
  unknown,
}

RecommendationEventType recommendationEventTypeFromString(String? value) {
  return RecommendationEventType.values.firstWhere(
    (event) => event.name == value,
    orElse: () => RecommendationEventType.unknown,
  );
}

class RecommendationEvent {
  const RecommendationEvent({
    required this.eventType,
    required this.createdAt,
    this.id,
    this.userId,
    this.outfitId,
    this.itemIds = const [],
    this.metadata = const {},
  });

  final String? id;
  final String? userId;
  final String? outfitId;
  final RecommendationEventType eventType;
  final List<String> itemIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory RecommendationEvent.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return RecommendationEvent(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      outfitId: json['outfit_id'] as String?,
      eventType: recommendationEventTypeFromString(
        json['event_type'] as String?,
      ),
      itemIds: (json['clothing_item_ids'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (outfitId != null) 'outfit_id': outfitId,
    'event_type': eventType.name,
    'clothing_item_ids': itemIds,
    'metadata': metadata,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  RecommendationEvent copyWith({
    RecommendationEventType? eventType,
    List<String>? itemIds,
    Map<String, dynamic>? metadata,
  }) => RecommendationEvent(
    id: id,
    userId: userId,
    outfitId: outfitId,
    eventType: eventType ?? this.eventType,
    itemIds: itemIds ?? this.itemIds,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt,
  );
}
