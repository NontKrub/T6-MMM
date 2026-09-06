import 'clothing_item.dart';
import 'outfit_intelligence.dart';

enum ProfileAnalyticsRange {
  monthToDate,
  sevenDays,
  thirtyDays,
  ninetyDays,
  oneYear,
}

class ProfileAnalyticsWindow {
  const ProfileAnalyticsWindow({
    required this.start,
    required this.endExclusive,
    required this.previousStart,
    required this.previousEndExclusive,
  });

  final DateTime start;
  final DateTime endExclusive;
  final DateTime previousStart;
  final DateTime previousEndExclusive;

  int get dayCount => endExclusive.difference(start).inDays;
}

class ProfileAnalyticsItemStat {
  const ProfileAnalyticsItemStat({
    required this.item,
    required this.wearCount,
    required this.lastAppearance,
  });

  final ClothingItem item;
  final int wearCount;
  final DateTime? lastAppearance;
}

class ProfileAnalyticsLook {
  const ProfileAnalyticsLook({
    required this.wornAt,
    required this.items,
    this.outfitId,
    this.repeatCount = 1,
  });

  final DateTime wornAt;
  final String? outfitId;
  final List<ClothingItem> items;
  final int repeatCount;
}

class ProfileActivityBucket {
  const ProfileActivityBucket({required this.start, required this.looks});

  final DateTime start;
  final int looks;
}

class ProfileColorStat {
  const ProfileColorStat({required this.hex, required this.itemCount});

  final String hex;
  final int itemCount;
}

class ProfileAnalyticsSnapshot {
  const ProfileAnalyticsSnapshot({
    required this.range,
    required this.window,
    required this.wardrobeItemCount,
    required this.looksWorn,
    required this.uniqueItemsWorn,
    required this.utilization,
    required this.previousUtilization,
    required this.mostWornItems,
    required this.unwornItems,
    required this.recentLooks,
    required this.activityBuckets,
    required this.categoryDistribution,
    required this.styleDistribution,
    required this.colorDistribution,
    this.repeatedLook,
    this.hasWearHistory = false,
  });

  final ProfileAnalyticsRange range;
  final ProfileAnalyticsWindow window;
  final int wardrobeItemCount;
  final int looksWorn;
  final int uniqueItemsWorn;
  final double utilization;
  final double previousUtilization;
  final List<ProfileAnalyticsItemStat> mostWornItems;
  final List<ClothingItem> unwornItems;
  final ProfileAnalyticsLook? repeatedLook;
  final List<ProfileAnalyticsLook> recentLooks;
  final List<ProfileActivityBucket> activityBuckets;
  final Map<ClothingCategory, int> categoryDistribution;
  final Map<ClothingStyle, int> styleDistribution;
  final List<ProfileColorStat> colorDistribution;
  final bool hasWearHistory;

  double get utilizationDeltaPoints => utilization - previousUtilization;

  bool get hasWardrobe => wardrobeItemCount > 0;
}

class ProfileAnalyticsInput {
  const ProfileAnalyticsInput({required this.items, required this.events});

  final List<ClothingItem> items;
  final List<WearEvent> events;
}
