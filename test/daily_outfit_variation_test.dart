import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/daily_outfit_variation.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'avoids the previous daily fingerprint when an alternative exists',
    () async {
      final preferences = await _preferences();
      final variation = DailyOutfitVariation(preferences: preferences);
      final first = _outfit('a', ['shirt', 'pants']);
      final alternative = _outfit('b', ['dress', 'shoes']);

      expect(
        await variation.choose(
          date: DateTime(2026, 9, 5),
          candidates: [first, alternative],
        ),
        first,
      );
      expect(
        await variation.choose(
          date: DateTime(2026, 9, 6),
          candidates: [first, alternative],
        ),
        alternative,
      );
    },
  );

  test('permits a repeat when there is only one valid candidate', () async {
    final preferences = await _preferences();
    final variation = DailyOutfitVariation(preferences: preferences);
    final only = _outfit('only', ['shirt']);

    await variation.choose(date: DateTime(2026, 9, 5), candidates: [only]);
    expect(
      await variation.choose(date: DateTime(2026, 9, 6), candidates: [only]),
      only,
    );
  });

  test(
    'keeps an explicitly selected outfit out of automatic replacement',
    () async {
      final preferences = await _preferences();
      final variation = DailyOutfitVariation(preferences: preferences);
      final explicit = _outfit('explicit', ['pinned']);
      final generated = _outfit('generated', ['other']);

      expect(
        await variation.choose(
          date: DateTime(2026, 9, 6),
          candidates: [generated],
          explicitSelection: explicit,
        ),
        explicit,
      );
      expect(preferences.getString(DailyOutfitVariation.dateKey), isNull);
    },
  );
}

Future<SharedPreferences> _preferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Outfit _outfit(String id, List<String> itemIds) =>
    Outfit(id: id, name: id, itemIds: itemIds);
