import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/wardrobe_provider.dart';
import 'package:mix_match_mood/core/services/wardrobe_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

class _FakeWardrobeRepository extends WardrobeRepository {
  Object? insertError;
  Object? archiveError;
  Object? wearError;
  Object? reanalyzeError;

  @override
  Future<ClothingItem> insertItem(ClothingItem item) async {
    if (insertError != null) throw insertError!;
    return item;
  }

  @override
  Future<void> archiveItem(String id) async {
    if (archiveError != null) throw archiveError!;
  }

  @override
  Future<void> recordWear({
    String? outfitId,
    required List<String> itemIds,
    String? style,
    String source = 'manual',
  }) async {
    if (wearError != null) throw wearError!;
  }

  @override
  Future<ClothingItem?> reanalyzeItem(String id) async {
    if (reanalyzeError != null) throw reanalyzeError!;
    return null;
  }
}

class _TestWardrobeNotifier extends WardrobeNotifier {
  _TestWardrobeNotifier(WardrobeRepository repository)
    : super(repository: repository);

  @override
  Future<void> load() async {}
}

void main() {
  final item = ClothingItem(
    id: 'item-1',
    name: 'Tee',
    category: ClothingCategory.top,
    imageUrl: '/tmp/tee.jpg',
  );

  test('failed insert does not publish a permanent item', () async {
    final repository = _FakeWardrobeRepository()
      ..insertError = StateError('insert failed');
    final notifier = _TestWardrobeNotifier(repository);

    await expectLater(notifier.addItem(item), throwsStateError);

    expect(notifier.state, isEmpty);
  });

  test('failed archive keeps the item visible', () async {
    final repository = _FakeWardrobeRepository()
      ..archiveError = StateError('archive failed');
    final notifier = _TestWardrobeNotifier(repository)..state = [item];

    await expectLater(notifier.removeItem(item.id), throwsStateError);

    expect(notifier.state, [item]);
  });

  test('failed wear event does not update local history state', () async {
    final repository = _FakeWardrobeRepository()
      ..wearError = StateError('wear failed');
    final notifier = _TestWardrobeNotifier(repository)..state = [item];

    await expectLater(notifier.markWorn(item.id), throwsStateError);

    expect(notifier.state.single.wearCount, 0);
    expect(notifier.state.single.lastWorn, isNull);
  });

  test('successful insert publishes the persisted item', () async {
    final notifier = _TestWardrobeNotifier(_FakeWardrobeRepository());

    await notifier.addItem(item);

    expect(notifier.state.single.id, item.id);
  });
}
