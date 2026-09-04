import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';
import '../../shared/models/recommendation_event.dart';
import '../../shared/models/user_profile.dart';
import 'local_account_repository.dart';
import 'profile_repository.dart';
import 'supabase_service.dart';
import 'wardrobe_repository.dart';

const _uuid = Uuid();

enum GuestMigrationStatus { pending, running, failed, completed }

enum GuestMigrationPhase { profile, wardrobe, events, verification }

class GuestMigrationState {
  const GuestMigrationState({
    required this.status,
    required this.targetUserId,
    this.phase = GuestMigrationPhase.profile,
    this.itemIdMap = const {},
    this.warnings = const [],
    this.error,
    this.updatedAt,
  });

  final GuestMigrationStatus status;
  final String targetUserId;
  final GuestMigrationPhase phase;
  final Map<String, String> itemIdMap;
  final List<String> warnings;
  final String? error;
  final DateTime? updatedAt;

  factory GuestMigrationState.fromJson(Map<String, dynamic> json) {
    final rawMap = json['item_id_map'];
    return GuestMigrationState(
      status: _enumValue(
        GuestMigrationStatus.values,
        json['status'] as String?,
        GuestMigrationStatus.pending,
      ),
      targetUserId: json['target_user_id'] as String? ?? '',
      phase: _enumValue(
        GuestMigrationPhase.values,
        json['phase'] as String?,
        GuestMigrationPhase.profile,
      ),
      itemIdMap: rawMap is Map
          ? rawMap.map<String, String>(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
      warnings:
          (json['warnings'] as List?)?.whereType<String>().toList() ?? const [],
      error: json['error'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'target_user_id': targetUserId,
    'phase': phase.name,
    'item_id_map': itemIdMap,
    'warnings': warnings,
    'error': error,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  GuestMigrationState copyWith({
    GuestMigrationStatus? status,
    GuestMigrationPhase? phase,
    Map<String, String>? itemIdMap,
    List<String>? warnings,
    bool clearWarnings = false,
    String? error,
    bool clearError = false,
    DateTime? updatedAt,
  }) => GuestMigrationState(
    status: status ?? this.status,
    targetUserId: targetUserId,
    phase: phase ?? this.phase,
    itemIdMap: itemIdMap ?? this.itemIdMap,
    warnings: clearWarnings ? const [] : warnings ?? this.warnings,
    error: clearError ? null : error ?? this.error,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class GuestMigrationResult {
  const GuestMigrationResult({
    required this.state,
    this.itemsMigrated = 0,
    this.wearEventsMigrated = 0,
    this.preferenceEventsMigrated = 0,
    this.recommendationEventsMigrated = 0,
    this.warnings = const [],
    this.skippedWearEvents = 0,
    this.skippedPreferenceEvents = 0,
    this.skippedRecommendationEvents = 0,
    this.error,
  });

  final GuestMigrationState state;
  final int itemsMigrated;
  final int wearEventsMigrated;
  final int preferenceEventsMigrated;
  final int recommendationEventsMigrated;
  final List<String> warnings;
  final int skippedWearEvents;
  final int skippedPreferenceEvents;
  final int skippedRecommendationEvents;
  final String? error;

  bool get completed => state.status == GuestMigrationStatus.completed;
}

class GuestAccountSnapshot {
  const GuestAccountSnapshot({
    required this.profile,
    required this.items,
    required this.wearEvents,
    required this.preferenceEvents,
    required this.recommendationEvents,
    this.tombstones = const [],
  });

  final UserProfile? profile;
  final List<ClothingItem> items;
  final List<WearEvent> wearEvents;
  final List<LocalPreferenceEvent> preferenceEvents;
  final List<RecommendationEvent> recommendationEvents;
  final List<GuestItemTombstone> tombstones;
}

class _MigrationEventResult {
  const _MigrationEventResult({
    this.wearIds = const [],
    this.preferenceIds = const [],
    this.recommendationIds = const [],
    this.warnings = const [],
    this.skippedWearEvents = 0,
    this.skippedPreferenceEvents = 0,
    this.skippedRecommendationEvents = 0,
  });

  final List<String> wearIds;
  final List<String> preferenceIds;
  final List<String> recommendationIds;
  final List<String> warnings;
  final int skippedWearEvents;
  final int skippedPreferenceEvents;
  final int skippedRecommendationEvents;
}

class GuestAccountMigrationService {
  GuestAccountMigrationService({
    LocalAccountRepository? local,
    ProfileRepository? profiles,
    WardrobeRepository? wardrobe,
    SupabaseClient? client,
  }) : _clientOverride = client {
    _local = local ?? LocalAccountRepository();
    _profiles = profiles ?? ProfileRepository(client: client);
    _wardrobe = wardrobe ?? WardrobeRepository(local: _local, client: client);
  }

  final SupabaseClient? _clientOverride;
  late final LocalAccountRepository _local;
  late final ProfileRepository _profiles;
  late final WardrobeRepository _wardrobe;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  Future<bool> hasPendingMigration() async {
    if (!await _local.hasGuestAccount()) return false;
    final raw = await _local.fetchGuestMigrationState();
    if (raw == null) return true;
    return GuestMigrationState.fromJson(raw).status !=
        GuestMigrationStatus.completed;
  }

  Future<GuestMigrationResult> migrate() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return GuestMigrationResult(
        state: GuestMigrationState(
          status: GuestMigrationStatus.failed,
          targetUserId: '',
          error: 'A signed-in account is required to import local data.',
        ),
        error: 'A signed-in account is required to import local data.',
      );
    }
    if (!await _local.hasGuestAccount()) {
      return GuestMigrationResult(
        state: GuestMigrationState(
          status: GuestMigrationStatus.completed,
          targetUserId: user.id,
        ),
      );
    }

    final snapshot = await _snapshot();
    var state = await _stateFor(user.id);
    var itemsMigrated = 0;
    var wearEventsMigrated = 0;
    var preferenceEventsMigrated = 0;
    var recommendationEventsMigrated = 0;
    var eventResult = const _MigrationEventResult();

    try {
      state = await _save(
        state.copyWith(
          status: GuestMigrationStatus.running,
          phase: GuestMigrationPhase.profile,
          clearWarnings: true,
          clearError: true,
        ),
      );
      if (snapshot.profile != null) {
        await _profiles.mergeGuestProfile(snapshot.profile!);
      }

      state = await _save(state.copyWith(phase: GuestMigrationPhase.wardrobe));
      for (final item in snapshot.items) {
        var targetId = state.itemIdMap[item.id];
        if (targetId == null) {
          targetId = Uuid.isValidUUID(fromString: item.id)
              ? item.id
              : _uuid.v4();
          if (await _wardrobe.hasCloudItem(targetId)) {
            final alternateId = _uuid.v5(
              Namespace.url.value,
              'mmm-guest-item:${user.id}:${item.id}',
            );
            targetId = await _wardrobe.hasCloudItem(alternateId)
                ? _uuid.v4()
                : alternateId;
          }
          state = await _save(
            state.copyWith(itemIdMap: {...state.itemIdMap, item.id: targetId}),
          );
        }

        final bytes = await _readImage(item);
        try {
          await _wardrobe.migrateLocalItem(
            item: item,
            targetId: targetId,
            bytes: bytes,
          );
        } on PostgrestException catch (error) {
          if (error.code != '23505' && error.code != '42501') rethrow;
          final alternateId = _uuid.v5(
            Namespace.url.value,
            'mmm-guest-item:${user.id}:${item.id}',
          );
          if (alternateId == targetId) rethrow;
          targetId = alternateId;
          state = await _save(
            state.copyWith(itemIdMap: {...state.itemIdMap, item.id: targetId}),
          );
          await _wardrobe.migrateLocalItem(
            item: item,
            targetId: targetId,
            bytes: bytes,
          );
        }
        itemsMigrated++;
      }

      state = await _save(state.copyWith(phase: GuestMigrationPhase.events));
      eventResult = await _migrateEvents(
        snapshot,
        state,
        user.id,
        onWarnings: (warnings) async {
          state = await _save(state.copyWith(warnings: warnings));
        },
      );
      wearEventsMigrated = eventResult.wearIds.length;
      preferenceEventsMigrated = eventResult.preferenceIds.length;
      recommendationEventsMigrated = eventResult.recommendationIds.length;
      state = await _save(state.copyWith(warnings: eventResult.warnings));

      state = await _save(
        state.copyWith(phase: GuestMigrationPhase.verification),
      );
      await _verify(snapshot, state, user.id, eventResult);
      await _local.clearGuestAccount();

      return GuestMigrationResult(
        state: state.copyWith(status: GuestMigrationStatus.completed),
        itemsMigrated: itemsMigrated,
        wearEventsMigrated: wearEventsMigrated,
        preferenceEventsMigrated: preferenceEventsMigrated,
        recommendationEventsMigrated: recommendationEventsMigrated,
        warnings: eventResult.warnings,
        skippedWearEvents: eventResult.skippedWearEvents,
        skippedPreferenceEvents: eventResult.skippedPreferenceEvents,
        skippedRecommendationEvents: eventResult.skippedRecommendationEvents,
      );
    } catch (error) {
      final failed = await _save(
        state.copyWith(
          status: GuestMigrationStatus.failed,
          error: error.toString(),
        ),
      );
      return GuestMigrationResult(
        state: failed,
        itemsMigrated: itemsMigrated,
        wearEventsMigrated: wearEventsMigrated,
        preferenceEventsMigrated: preferenceEventsMigrated,
        recommendationEventsMigrated: recommendationEventsMigrated,
        warnings: state.warnings,
        skippedWearEvents: eventResult.skippedWearEvents,
        skippedPreferenceEvents: eventResult.skippedPreferenceEvents,
        skippedRecommendationEvents: eventResult.skippedRecommendationEvents,
        error: error.toString(),
      );
    }
  }

  Future<GuestAccountSnapshot> _snapshot() async => GuestAccountSnapshot(
    profile: await _local.fetchProfile(),
    items: await _local.fetchItems(),
    wearEvents: await _local.fetchWearEvents(),
    preferenceEvents: await _local.fetchPreferenceEvents(),
    recommendationEvents: await _local.fetchRecommendationEvents(),
    tombstones: await _local.fetchItemTombstones(),
  );

  Future<GuestMigrationState> _stateFor(String userId) async {
    final raw = await _local.fetchGuestMigrationState();
    if (raw == null) {
      return GuestMigrationState(
        status: GuestMigrationStatus.pending,
        targetUserId: userId,
      );
    }
    final state = GuestMigrationState.fromJson(raw);
    if (state.targetUserId != userId) {
      return GuestMigrationState(
        status: GuestMigrationStatus.pending,
        targetUserId: userId,
      );
    }
    return state;
  }

  Future<GuestMigrationState> _save(GuestMigrationState state) async {
    final updated = state.copyWith(updatedAt: DateTime.now().toUtc());
    await _local.saveGuestMigrationState(updated.toJson());
    return updated;
  }

  Future<Uint8List> _readImage(ClothingItem item) async {
    final path = item.imagePath ?? item.imageUrl;
    if (path.isEmpty || !await File(path).exists()) {
      throw StateError('The local image for "${item.name}" is unavailable.');
    }
    return File(path).readAsBytes();
  }

  Future<_MigrationEventResult> _migrateEvents(
    GuestAccountSnapshot snapshot,
    GuestMigrationState state,
    String userId, {
    required Future<void> Function(List<String>) onWarnings,
  }) async {
    final client = _client!;
    final itemById = {for (final item in snapshot.items) item.id: item};
    final wearIds = <String>[];
    final preferenceIds = <String>[];
    final recommendationIds = <String>[];
    final warnings = <String>[];
    var skippedWearEvents = 0;
    var skippedPreferenceEvents = 0;
    var skippedRecommendationEvents = 0;

    Future<void> addWarning(String warning) async {
      warnings.add(warning);
      await onWarnings(List.unmodifiable(warnings));
    }

    for (final event in snapshot.wearEvents) {
      final itemIds = tryMapGuestItemIds(event.itemIds, state);
      if (itemIds == null) {
        skippedWearEvents++;
        await addWarning(
          _eventWarning('wear', event.itemIds, snapshot.tombstones),
        );
        continue;
      }
      final colors = event.itemIds
          .map((id) => itemById[id]?.color)
          .whereType<String>()
          .where((color) => color.isNotEmpty)
          .toSet()
          .toList();
      final eventId = _eventId(userId, 'wear', _wearEventKey(event));
      await client.from('wear_events').upsert({
        'id': eventId,
        'user_id': userId,
        'outfit_id': null,
        'clothing_item_ids': itemIds,
        'colors': colors,
        'worn_at': event.wornAt.toUtc().toIso8601String(),
        'source': _wearSource(event.source),
      }, onConflict: 'id');
      wearIds.add(eventId);
    }

    for (final event in snapshot.preferenceEvents) {
      final itemIds = tryMapGuestItemIds(event.itemIds, state);
      if (itemIds == null) {
        skippedPreferenceEvents++;
        await addWarning(
          _eventWarning('preference', event.itemIds, snapshot.tombstones),
        );
        continue;
      }
      final eventId = _eventId(
        userId,
        'preference',
        jsonEncode(event.toJson()),
      );
      await client.from('outfit_preference_events').upsert({
        'id': eventId,
        'user_id': userId,
        'outfit_id': null,
        'style': event.style,
        'clothing_item_ids': itemIds,
        'tags': event.tags,
        'colors': event.colors,
        'selection_factors': const <String>[],
        'score': null,
        'source': event.source,
        'created_at': event.selectedAt.toUtc().toIso8601String(),
      }, onConflict: 'id');
      preferenceIds.add(eventId);
    }

    for (final event in snapshot.recommendationEvents) {
      final unknownWarning = recommendationMigrationWarning(event.eventType);
      if (unknownWarning != null) {
        skippedRecommendationEvents++;
        await addWarning(unknownWarning);
        continue;
      }
      final itemIds = tryMapGuestItemIds(event.itemIds, state);
      if (itemIds == null) {
        skippedRecommendationEvents++;
        await addWarning(
          _eventWarning('recommendation', event.itemIds, snapshot.tombstones),
        );
        continue;
      }
      final eventId = _eventId(
        userId,
        'recommendation',
        _recommendationEventKey(event),
      );
      await client.from('recommendation_events').upsert({
        'id': eventId,
        'user_id': userId,
        'outfit_id': null,
        'event_type': event.eventType.name,
        'clothing_item_ids': itemIds,
        'metadata': {...event.metadata, 'guest_event_id': event.id},
        'created_at': event.createdAt.toUtc().toIso8601String(),
      }, onConflict: 'id');
      recommendationIds.add(eventId);
    }

    return _MigrationEventResult(
      wearIds: wearIds,
      preferenceIds: preferenceIds,
      recommendationIds: recommendationIds,
      warnings: warnings,
      skippedWearEvents: skippedWearEvents,
      skippedPreferenceEvents: skippedPreferenceEvents,
      skippedRecommendationEvents: skippedRecommendationEvents,
    );
  }

  Future<void> _verify(
    GuestAccountSnapshot snapshot,
    GuestMigrationState state,
    String userId,
    _MigrationEventResult eventResult,
  ) async {
    final client = _client!;
    if (snapshot.profile != null) {
      final profile = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) throw StateError('The cloud profile was not saved.');
    }

    final targetIds = snapshot.items
        .map((item) => state.itemIdMap[item.id])
        .whereType<String>()
        .toSet()
        .toList();
    if (targetIds.length != snapshot.items.length) {
      throw StateError('The wardrobe ID mapping is incomplete.');
    }
    if (targetIds.isNotEmpty) {
      final rows = await client
          .from('clothing_items')
          .select('id,image_path')
          .eq('user_id', userId)
          .inFilter('id', targetIds);
      if (rows.length != targetIds.length) {
        throw StateError('The cloud wardrobe is incomplete.');
      }
      for (final row in rows) {
        final path = row['image_path'] as String?;
        if (path == null || path.isEmpty) {
          throw StateError('A migrated wardrobe image is missing.');
        }
        await client.storage.from(WardrobeRepository.bucket).download(path);
      }
    }

    final tables = [
      ('wear_events', eventResult.wearIds),
      ('outfit_preference_events', eventResult.preferenceIds),
      ('recommendation_events', eventResult.recommendationIds),
    ];
    for (final (table, ids) in tables) {
      if (ids.isEmpty) continue;
      final rows = await client
          .from(table)
          .select('id')
          .eq('user_id', userId)
          .inFilter('id', ids);
      if (rows.length != ids.length) {
        throw StateError('Migrated $table could not be verified.');
      }
    }
  }

  String _eventWarning(
    String type,
    List<String> itemIds,
    List<GuestItemTombstone> tombstones,
  ) {
    final hasTombstone = itemIds.any(
      (id) => tombstones.any((tombstone) => tombstone.id == id),
    );
    final reason = hasTombstone
        ? 'a referenced wardrobe item was deleted locally'
        : 'a referenced wardrobe item is unavailable';
    return 'Skipped $type history because $reason.';
  }

  String _eventId(String userId, String type, String source) =>
      _uuid.v5(Namespace.url.value, 'mmm-guest-event:$userId:$type:$source');

  String _wearEventKey(WearEvent event) =>
      event.id ?? jsonEncode(_wearJson(event));

  String _recommendationEventKey(RecommendationEvent event) =>
      event.id ?? jsonEncode(event.toJson());

  Map<String, dynamic> _wearJson(WearEvent event) => {
    'id': event.id,
    'outfit_id': event.outfitId,
    'item_ids': event.itemIds,
    'worn_at': event.wornAt.toUtc().toIso8601String(),
    'source': event.source,
  };

  String _wearSource(String value) =>
      const {'recommended', 'manual', 'in_a_rush'}.contains(value)
      ? value
      : 'manual';
}

String? recommendationMigrationWarning(RecommendationEventType eventType) {
  if (eventType != RecommendationEventType.unknown) return null;
  return 'Skipped recommendation history because its event type is no longer recognized.';
}

List<String> mapGuestItemIds(List<String> itemIds, GuestMigrationState state) {
  final mapped = tryMapGuestItemIds(itemIds, state);
  if (mapped == null) {
    throw StateError('A migrated event references an unknown wardrobe item.');
  }
  return mapped;
}

List<String>? tryMapGuestItemIds(
  List<String> itemIds,
  GuestMigrationState state,
) {
  final sourceIds = itemIds.toSet();
  final mappedIds = sourceIds
      .map((id) => state.itemIdMap[id])
      .whereType<String>()
      .toSet();
  if (mappedIds.length != sourceIds.length) {
    return null;
  }
  return mappedIds.toList();
}

T _enumValue<T extends Enum>(Iterable<T> values, String? raw, T fallback) =>
    values.firstWhere((value) => value.name == raw, orElse: () => fallback);
