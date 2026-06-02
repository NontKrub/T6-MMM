import '../../shared/models/outfit.dart';
import 'recommendation_repository.dart';
import 'supabase_service.dart';
import 'weather_context_repository.dart';

class OutfitRepository {
  final RecommendationRepository _recommendations;
  final WeatherContextRepository _weatherContext;

  OutfitRepository({
    RecommendationRepository? recommendations,
    WeatherContextRepository? weatherContext,
  }) : _recommendations = recommendations ?? RecommendationRepository(),
       _weatherContext = weatherContext ?? WeatherContextRepository();

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
  }) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Sign in to generate AI outfits.');
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
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['outfits'] as List? ?? const [])
        .map((row) => Outfit.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
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
    if (client == null || user == null) return;

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
  }

  Future<Outfit?> rushOutfit({String style = 'rush'}) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Sign in to use rush outfit.');
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
}
