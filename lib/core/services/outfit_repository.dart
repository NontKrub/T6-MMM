import '../../shared/models/outfit.dart';
import '../../shared/models/outfit_intelligence.dart';
import '../../shared/models/recommendation_event.dart';
import 'local_account_repository.dart';
import 'outfit_recommendation_service.dart';
import 'recommendation_repository.dart';
import 'supabase_service.dart';
import 'weather_context_repository.dart';

class OutfitRepository {
  final RecommendationRepository _recommendations;
  final WeatherContextRepository _weatherContext;
  final LocalAccountRepository _local;
  final OutfitRecommendationService _localRecommendations;

  OutfitRepository({
    RecommendationRepository? recommendations,
    WeatherContextRepository? weatherContext,
    LocalAccountRepository? local,
    OutfitRecommendationService? localRecommendations,
  }) : _recommendations = recommendations ?? RecommendationRepository(),
       _weatherContext = weatherContext ?? WeatherContextRepository(),
       _local = local ?? LocalAccountRepository(),
       _localRecommendations =
           localRecommendations ?? const OutfitRecommendationService();

  Future<List<Outfit>> fetchOutfits() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return const [];

    final rows = await client
        .from('outfits')
        .select('*, outfit_items(clothing_item_id, position)')
        .order('created_at', ascending: false);

    return rows.map<Outfit>((row) {
      final data = Map<String, dynamic>.from(row);
      final joinRows =
          (data['outfit_items'] as List? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList()
            ..sort(
              (a, b) => (a['position'] as int? ?? 0).compareTo(
                b['position'] as int? ?? 0,
              ),
            );
      data['item_ids'] = joinRows
          .map((entry) => entry['clothing_item_id'] as String)
          .toList();
      return Outfit.fromJson(data);
    }).toList();
  }

  Future<List<Outfit>> generateOutfits({
    required String style,
    bool usePersonalColor = false,
    bool useLuckyColor = false,
    bool matchWeather = false,
    bool learnPreferences = true,
    String luckyColorMethod = 'birth_profile',
    String weatherLocationMode = 'auto_detect',
    String? targetHex,
  }) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      final items = await _local.fetchItems();
      final history = await _local.fetchWearEvents();
      final behavioralWeights = await _local.fetchBehavioralWeights();
      final generated = _localRecommendations.generate(
        items,
        style: style,
        history: await _local.fetchWearCombinations(),
        targetHex: targetHex,
        context: OutfitContext(
          desiredStyle: style,
          targetHex: targetHex,
          history: history,
          styleProfile: UserStyleProfile(
            explicitStyles: [style],
            behavioralWeights: behavioralWeights,
          ),
        ),
      );
      await _recordRecommendationEvents(generated);
      return generated;
    }

    final shouldMatchWeather =
        matchWeather && weatherLocationMode == 'auto_detect';
    final weather = shouldMatchWeather
        ? await _weatherContext.currentFromDeviceLocation()
        : null;
    final luckyColors = useLuckyColor
        ? await _recommendations.dailyLuckyColors(method: luckyColorMethod)
        : const <String>[];

    final response = await client.functions.invoke(
      'generate-outfits',
      body: {
        'style': style,
        'use_personal_color': usePersonalColor,
        'use_lucky_color': useLuckyColor,
        'match_weather': shouldMatchWeather,
        'weather': weather,
        'lucky_colors': luckyColors,
        'learn_preferences': learnPreferences,
        'lucky_color_method': luckyColorMethod,
        'weather_location_mode': weatherLocationMode,
        'target_hex': targetHex,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final generated = (data['outfits'] as List? ?? const [])
        .map((row) => Outfit.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    await _recordRecommendationEvents(generated);
    return generated;
  }

  Future<void> recordPreferenceEvent({
    required Outfit outfit,
    required List<String> itemIds,
    required List<String> tags,
    required List<String> colors,
    required String source,
  }) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _local.recordPreferenceEvent(
        LocalPreferenceEvent(
          style: outfit.style,
          itemIds: itemIds,
          tags: tags,
          colors: colors,
          source: source,
          selectedAt: DateTime.now(),
        ),
      );
      await recordRecommendationEvent(
        RecommendationEvent(
          eventType: RecommendationEventType.accepted,
          outfitId: outfit.id,
          itemIds: itemIds,
          metadata: _feedbackMetadata(
            outfit: outfit,
            tags: tags,
            colors: colors,
          ),
          createdAt: DateTime.now(),
        ),
      );
      await recordRecommendationEvent(
        RecommendationEvent(
          eventType: RecommendationEventType.worn,
          outfitId: outfit.id,
          itemIds: itemIds,
          metadata: _feedbackMetadata(
            outfit: outfit,
            tags: tags,
            colors: colors,
          ),
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    await client.from('outfit_preference_events').insert({
      'user_id': user.id,
      'outfit_id': outfit.id,
      'style': outfit.style,
      'clothing_item_ids': itemIds,
      'tags': tags,
      'colors': colors,
      'selection_factors': outfit.selectionFactors,
      'score': outfit.score,
      'source': source,
    });
    await recordRecommendationEvent(
      RecommendationEvent(
        eventType: RecommendationEventType.accepted,
        outfitId: outfit.id,
        itemIds: itemIds,
        metadata: _feedbackMetadata(outfit: outfit, tags: tags, colors: colors),
        createdAt: DateTime.now(),
      ),
    );
    await recordRecommendationEvent(
      RecommendationEvent(
        eventType: RecommendationEventType.worn,
        outfitId: outfit.id,
        itemIds: itemIds,
        metadata: _feedbackMetadata(outfit: outfit, tags: tags, colors: colors),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> recordRecommendationEvent(RecommendationEvent event) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _local.recordRecommendationEvent(event);
      return;
    }
    await client.from('recommendation_events').insert({
      'user_id': user.id,
      'outfit_id': event.outfitId,
      'event_type': event.eventType.name,
      'clothing_item_ids': event.itemIds,
      'metadata': event.metadata,
    });
  }

  Future<Outfit?> rushOutfit({String style = 'rush'}) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      final outfits = _localRecommendations.generate(
        await _local.fetchItems(),
        style: style,
        history: await _local.fetchWearCombinations(),
        rush: true,
        preferences: await _local.fetchPreferenceEvents(),
      );
      return outfits.firstOrNull;
    }

    final response = await client.functions.invoke(
      'rush-outfit',
      body: {'style': style},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final outfit = data['outfit'];
    if (outfit is! Map) return null;
    return Outfit.fromJson(Map<String, dynamic>.from(outfit));
  }

  Future<int> repeatCountFor(List<String> itemIds) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      return repeatCount(itemIds, await _local.fetchWearCombinations());
    }
    final rows = await client.from('wear_events').select('clothing_item_ids');
    final history = rows
        .map<List<String>>(
          (row) => (row['clothing_item_ids'] as List? ?? const [])
              .whereType<String>()
              .toList(),
        )
        .toList();
    return repeatCount(itemIds, history);
  }

  Map<String, dynamic> _feedbackMetadata({
    required Outfit outfit,
    required List<String> tags,
    required List<String> colors,
  }) => {
    'styles': outfit.style == null ? const [] : [outfit.style!],
    'tags': tags,
    'colors': colors,
    'selection_factors': outfit.selectionFactors,
  };

  Future<void> _recordRecommendationEvents(List<Outfit> outfits) async {
    for (final outfit in outfits) {
      for (final eventType in [
        RecommendationEventType.generated,
        RecommendationEventType.shown,
      ]) {
        try {
          await recordRecommendationEvent(
            RecommendationEvent(
              eventType: eventType,
              outfitId: outfit.id,
              itemIds: outfit.itemIds,
              metadata: {
                'styles': outfit.style == null ? const [] : [outfit.style!],
                'selection_factors': outfit.selectionFactors,
              },
              createdAt: DateTime.now(),
            ),
          );
        } catch (_) {
          // Recommendation telemetry must not block a usable outfit response.
        }
      }
    }
  }
}
