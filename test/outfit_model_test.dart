import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';

void main() {
  test('fromJson handles legacy generated outfit rows', () {
    final outfit = Outfit.fromJson({
      'id': 'outfit-1',
      'name': 'Legacy outfit',
      'item_ids': ['top-1', 'pants-1', 'shoes-1'],
    });

    expect(outfit.itemIds, ['top-1', 'pants-1', 'shoes-1']);
    expect(outfit.reason, isNull);
    expect(outfit.score, isNull);
    expect(outfit.selectionFactors, isEmpty);
  });

  test('fromJson parses score, reason, and selection factor lists', () {
    final outfit = Outfit.fromJson({
      'id': 'outfit-2',
      'name': 'Weather outfit',
      'itemIds': ['top-1'],
      'reason': 'Fits rain and lucky color.',
      'score': 91,
      'selection_factors': ['weather', 'lucky_color'],
    });

    expect(outfit.reason, 'Fits rain and lucky color.');
    expect(outfit.score, 91);
    expect(outfit.selectionFactors, ['weather', 'lucky_color']);
  });

  test('fromJson parses map-backed selection factors', () {
    final outfit = Outfit.fromJson({
      'id': 'outfit-3',
      'name': 'Mapped factors',
      'selection_factors': {
        'weather': true,
        'personal_color': 8,
        'ignored': false,
      },
    });

    expect(outfit.selectionFactors, ['weather', 'personal_color']);
  });
}
