enum ColorSeason { spring, summer, autumn, winter }

enum AvatarType { human, dog, cat }

enum AvatarBodyShape { male, female }

AvatarBodyShape avatarBodyShapeFromString(String value) {
  return AvatarBodyShape.values.firstWhere(
    (s) => s.name == value.toLowerCase(),
    orElse: () => AvatarBodyShape.female,
  );
}

ColorSeason colorSeasonFromString(String value) {
  return ColorSeason.values.firstWhere(
    (season) => season.name == value.toLowerCase(),
    orElse: () => ColorSeason.spring,
  );
}

AvatarType avatarTypeFromString(String value) {
  return AvatarType.values.firstWhere(
    (type) => type.name == value.toLowerCase(),
    orElse: () => AvatarType.human,
  );
}

extension ColorSeasonExt on ColorSeason {
  String get label {
    switch (this) {
      case ColorSeason.spring:
        return 'Spring';
      case ColorSeason.summer:
        return 'Summer';
      case ColorSeason.autumn:
        return 'Autumn';
      case ColorSeason.winter:
        return 'Winter';
    }
  }

  String get description {
    switch (this) {
      case ColorSeason.spring:
        return 'Warm, bright, coral & peach tones';
      case ColorSeason.summer:
        return 'Cool, muted, lavender & soft blue';
      case ColorSeason.autumn:
        return 'Warm, earthy, rust & olive tones';
      case ColorSeason.winter:
        return 'Cool, bright, jewel & icy tones';
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final ColorSeason colorSeason;
  final AvatarType avatarType;
  final List<String> stylePreferences;
  final List<String> occasions;
  final bool onboardingComplete;
  final String? bodyType;
  final double brandTier;
  final DateTime? birthDate;
  final int? birthWeekday;
  final AvatarBodyShape bodyShape;
  final int skinToneIndex;
  final int hairColorIndex;
  final int hairStyleIndex;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.colorSeason = ColorSeason.spring,
    this.avatarType = AvatarType.human,
    this.stylePreferences = const [],
    this.occasions = const [],
    this.onboardingComplete = false,
    this.bodyType,
    this.brandTier = 0.3,
    this.birthDate,
    this.birthWeekday,
    this.bodyShape = AvatarBodyShape.female,
    this.skinToneIndex = 1,
    this.hairColorIndex = 1,
    this.hairStyleIndex = 3,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    List<String> styles = const [],
    List<String> occasions = const [],
  }) {
    return UserProfile(
      id: json['id'] as String,
      name: json['display_name'] as String? ?? 'MMM User',
      avatarUrl: json['avatar_url'] as String?,
      colorSeason: colorSeasonFromString(
        json['color_season'] as String? ?? 'spring',
      ),
      avatarType: avatarTypeFromString(
        json['avatar_type'] as String? ?? 'human',
      ),
      stylePreferences: styles,
      occasions: occasions,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      bodyType: json['body_type'] as String?,
      brandTier: (json['brand_tier'] as num?)?.toDouble() ?? 0.3,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      birthWeekday: json['birth_weekday'] as int?,
      bodyShape: avatarBodyShapeFromString(
        json['body_shape'] as String? ?? 'female',
      ),
      skinToneIndex: (json['skin_tone_index'] as int?) ?? 1,
      hairColorIndex: (json['hair_color_index'] as int?) ?? 1,
      hairStyleIndex: (json['hair_style_index'] as int?) ?? 3,
    );
  }

  Map<String, dynamic> toProfileJson() {
    final derivedBirthWeekday = birthDate == null
        ? null
        : (birthWeekday ?? birthDate!.weekday);

    return {
      'id': id,
      'display_name': name,
      'avatar_url': avatarUrl,
      'color_season': colorSeason.name,
      'avatar_type': avatarType.name,
      'onboarding_complete': onboardingComplete,
      'body_type': bodyType,
      'brand_tier': brandTier,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'birth_weekday': derivedBirthWeekday,
      'body_shape': bodyShape.name,
      'skin_tone_index': skinToneIndex,
      'hair_color_index': hairColorIndex,
      'hair_style_index': hairStyleIndex,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      ...toProfileJson(),
      'style_preferences': stylePreferences,
      'occasions': occasions,
    };
  }

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    ColorSeason? colorSeason,
    AvatarType? avatarType,
    List<String>? stylePreferences,
    List<String>? occasions,
    bool? onboardingComplete,
    String? bodyType,
    double? brandTier,
    DateTime? birthDate,
    int? birthWeekday,
    AvatarBodyShape? bodyShape,
    int? skinToneIndex,
    int? hairColorIndex,
    int? hairStyleIndex,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      colorSeason: colorSeason ?? this.colorSeason,
      avatarType: avatarType ?? this.avatarType,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      occasions: occasions ?? this.occasions,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      bodyType: bodyType ?? this.bodyType,
      brandTier: brandTier ?? this.brandTier,
      birthDate: birthDate ?? this.birthDate,
      birthWeekday: birthWeekday ?? this.birthWeekday,
      bodyShape: bodyShape ?? this.bodyShape,
      skinToneIndex: skinToneIndex ?? this.skinToneIndex,
      hairColorIndex: hairColorIndex ?? this.hairColorIndex,
      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
    );
  }
}
