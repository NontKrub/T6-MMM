import 'clothing_item.dart';

enum WeatherCondition { clear, cloudy, rain, snow, storm, unknown }

class WeatherContext {
  const WeatherContext({
    required this.temperatureC,
    this.isRaining = false,
    this.humidity,
    this.condition = WeatherCondition.unknown,
  });

  final double temperatureC;
  final bool isRaining;
  final double? humidity;
  final WeatherCondition condition;

  factory WeatherContext.fromJson(Map<String, dynamic> json) {
    final rawCondition = (json['condition'] as String?)?.toLowerCase();
    final condition = WeatherCondition.values.firstWhere(
      (value) => value.name == rawCondition,
      orElse: () => WeatherCondition.unknown,
    );
    final temperature = json['temperature_c'] ?? json['temperature'];
    return WeatherContext(
      temperatureC: temperature is num ? temperature.toDouble() : 20,
      isRaining: json['is_raining'] == true || json['rain'] == true,
      humidity: (json['humidity'] as num?)?.toDouble(),
      condition: condition,
    );
  }

  bool get raining =>
      isRaining ||
      condition == WeatherCondition.rain ||
      condition == WeatherCondition.storm;
}

class UserStyleProfile {
  const UserStyleProfile({
    this.explicitStyles = const [],
    this.explicitColors = const [],
    this.explicitFits = const [],
    this.explicitFormality,
    this.avoidances = const [],
    this.behavioralWeights = const {},
    this.confidence = 1,
  });

  final List<String> explicitStyles;
  final List<String> explicitColors;
  final List<ClothingFit> explicitFits;
  final ClothingFormality? explicitFormality;
  final List<String> avoidances;
  final Map<String, double> behavioralWeights;
  final double confidence;
}

class WearEvent {
  const WearEvent({
    required this.itemIds,
    required this.wornAt,
    this.id,
    this.outfitId,
    this.source = 'manual',
  });

  final String? id;
  final String? outfitId;
  final List<String> itemIds;
  final DateTime wornAt;
  final String source;
}

class OutfitContext {
  const OutfitContext({
    this.weather,
    this.styleProfile = const UserStyleProfile(),
    this.date,
    this.occasion,
    this.desiredStyle,
    this.personalColor,
    this.luckyColor,
    this.history = const [],
    this.inARush = false,
    this.targetHex,
  });

  final WeatherContext? weather;
  final UserStyleProfile styleProfile;
  final DateTime? date;
  final String? occasion;
  final String? desiredStyle;
  final String? personalColor;
  final String? luckyColor;
  final List<WearEvent> history;
  final bool inARush;
  final String? targetHex;

  OutfitContext copyWith({
    WeatherContext? weather,
    UserStyleProfile? styleProfile,
    DateTime? date,
    String? occasion,
    String? desiredStyle,
    String? personalColor,
    String? luckyColor,
    List<WearEvent>? history,
    bool? inARush,
    String? targetHex,
  }) => OutfitContext(
    weather: weather ?? this.weather,
    styleProfile: styleProfile ?? this.styleProfile,
    date: date ?? this.date,
    occasion: occasion ?? this.occasion,
    desiredStyle: desiredStyle ?? this.desiredStyle,
    personalColor: personalColor ?? this.personalColor,
    luckyColor: luckyColor ?? this.luckyColor,
    history: history ?? this.history,
    inARush: inARush ?? this.inARush,
    targetHex: targetHex ?? this.targetHex,
  );
}

class RecommendationReason {
  const RecommendationReason({required this.code, required this.text});

  final String code;
  final String text;
}

class OutfitCandidate {
  const OutfitCandidate({
    required this.id,
    this.top,
    this.bottom,
    this.shoes,
    this.outerwear,
    this.onePiece,
    this.accessories = const [],
  });

  final String id;
  final ClothingItem? top;
  final ClothingItem? bottom;
  final ClothingItem? shoes;
  final ClothingItem? outerwear;
  final ClothingItem? onePiece;
  final List<ClothingItem> accessories;

  List<ClothingItem> get items => [
    ?onePiece,
    ?top,
    ?bottom,
    ?outerwear,
    ?shoes,
    ...accessories,
  ];

  List<String> get itemIds => items.map((item) => item.id).toList();

  bool get isComplete =>
      shoes != null && (onePiece != null || (top != null && bottom != null));
}

class OutfitScore {
  const OutfitScore({
    required this.total,
    required this.color,
    required this.style,
    required this.weather,
    required this.preference,
    required this.repetition,
    required this.context,
    this.reasons = const [],
  });

  final double total;
  final double color;
  final double style;
  final double weather;
  final double preference;
  final double repetition;
  final double context;
  final List<RecommendationReason> reasons;

  OutfitScore copyWith({List<RecommendationReason>? reasons}) => OutfitScore(
    total: total,
    color: color,
    style: style,
    weather: weather,
    preference: preference,
    repetition: repetition,
    context: context,
    reasons: reasons ?? this.reasons,
  );
}
