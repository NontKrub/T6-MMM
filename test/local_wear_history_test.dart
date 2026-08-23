import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/core/services/outfit_repository.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists normalized outfit combinations', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalAccountRepository();

    await repository.recordWearCombination(['top', 'pants']);
    await repository.recordWearCombination(['pants', 'top']);

    expect(await repository.fetchWearCombinations(), [
      ['pants', 'top'],
      ['pants', 'top'],
    ]);
  });

  test(
    'persists guest preference events separately from wear history',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalAccountRepository();
      final selectedAt = DateTime.utc(2026, 8, 23);

      await repository.recordPreferenceEvent(
        LocalPreferenceEvent(
          style: 'casual',
          itemIds: const ['top', 'pants'],
          tags: const ['denim', 'casual'],
          colors: const ['blue'],
          source: 'generated',
          selectedAt: selectedAt,
        ),
      );

      final events = await LocalAccountRepository().fetchPreferenceEvents();
      expect(events.single.style, 'casual');
      expect(events.single.tags, ['denim', 'casual']);
      expect(events.single.colors, ['blue']);
      expect(events.single.selectedAt, selectedAt);
      expect(await repository.fetchWearCombinations(), isEmpty);
    },
  );

  test('outfit repository records guest selections locally', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    final repository = OutfitRepository(local: local);

    await repository.recordPreferenceEvent(
      outfit: const Outfit(
        id: 'generated',
        name: 'Generated',
        itemIds: ['top', 'pants', 'shoes'],
        style: 'casual',
      ),
      itemIds: const ['top', 'pants', 'shoes'],
      tags: const ['denim'],
      colors: const ['blue'],
      source: 'generated',
    );

    final event = (await local.fetchPreferenceEvents()).single;
    expect(event.itemIds, ['top', 'pants', 'shoes']);
    expect(event.source, 'generated');
  });
}
