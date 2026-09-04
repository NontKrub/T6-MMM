import 'dart:math' as math;

import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';
import 'clothing_analysis_service.dart';
import 'color_compatibility_service.dart';
import 'recommendation_explanation_service.dart';
import 'style_compatibility_service.dart';

class OutfitScoringService {
  const OutfitScoringService({
    this.colors = const ColorCompatibilityService(),
    this.styles = const StyleCompatibilityService(),
    this.explanations = const RecommendationExplanationService(),
  });

  static const colorWeight = .25;
  static const styleWeight = .25;
  static const weatherWeight = .20;
  static const preferenceWeight = .15;
  static const repetitionWeight = .10;
  static const contextWeight = .05;

  final ColorCompatibilityService colors;
  final StyleCompatibilityService styles;
  final RecommendationExplanationService explanations;

  OutfitScore score(
    OutfitCandidate candidate, {
    OutfitContext context = const OutfitContext(),
  }) {
    if (!candidate.isComplete) {
      return const OutfitScore(
        total: 0,
        color: 0,
        style: 0,
        weather: 0,
        preference: 0,
        repetition: 0,
        context: 0,
      );
    }
    final items = candidate.items;
    final color = colors.score(items);
    final style = styles.score(items, desiredStyle: context.desiredStyle);
    final weather = _weatherScore(items, context.weather);
    final preference = _preferenceScore(items, context.styleProfile);
    final repetition = _repetitionScore(candidate, context);
    final contextScore = _contextScore(items, context);
    final total = _bounded(
      color * colorWeight +
          style * styleWeight +
          weather * weatherWeight +
          preference * preferenceWeight +
          repetition * repetitionWeight +
          contextScore * contextWeight,
    );
    final base = OutfitScore(
      total: total,
      color: color,
      style: style,
      weather: weather,
      preference: preference,
      repetition: repetition,
      context: contextScore,
    );
    return base.copyWith(
      reasons: explanations.explain(
        candidate: candidate,
        score: base,
        context: context,
      ),
    );
  }

  double _weatherScore(List<ClothingItem> items, WeatherContext? weather) {
    if (weather == null) return 50;
    final warmth = items.map(_warmth).reduce((a, b) => a + b) / items.length;
    final target = switch (weather.temperatureC) {
      >= 32 => .15,
      >= 27 => .25,
      >= 20 => .45,
      >= 12 => .65,
      _ => .85,
    };
    var score = 100 - (warmth - target).abs() * 120;
    if (weather.raining) {
      final rainFriendly = items.where(_isRainFriendly).length;
      score += rainFriendly * 8;
      if (items.any(_isOpenFootwear)) score -= 25;
    }
    return _bounded(score);
  }

  double _preferenceScore(List<ClothingItem> items, UserStyleProfile profile) {
    if (profile == const UserStyleProfile()) return 50;
    var score = 50.0;
    final tokens = items.expand(_tokens).toSet();
    final explicitStyles = profile.explicitStyles
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (explicitStyles.isNotEmpty) {
      score +=
          items.where((item) {
            final itemTokens = _tokens(item);
            return explicitStyles.any(itemTokens.contains);
          }).length /
          items.length *
          25 *
          profile.confidence;
    }
    final explicitColors = profile.explicitColors
        .map((value) => value.trim().toLowerCase())
        .toSet();
    if (explicitColors.isNotEmpty) {
      score += tokens.intersection(explicitColors).length * 5;
    }
    if (profile.explicitFits.isNotEmpty) {
      score +=
          items
              .where((item) => profile.explicitFits.contains(item.fit))
              .length /
          items.length *
          15;
    }
    if (profile.explicitFormality != null) {
      score +=
          items
              .where((item) => item.formality == profile.explicitFormality)
              .length /
          items.length *
          10;
    }
    final avoidanceHits = profile.avoidances
        .map((value) => value.trim().toLowerCase())
        .where(tokens.contains)
        .length;
    score -= avoidanceHits * 12;
    for (final entry in profile.behavioralWeights.entries) {
      final key = entry.key.toLowerCase();
      final rawKey = key.contains(':') ? key.split(':').last : key;
      if (tokens.contains(key) || tokens.contains(rawKey)) {
        score += (entry.value.clamp(0, 1) - .5) * 10;
      }
    }
    return _bounded(score);
  }

  double _repetitionScore(OutfitCandidate candidate, OutfitContext context) {
    final now = context.date ?? DateTime.now();
    final key = _key(candidate.itemIds);
    var score = 100.0;
    var exactRecent = 0;
    var itemRecent = 0;
    for (final event in context.history) {
      final days = math.max(0, now.difference(event.wornAt).inDays);
      if (_key(event.itemIds) == key) {
        exactRecent++;
        score -= days <= 1
            ? 45
            : days <= 7
            ? 25
            : 8;
      }
      if (days <= 7) {
        itemRecent += event.itemIds
            .where(candidate.itemIds.contains)
            .toSet()
            .length;
      }
    }
    score -= itemRecent * 5;
    final lastWornDays = candidate.items
        .map((item) => item.lastWorn)
        .whereType<DateTime>()
        .map((date) => math.max(0, now.difference(date).inDays))
        .fold<int?>(
          null,
          (best, value) => best == null ? value : math.min(best, value),
        );
    if (exactRecent == 0 && lastWornDays != null) {
      if (lastWornDays <= 1) score -= 25;
      if (lastWornDays <= 7) score -= 8;
    }
    return _bounded(score);
  }

  double _contextScore(List<ClothingItem> items, OutfitContext context) {
    var score = 50.0;
    if (context.occasion != null) {
      final occasion = context.occasion!.toLowerCase();
      final target = occasion.contains('formal') || occasion.contains('work')
          ? ClothingFormality.business
          : ClothingFormality.casual;
      final matches = items
          .where(
            (item) =>
                item.formality == target ||
                item.formality == ClothingFormality.unknown,
          )
          .length;
      score = matches / items.length * 100;
    }
    final itemColors = items
        .expand((item) => item.colorHexes)
        .map(normalizeHexColor)
        .whereType<String>()
        .toList();
    if (context.targetHex != null && itemColors.isNotEmpty) {
      final distances = itemColors
          .map((color) => colorDistance(color, context.targetHex!))
          .toList();
      final closest = distances.reduce(math.min);
      score += closest <= 80
          ? 35
          : closest <= 180
          ? 15
          : -10;
    }
    if (context.luckyColor != null &&
        items.any(
          (item) => _tokens(item).contains(context.luckyColor!.toLowerCase()),
        )) {
      score += 20;
    }
    if (context.personalColor != null &&
        items.any(
          (item) =>
              _tokens(item).contains(context.personalColor!.toLowerCase()),
        )) {
      score += 15;
    }
    return _bounded(score);
  }

  double _warmth(ClothingItem item) =>
      item.warmthLevel ??
      switch (item.category) {
        ClothingCategory.outerwear => .75,
        ClothingCategory.pants => .4,
        ClothingCategory.top => .35,
        ClothingCategory.dress => .35,
        ClothingCategory.shoes => .2,
        _ => .2,
      };

  bool _isRainFriendly(ClothingItem item) {
    final values = [
      ...item.tags,
      item.subtype ?? '',
      item.name,
    ].join(' ').toLowerCase();
    return item.weatherSuitability.contains(WeatherSuitability.rainy) ||
        values.contains('rain') ||
        values.contains('waterproof') ||
        values.contains('boot');
  }

  bool _isOpenFootwear(ClothingItem item) {
    if (item.category != ClothingCategory.shoes) return false;
    final values = [
      ...item.tags,
      item.subtype ?? '',
      item.name,
    ].join(' ').toLowerCase();
    return values.contains('sandal') || values.contains('open');
  }

  Set<String> _tokens(ClothingItem item) => {
    ...item.tags.map((value) => value.trim().toLowerCase()),
    ...item.styles.map((value) => value.name.toLowerCase()),
    if (item.color != null) item.color!.trim().toLowerCase(),
    if (item.fit != ClothingFit.unknown) item.fit.name.toLowerCase(),
    if (item.formality != ClothingFormality.unknown)
      item.formality.name.toLowerCase(),
  };

  double _bounded(double value) => value.clamp(0, 100).toDouble();

  String _key(Iterable<String> ids) => (ids.toSet().toList()..sort()).join('|');
}
