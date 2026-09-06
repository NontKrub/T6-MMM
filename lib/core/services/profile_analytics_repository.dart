import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';
import '../../shared/models/profile_analytics.dart';
import 'local_account_repository.dart';
import 'supabase_service.dart';
import 'wardrobe_repository.dart';

class ProfileAnalyticsRepository {
  ProfileAnalyticsRepository({
    LocalAccountRepository? local,
    WardrobeRepository? wardrobe,
    SupabaseClient? client,
  }) : _local = local ?? LocalAccountRepository(),
       _clientOverride = client,
       _wardrobe = wardrobe ?? WardrobeRepository(client: client);

  final LocalAccountRepository _local;
  final SupabaseClient? _clientOverride;
  final WardrobeRepository _wardrobe;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  Future<ProfileAnalyticsSnapshot> fetch({
    required ProfileAnalyticsRange range,
    DateTime? now,
  }) async {
    final client = _client;
    final input = await _fetchInput(client, range: range, now: now);
    return ProfileAnalyticsCalculator.calculate(input, range: range, now: now);
  }

  Future<ProfileAnalyticsInput> _fetchInput(
    SupabaseClient? client, {
    required ProfileAnalyticsRange range,
    DateTime? now,
  }) async {
    final items = await _wardrobe.fetchItems();
    if (client == null || client.auth.currentUser == null) {
      return ProfileAnalyticsInput(
        items: items,
        events: await _local.fetchWearEvents(),
      );
    }

    final window = ProfileAnalyticsCalculator.windowFor(range, now);
    final rows = await client
        .from('wear_events')
        .select('id,outfit_id,clothing_item_ids,worn_at,source')
        .eq('user_id', client.auth.currentUser!.id)
        .gte('worn_at', window.previousStart.toUtc().toIso8601String())
        .lt('worn_at', window.endExclusive.toUtc().toIso8601String())
        .order('worn_at', ascending: false);
    final events = rows
        .map((row) => _eventFromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    return ProfileAnalyticsInput(items: items, events: events);
  }

  WearEvent _eventFromRow(Map<String, dynamic> row) => WearEvent(
    id: row['id'] as String?,
    outfitId: row['outfit_id'] as String?,
    itemIds: (row['clothing_item_ids'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    wornAt:
        DateTime.tryParse(row['worn_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    source: row['source'] as String? ?? 'manual',
  );
}

class ProfileAnalyticsCalculator {
  const ProfileAnalyticsCalculator._();

  static ProfileAnalyticsWindow windowFor(
    ProfileAnalyticsRange range,
    DateTime? now,
  ) => _window(range, (now ?? DateTime.now()).toLocal());

  static ProfileAnalyticsSnapshot calculate(
    ProfileAnalyticsInput input, {
    required ProfileAnalyticsRange range,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toLocal();
    final window = _window(range, reference);
    final activeItems = input.items
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
    final itemById = {for (final item in activeItems) item.id: item};
    final currentEvents = _eventsInWindow(
      input.events,
      window.start,
      window.endExclusive,
      itemById,
    );
    final previousEvents = _eventsInWindow(
      input.events,
      window.previousStart,
      window.previousEndExclusive,
      itemById,
    );
    final currentItemIds = _uniqueItemIds(currentEvents);
    final previousItemIds = _uniqueItemIds(previousEvents);
    final mostWornItems = _mostWorn(currentEvents, itemById);
    final recentLooks = _looks(currentEvents, itemById)
      ..sort((a, b) => b.wornAt.compareTo(a.wornAt));
    final repeatedLook = _repeatedLook(currentEvents, itemById);

    return ProfileAnalyticsSnapshot(
      range: range,
      window: window,
      wardrobeItemCount: activeItems.length,
      looksWorn: currentEvents.where(_isLook).length,
      uniqueItemsWorn: currentItemIds.length,
      utilization: _percentage(currentItemIds.length, activeItems.length),
      previousUtilization: _percentage(
        previousItemIds.length,
        activeItems.length,
      ),
      mostWornItems: mostWornItems,
      unwornItems: _unwornItems(activeItems, input.events, reference),
      repeatedLook: repeatedLook,
      recentLooks: recentLooks.take(5).toList(growable: false),
      activityBuckets: _activityBuckets(currentEvents, window, range),
      categoryDistribution: _categoryDistribution(activeItems),
      styleDistribution: _styleDistribution(activeItems),
      colorDistribution: _colorDistribution(activeItems),
      hasWearHistory: input.events.isNotEmpty,
    );
  }

  static List<WearEvent> _eventsInWindow(
    List<WearEvent> events,
    DateTime start,
    DateTime endExclusive,
    Map<String, ClothingItem> itemById,
  ) => events
      .where((event) {
        final wornAt = event.wornAt.toLocal();
        return !wornAt.isBefore(start) && wornAt.isBefore(endExclusive);
      })
      .map(
        (event) => WearEvent(
          id: event.id,
          outfitId: event.outfitId,
          itemIds: _activeItemIds(event, itemById),
          wornAt: event.wornAt,
          source: event.source,
        ),
      )
      .where((event) => event.itemIds.isNotEmpty)
      .toList(growable: false);

  static List<String> _activeItemIds(
    WearEvent event,
    Map<String, ClothingItem> itemById,
  ) => event.itemIds.where(itemById.containsKey).toSet().toList()..sort();

  static Set<String> _uniqueItemIds(Iterable<WearEvent> events) =>
      events.expand((event) => event.itemIds).toSet();

  static bool _isLook(WearEvent event) =>
      event.outfitId != null || event.itemIds.toSet().length >= 2;

  static List<ProfileAnalyticsItemStat> _mostWorn(
    Iterable<WearEvent> events,
    Map<String, ClothingItem> itemById,
  ) {
    final counts = <String, int>{};
    final latest = <String, DateTime>{};
    for (final event in events) {
      for (final id in event.itemIds.toSet()) {
        counts[id] = (counts[id] ?? 0) + 1;
        final wornAt = event.wornAt.toLocal();
        if (!latest.containsKey(id) || wornAt.isAfter(latest[id]!)) {
          latest[id] = wornAt;
        }
      }
    }
    final stats =
        counts.entries
            .map(
              (entry) => ProfileAnalyticsItemStat(
                item: itemById[entry.key]!,
                wearCount: entry.value,
                lastAppearance: latest[entry.key],
              ),
            )
            .toList()
          ..sort((a, b) {
            final byCount = b.wearCount.compareTo(a.wearCount);
            if (byCount != 0) return byCount;
            final byLatest = (b.lastAppearance ?? DateTime(0)).compareTo(
              a.lastAppearance ?? DateTime(0),
            );
            if (byLatest != 0) return byLatest;
            final byId = a.item.id.compareTo(b.item.id);
            return byId != 0 ? byId : a.item.name.compareTo(b.item.name);
          });
    return stats.take(5).toList(growable: false);
  }

  static List<ProfileAnalyticsLook> _looks(
    Iterable<WearEvent> events,
    Map<String, ClothingItem> itemById,
  ) => events
      .where(_isLook)
      .map(
        (event) => ProfileAnalyticsLook(
          wornAt: event.wornAt,
          outfitId: event.outfitId,
          items: event.itemIds
              .map((id) => itemById[id])
              .whereType<ClothingItem>()
              .toList(growable: false),
        ),
      )
      .toList();

  static ProfileAnalyticsLook? _repeatedLook(
    Iterable<WearEvent> events,
    Map<String, ClothingItem> itemById,
  ) {
    final groups = <String, List<WearEvent>>{};
    for (final event in events.where(_isLook)) {
      final ids = event.itemIds.toSet().toList()..sort();
      if (ids.length < 2) continue;
      final key = ids.join('|');
      groups.putIfAbsent(key, () => []).add(event);
    }
    final repeated = groups.entries.where((entry) => entry.value.length >= 2);
    final best = repeated.fold<MapEntry<String, List<WearEvent>>?>(null, (
      current,
      entry,
    ) {
      if (current == null) return entry;
      final countComparison = entry.value.length.compareTo(
        current.value.length,
      );
      if (countComparison != 0) {
        return countComparison > 0 ? entry : current;
      }
      final entryLatest = entry.value
          .map((event) => event.wornAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final currentLatest = current.value
          .map((event) => event.wornAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (entryLatest != currentLatest) {
        return entryLatest.isAfter(currentLatest) ? entry : current;
      }
      return entry.key.compareTo(current.key) < 0 ? entry : current;
    });
    if (best == null) return null;
    final latest = best.value
        .map((event) => event.wornAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final latestEvent = best.value.firstWhere(
      (event) => event.wornAt == latest,
    );
    return ProfileAnalyticsLook(
      wornAt: latest,
      outfitId: latestEvent.outfitId,
      items: best.key
          .split('|')
          .map((id) => itemById[id])
          .whereType<ClothingItem>()
          .toList(growable: false),
      repeatCount: best.value.length,
    );
  }

  static List<ClothingItem> _unwornItems(
    List<ClothingItem> items,
    List<WearEvent> events,
    DateTime now,
  ) {
    final cutoff = _startOfDay(now).subtract(const Duration(days: 30));
    final latestByItem = <String, DateTime>{};
    for (final event in events) {
      final wornAt = event.wornAt.toLocal();
      for (final id in event.itemIds.toSet()) {
        final previous = latestByItem[id];
        if (previous == null || wornAt.isAfter(previous)) {
          latestByItem[id] = wornAt;
        }
      }
    }
    return items
        .where((item) {
          final createdAt = item.createdAt?.toLocal();
          final lastWorn = latestByItem[item.id] ?? item.lastWorn?.toLocal();
          return createdAt != null &&
              !createdAt.isAfter(cutoff) &&
              (lastWorn == null || lastWorn.isBefore(cutoff));
        })
        .toList(growable: false);
  }

  static List<ProfileActivityBucket> _activityBuckets(
    List<WearEvent> events,
    ProfileAnalyticsWindow window,
    ProfileAnalyticsRange range,
  ) {
    final bucketCount = switch (range) {
      ProfileAnalyticsRange.sevenDays => 7,
      ProfileAnalyticsRange.monthToDate => math.min(7, window.dayCount),
      ProfileAnalyticsRange.thirtyDays => 10,
      ProfileAnalyticsRange.ninetyDays => 12,
      ProfileAnalyticsRange.oneYear => 12,
    };
    final safeCount = math.max(1, bucketCount);
    final bucketSize = math.max(1, (window.dayCount / safeCount).ceil());
    final counts = List<int>.filled(safeCount, 0);
    for (final event in events.where(_isLook)) {
      final eventDay = event.wornAt.toLocal();
      final day = DateTime.utc(eventDay.year, eventDay.month, eventDay.day)
          .difference(
            DateTime.utc(
              window.start.year,
              window.start.month,
              window.start.day,
            ),
          )
          .inDays;
      final index = (day ~/ bucketSize).clamp(0, safeCount - 1);
      counts[index]++;
    }
    return List.generate(safeCount, (index) {
      final start = window.start.add(Duration(days: index * bucketSize));
      return ProfileActivityBucket(start: start, looks: counts[index]);
    }, growable: false);
  }

  static Map<ClothingCategory, int> _categoryDistribution(
    Iterable<ClothingItem> items,
  ) {
    final counts = <ClothingCategory, int>{};
    for (final item in items) {
      if (item.category == ClothingCategory.unknown) continue;
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  static Map<ClothingStyle, int> _styleDistribution(
    Iterable<ClothingItem> items,
  ) {
    final counts = <ClothingStyle, int>{};
    for (final item in items) {
      for (final style in item.styles.toSet()) {
        if (style == ClothingStyle.unknown) continue;
        counts[style] = (counts[style] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  static List<ProfileColorStat> _colorDistribution(
    Iterable<ClothingItem> items,
  ) {
    final counts = <String, int>{};
    final validHex = RegExp(r'^#[0-9a-fA-F]{6}$');
    for (final item in items) {
      for (final raw
          in item.colorHexes
              .map((value) => value.trim().toUpperCase())
              .toSet()) {
        if (!validHex.hasMatch(raw)) continue;
        counts[raw] = (counts[raw] ?? 0) + 1;
      }
    }
    final stats =
        counts.entries
            .map(
              (entry) =>
                  ProfileColorStat(hex: entry.key, itemCount: entry.value),
            )
            .toList()
          ..sort((a, b) {
            final byCount = b.itemCount.compareTo(a.itemCount);
            return byCount != 0 ? byCount : a.hex.compareTo(b.hex);
          });
    return stats.take(4).toList(growable: false);
  }

  static double _percentage(int numerator, int denominator) {
    if (denominator == 0) return 0;
    return numerator / denominator * 100;
  }

  static ProfileAnalyticsWindow _window(
    ProfileAnalyticsRange range,
    DateTime now,
  ) {
    final today = _startOfDay(now);
    if (range == ProfileAnalyticsRange.monthToDate) {
      final start = DateTime(today.year, today.month, 1);
      final end = today.add(const Duration(days: 1));
      final previousMonth = DateTime(today.year, today.month - 1, 1);
      final previousMonthDays = DateTime(
        previousMonth.year,
        previousMonth.month + 1,
        0,
      ).day;
      final previousDay = math.min(today.day, previousMonthDays);
      return ProfileAnalyticsWindow(
        start: start,
        endExclusive: end,
        previousStart: previousMonth,
        previousEndExclusive: previousMonth.add(Duration(days: previousDay)),
      );
    }

    final days = switch (range) {
      ProfileAnalyticsRange.sevenDays => 7,
      ProfileAnalyticsRange.thirtyDays => 30,
      ProfileAnalyticsRange.ninetyDays => 90,
      ProfileAnalyticsRange.oneYear => 365,
      ProfileAnalyticsRange.monthToDate => 1,
    };
    final start = today.subtract(Duration(days: days - 1));
    return ProfileAnalyticsWindow(
      start: start,
      endExclusive: today.add(const Duration(days: 1)),
      previousStart: start.subtract(Duration(days: days)),
      previousEndExclusive: start,
    );
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
