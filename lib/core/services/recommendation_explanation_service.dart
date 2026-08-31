import '../../shared/models/outfit_intelligence.dart';

class RecommendationExplanationService {
  const RecommendationExplanationService();

  List<RecommendationReason> explain({
    required OutfitCandidate candidate,
    required OutfitScore score,
    required OutfitContext context,
  }) {
    final reasons = <RecommendationReason>[];
    final desiredStyle = context.desiredStyle;
    if (score.style >= 70) {
      reasons.add(
        RecommendationReason(
          code: desiredStyle == null
              ? 'style_compatibility'
              : 'style_preference_match',
          text: desiredStyle == null
              ? 'The pieces share a compatible style.'
              : 'Matches your $desiredStyle style preference.',
        ),
      );
    }
    final weather = context.weather;
    if (weather != null && score.weather >= 70) {
      final band = weather.temperatureC >= 32
          ? 'hot'
          : weather.temperatureC < 12
          ? 'cold'
          : 'mild';
      reasons.add(
        RecommendationReason(
          code: 'weather_${weather.raining ? 'rain' : band}_match',
          text: weather.raining
              ? 'Good choice for rainy weather.'
              : 'Good choice for $band weather.',
        ),
      );
    }
    if (score.color >= 75) {
      final allNeutral = candidate.items.every(
        (item) =>
            item.color == null ||
            const {
              'black',
              'white',
              'gray',
              'grey',
              'brown',
              'beige',
            }.contains(item.color!.toLowerCase()),
      );
      reasons.add(
        RecommendationReason(
          code: allNeutral ? 'color_neutral_balance' : 'color_harmony',
          text: allNeutral
              ? 'Neutral colors pair well together.'
              : 'The colors work well together.',
        ),
      );
    }
    if (score.preference >= 70) {
      reasons.add(
        const RecommendationReason(
          code: 'preference_match',
          text: 'Fits your saved wardrobe preferences.',
        ),
      );
    }
    if (score.repetition >= 75) {
      reasons.add(
        const RecommendationReason(
          code: 'low_recent_repetition',
          text: "You haven't worn this combination recently.",
        ),
      );
    }
    if (context.inARush && candidate.isComplete) {
      reasons.add(
        const RecommendationReason(
          code: 'complete_outfit',
          text: 'A complete outfit ready to wear.',
        ),
      );
    }
    return reasons.take(5).toList();
  }
}
