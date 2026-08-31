import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/core/services/recommendation_feedback_service.dart';
import 'package:mix_match_mood/shared/models/recommendation_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('feedback changes behavioral weights gradually and clamps them', () {
    const service = RecommendationFeedbackService();
    final event = RecommendationEvent(
      eventType: RecommendationEventType.accepted,
      createdAt: DateTime.utc(2026, 8, 31),
      metadata: const {
        'styles': ['streetwear'],
        'colors': ['black'],
      },
    );

    final accepted = service.apply(const {}, event);
    expect(accepted['styles:streetwear'], .53);
    expect(accepted['colors:black'], .53);

    final disliked = service.apply({
      'styles:streetwear': .53,
    }, event.copyWith(eventType: RecommendationEventType.disliked));
    expect(disliked['styles:streetwear'], closeTo(.48, .000001));
    expect(
      service.apply(
        {'styles:streetwear': .01},
        event.copyWith(eventType: RecommendationEventType.disliked),
      )['styles:streetwear'],
      0,
    );
  });

  test(
    'guest recommendation events and wear events persist independently',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalAccountRepository();
      final createdAt = DateTime.utc(2026, 8, 31);

      await repository.recordRecommendationEvent(
        RecommendationEvent(
          eventType: RecommendationEventType.liked,
          itemIds: const ['top', 'pants', 'shoes'],
          metadata: const {
            'styles': ['casual'],
            'tags': ['denim'],
          },
          createdAt: createdAt,
        ),
      );

      final events = await repository.fetchRecommendationEvents();
      expect(events.single.eventType, RecommendationEventType.liked);
      expect((await repository.fetchBehavioralWeights())['styles:casual'], .55);
      expect(await repository.fetchWearEvents(), isEmpty);
    },
  );

  test('recommendation event copyWith changes only the event type', () {
    final event = RecommendationEvent(
      eventType: RecommendationEventType.shown,
      createdAt: DateTime.utc(2026, 8, 31),
    );
    expect(
      event.copyWith(eventType: RecommendationEventType.skipped).eventType,
      RecommendationEventType.skipped,
    );
  });
}
