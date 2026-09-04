import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';
import '../../shared/models/recommendation_event.dart';
import '../../shared/models/user_profile.dart';
import 'recommendation_feedback_service.dart';

const _uuid = Uuid();

class LocalPreferenceEvent {
  const LocalPreferenceEvent({
    required this.style,
    required this.itemIds,
    required this.tags,
    required this.colors,
    required this.source,
    required this.selectedAt,
  });

  final String? style;
  final List<String> itemIds;
  final List<String> tags;
  final List<String> colors;
  final String source;
  final DateTime selectedAt;

  factory LocalPreferenceEvent.fromJson(Map<String, dynamic> json) =>
      LocalPreferenceEvent(
        style: json['style'] as String?,
        itemIds: (json['item_ids'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        tags: (json['tags'] as List? ?? const []).whereType<String>().toList(),
        colors: (json['colors'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        source: json['source'] as String? ?? 'generated',
        selectedAt:
            DateTime.tryParse(json['selected_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toJson() => {
    'style': style,
    'item_ids': itemIds,
    'tags': tags,
    'colors': colors,
    'source': source,
    'selected_at': selectedAt.toUtc().toIso8601String(),
  };
}

class GuestItemTombstone {
  const GuestItemTombstone({
    required this.id,
    required this.name,
    required this.category,
    required this.deletedAt,
  });

  final String id;
  final String name;
  final ClothingCategory category;
  final DateTime deletedAt;

  factory GuestItemTombstone.fromJson(Map<String, dynamic> json) {
    return GuestItemTombstone(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: clothingCategoryFromString(json['category'] as String?),
      deletedAt:
          DateTime.tryParse(json['deleted_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'deleted_at': deletedAt.toUtc().toIso8601String(),
  };
}

class LocalAccountRepository {
  static const _guestEnabledKey = 'mmm_guest_enabled';
  static const _profileKey = 'mmm_guest_profile';
  static const _wardrobeKey = 'mmm_guest_wardrobe';
  static const _wearHistoryKey = 'mmm_guest_wear_history';
  static const _wearEventsKey = 'mmm_guest_wear_events';
  static const _preferenceHistoryKey = 'mmm_guest_preference_history';
  static const _recommendationEventsKey = 'mmm_guest_recommendation_events';
  static const _behavioralWeightsKey = 'mmm_guest_behavioral_weights';
  static const _itemTombstonesKey = 'mmm_guest_item_tombstones';

  Future<bool> hasGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestEnabledKey) ?? false;
  }

  Future<UserProfile> startGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);

    final existing = await fetchProfile();
    if (existing != null) return existing;

    const profile = UserProfile(id: 'local_guest', name: 'Guest');
    await upsertProfile(profile);
    return profile;
  }

  Future<void> clearGuestAccount() async {
    // Destructive: call only after an explicit local-account deletion or a
    // verified guest-to-cloud migration.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestEnabledKey);
    await prefs.remove(_profileKey);
    await prefs.remove(_wardrobeKey);
    await prefs.remove(_wearHistoryKey);
    await prefs.remove(_wearEventsKey);
    await prefs.remove(_preferenceHistoryKey);
    await prefs.remove(_recommendationEventsKey);
    await prefs.remove(_behavioralWeightsKey);
    await prefs.remove(_itemTombstonesKey);
    await prefs.remove(_migrationStateKey);
  }

  static const _migrationStateKey = 'mmm_guest_migration_state';

  Future<Map<String, dynamic>?> fetchGuestMigrationState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_migrationStateKey);
    if (raw == null || raw.isEmpty) return null;
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> saveGuestMigrationState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_migrationStateKey, jsonEncode(state));
  }

  Future<UserProfile?> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_guestEnabledKey) ?? false)) return null;

    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile.fromJson(
      json,
      styles:
          (json['style_preferences'] as List?)?.whereType<String>().toList() ??
          const [],
      occasions:
          (json['occasions'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<List<ClothingItem>> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_guestEnabledKey) ?? false)) return const [];

    final raw = prefs.getString(_wardrobeKey);
    if (raw == null || raw.isEmpty) return const [];

    final rows = (jsonDecode(raw) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return rows.map(ClothingItem.fromJson).toList();
  }

  Future<ClothingItem> insertItem(ClothingItem item) async {
    final itemWithId = item.id.isEmpty ? item.copyWithWithId(_uuid.v4()) : item;
    final items = await fetchItems();
    await _saveItems([
      itemWithId,
      ...items.where((i) => i.id != itemWithId.id),
    ]);
    return itemWithId;
  }

  Future<void> archiveItem(String id) async {
    final items = await fetchItems();
    final item = items.where((item) => item.id == id).firstOrNull;
    if (item != null) {
      final tombstones = await fetchItemTombstones();
      tombstones.removeWhere((entry) => entry.id == id);
      tombstones.add(
        GuestItemTombstone(
          id: item.id,
          name: item.name,
          category: item.category,
          deletedAt: DateTime.now().toUtc(),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _itemTombstonesKey,
        jsonEncode(tombstones.map((entry) => entry.toJson()).toList()),
      );
    }
    await _saveItems(items.where((item) => item.id != id).toList());
  }

  Future<List<GuestItemTombstone>> fetchItemTombstones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemTombstonesKey);
    if (raw == null || raw.isEmpty) return <GuestItemTombstone>[];
    final rows = jsonDecode(raw);
    if (rows is! List) return <GuestItemTombstone>[];
    return rows
        .whereType<Map>()
        .map(
          (row) => GuestItemTombstone.fromJson(Map<String, dynamic>.from(row)),
        )
        .where((entry) => entry.id.isNotEmpty)
        .toList(growable: true);
  }

  Future<void> updateItems(List<ClothingItem> items) => _saveItems(items);

  Future<List<List<String>>> fetchWearCombinations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wearHistoryKey);
    if (raw == null || raw.isEmpty) return <List<String>>[];
    return (jsonDecode(raw) as List)
        .map((entry) => (entry as List).whereType<String>().toList())
        .toList();
  }

  Future<void> recordWearCombination(List<String> itemIds) async {
    final normalized = itemIds.toSet().toList()..sort();
    final history = await fetchWearCombinations();
    history.add(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wearHistoryKey, jsonEncode(history));
  }

  Future<List<WearEvent>> fetchWearEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wearEventsKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .map((row) => _wearEventFromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> recordWearEvent(WearEvent event) async {
    final normalized = event.itemIds.toSet().toList()..sort();
    final events = [
      ...await fetchWearEvents(),
      ...[
        WearEvent(
          id: event.id,
          outfitId: event.outfitId,
          itemIds: normalized,
          wornAt: event.wornAt,
          source: event.source,
        ),
      ],
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _wearEventsKey,
      jsonEncode(
        events.reversed
            .take(100)
            .toList()
            .reversed
            .map(_wearEventToJson)
            .toList(),
      ),
    );
    await recordWearCombination(normalized);
  }

  Future<List<LocalPreferenceEvent>> fetchPreferenceEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferenceHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .map(
          (row) => LocalPreferenceEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> recordPreferenceEvent(LocalPreferenceEvent event) async {
    final events = [...await fetchPreferenceEvents()];
    events.add(event);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferenceHistoryKey,
      jsonEncode(
        events.reversed
            .take(100)
            .toList()
            .reversed
            .map((entry) => entry.toJson())
            .toList(),
      ),
    );
  }

  Future<List<RecommendationEvent>> fetchRecommendationEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recommendationEventsKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .map(
          (row) => RecommendationEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> recordRecommendationEvent(RecommendationEvent event) async {
    final events = [...await fetchRecommendationEvents(), event];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recommendationEventsKey,
      jsonEncode(
        events.reversed
            .take(200)
            .toList()
            .reversed
            .map((entry) => entry.toJson())
            .toList(),
      ),
    );
    final learned = const RecommendationFeedbackService().apply(
      await fetchBehavioralWeights(),
      event,
    );
    await prefs.setString(_behavioralWeightsKey, jsonEncode(learned));
  }

  Future<Map<String, double>> fetchBehavioralWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_behavioralWeightsKey);
    if (raw == null || raw.isEmpty) return const {};
    final json = jsonDecode(raw);
    if (json is! Map) return const {};
    return json.map<String, double>((key, value) {
      final number = value is num ? value.toDouble() : .5;
      return MapEntry(key.toString(), number.clamp(0, 1).toDouble());
    });
  }

  Future<void> _saveItems(List<ClothingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);
    await prefs.setString(
      _wardrobeKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

extension on ClothingItem {
  ClothingItem copyWithWithId(String id) {
    return ClothingItem(
      id: id,
      userId: userId,
      name: name,
      brand: brand,
      category: category,
      subtype: subtype,
      imageUrl: imageUrl,
      imagePath: imagePath,
      tags: tags,
      color: color,
      colorHexes: colorHexes,
      pattern: pattern,
      material: material,
      fit: fit,
      silhouette: silhouette,
      styles: styles,
      formality: formality,
      seasons: seasons,
      weatherSuitability: weatherSuitability,
      warmthLevel: warmthLevel,
      analysisConfidence: analysisConfidence,
      classificationSource: classificationSource,
      colorSource: colorSource,
      analysisSource: analysisSource,
      analysisStatus: analysisStatus,
      analysisVersion: analysisVersion,
      correctedFields: correctedFields,
      userCorrected: userCorrected,
      analyzedAt: analyzedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      wearCount: wearCount,
      lastWorn: lastWorn,
    );
  }
}

Map<String, dynamic> _wearEventToJson(WearEvent event) => {
  if (event.id != null) 'id': event.id,
  if (event.outfitId != null) 'outfit_id': event.outfitId,
  'item_ids': event.itemIds,
  'worn_at': event.wornAt.toUtc().toIso8601String(),
  'source': event.source,
};

WearEvent _wearEventFromJson(Map<String, dynamic> json) => WearEvent(
  id: json['id'] as String?,
  outfitId: json['outfit_id'] as String?,
  itemIds: (json['item_ids'] as List? ?? const []).whereType<String>().toList(),
  wornAt:
      DateTime.tryParse(json['worn_at'] as String? ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  source: json['source'] as String? ?? 'manual',
);
