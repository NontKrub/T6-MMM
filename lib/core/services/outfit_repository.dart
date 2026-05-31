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
  }) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Sign in to generate AI outfits.');
    }

    final weather = matchWeather
        ? await _weatherContext.currentFromDeviceLocation()
        : null;
    final luckyColors = useLuckyColor
        ? await _recommendations.dailyLuckyColors()
        : const <String>[];

    final response = await client.functions.invoke(
      'generate-outfits',
      body: {
        'style': style,
        'use_personal_color': usePersonalColor,
        'use_lucky_color': useLuckyColor,
        'match_weather': matchWeather,
        'weather': weather,
        'lucky_colors': luckyColors,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['outfits'] as List? ?? const [])
        .map((row) => Outfit.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
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
