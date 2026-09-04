import '../../shared/models/outfit_intelligence.dart';
import '../../shared/models/recommendation_event.dart';

class RecommendationFeedbackService {
  const RecommendationFeedbackService();

  double weightFor(RecommendationEventType eventType) => switch (eventType) {
    RecommendationEventType.accepted => .03,
    RecommendationEventType.liked => .05,
    RecommendationEventType.worn => .06,
    RecommendationEventType.skipped => -.01,
    RecommendationEventType.disliked => -.05,
    _ => 0,
  };

  Map<String, double> apply(
    Map<String, double> current,
    RecommendationEvent event,
  ) {
    final delta = weightFor(event.eventType);
    if (delta == 0) return Map<String, double>.from(current);
    final next = Map<String, double>.from(current);
    for (final token in _tokens(event.metadata)) {
      next[token] = ((next[token] ?? .5) + delta).clamp(0, 1).toDouble();
    }
    return next;
  }

  UserStyleProfile applyToProfile(
    UserStyleProfile profile,
    RecommendationEvent event,
  ) => UserStyleProfile(
    explicitStyles: profile.explicitStyles,
    explicitColors: profile.explicitColors,
    explicitFits: profile.explicitFits,
    explicitFormality: profile.explicitFormality,
    avoidances: profile.avoidances,
    confidence: profile.confidence,
    behavioralWeights: apply(profile.behavioralWeights, event),
  );

  Set<String> _tokens(Map<String, dynamic> metadata) {
    final tokens = <String>{};
    for (final key in const ['styles', 'tags', 'colors', 'fits', 'formality']) {
      final value = metadata[key];
      final values = value is List
          ? value.whereType<String>()
          : const <String>[];
      for (final entry in values) {
        final normalized = entry.trim().toLowerCase();
        if (normalized.isNotEmpty) tokens.add('$key:$normalized');
      }
    }
    return tokens;
  }
}
