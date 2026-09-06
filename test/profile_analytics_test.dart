import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/profile_analytics_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/outfit_intelligence.dart';
import 'package:mix_match_mood/shared/models/profile_analytics.dart';

ClothingItem _item(
  String id, {
  ClothingCategory category = ClothingCategory.top,
  DateTime? createdAt,
  List<ClothingStyle> styles = const [],
  List<String> colors = const [],
}) => ClothingItem(
  id: id,
  name: id,
  category: category,
  imageUrl: '',
  createdAt: createdAt,
  styles: styles,
  colorHexes: colors,
);

WearEvent _event(List<String> ids, DateTime wornAt, {String? outfitId}) =>
    WearEvent(itemIds: ids, wornAt: wornAt, outfitId: outfitId);

void main() {
  final now = DateTime(2026, 9, 6, 12);

  test('calculates deterministic wear, repetition, mix, and tie ordering', () {
    final input = ProfileAnalyticsInput(
      items: [
        _item(
          'a',
          createdAt: DateTime(2026, 8, 1),
          styles: [ClothingStyle.casual],
          colors: ['#3366FF'],
        ),
        _item(
          'b',
          category: ClothingCategory.pants,
          createdAt: DateTime(2026, 8, 1),
          styles: [ClothingStyle.minimal],
          colors: ['#3366FF'],
        ),
        _item(
          'c',
          category: ClothingCategory.shoes,
          createdAt: DateTime(2026, 9, 1),
          styles: [ClothingStyle.casual],
          colors: ['#FFFFFF'],
        ),
        _item('d', createdAt: DateTime(2026, 7, 1)),
      ],
      events: [
        _event(['a', 'b'], DateTime(2026, 9, 2)),
        _event(['b', 'a'], DateTime(2026, 9, 3)),
        _event(['c'], DateTime(2026, 9, 4)),
        _event(['missing', 'a'], DateTime(2026, 9, 5)),
        _event(['a'], DateTime(2026, 8, 5)),
      ],
    );

    final snapshot = ProfileAnalyticsCalculator.calculate(
      input,
      range: ProfileAnalyticsRange.thirtyDays,
      now: now,
    );

    expect(snapshot.wardrobeItemCount, 4);
    expect(snapshot.looksWorn, 2);
    expect(snapshot.uniqueItemsWorn, 3);
    expect(snapshot.utilization, 75);
    expect(snapshot.previousUtilization, 25);
    expect(snapshot.mostWornItems.map((entry) => entry.item.id), [
      'a',
      'b',
      'c',
    ]);
    expect(snapshot.mostWornItems.first.wearCount, 3);
    expect(snapshot.repeatedLook?.items.map((item) => item.id), ['a', 'b']);
    expect(snapshot.repeatedLook?.repeatCount, 2);
    expect(snapshot.unwornItems.map((item) => item.id), ['d']);
    expect(snapshot.categoryDistribution[ClothingCategory.top], 2);
    expect(snapshot.styleDistribution[ClothingStyle.casual], 2);
    expect(snapshot.colorDistribution.first.hex, '#3366FF');
  });

  test(
    'uses half-open windows and excludes a new item from unworn results',
    () {
      final input = ProfileAnalyticsInput(
        items: [_item('new', createdAt: DateTime(2026, 8, 20))],
        events: [
          _event(['new'], DateTime(2026, 8, 7, 23, 59)),
          _event(['new'], DateTime(2026, 8, 8)),
        ],
      );

      final snapshot = ProfileAnalyticsCalculator.calculate(
        input,
        range: ProfileAnalyticsRange.thirtyDays,
        now: now,
      );

      expect(snapshot.window.start, DateTime(2026, 8, 8));
      expect(snapshot.window.endExclusive, DateTime(2026, 9, 7));
      expect(snapshot.uniqueItemsWorn, 1);
      expect(snapshot.unwornItems, isEmpty);
    },
  );
}
