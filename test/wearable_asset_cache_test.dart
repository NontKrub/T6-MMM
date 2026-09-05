import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/wearable_asset_cache.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/wearable_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rebuilds and reads a derived wearable locally', () async {
    final item = _item(colorHexes: const ['#FFFFFF']);
    final cache = WearableAssetCache();

    final rebuilt = await cache.rebuild(item);
    final loaded = await cache.get(item);

    expect(rebuilt.templateKey, 'oversized_top');
    expect(loaded?.clothingItemId, item.id);
    expect(loaded?.patternKey, 'solid');
  });

  test('invalidates when the wardrobe representation changes', () async {
    final item = _item(colorHexes: const ['#FFFFFF']);
    final changed = item.copyWith(colorHexes: const ['#111111']);
    final cache = WearableAssetCache();
    await cache.rebuild(item);

    expect(await cache.get(changed), isNull);
    await cache.invalidate(item);
    expect(await cache.get(item), isNull);
  });

  test('removes every derived version when an item is deleted', () async {
    final item = _item(colorHexes: const ['#FFFFFF']);
    final changed = item.copyWith(colorHexes: const ['#111111']);
    final cache = WearableAssetCache();
    await cache.save(
      item,
      const WearableAsset(
        clothingItemId: 'item-1',
        itemName: 'Top',
        status: WearableStatus.ready,
        slot: AvatarSlot.top,
        templateKey: 'oversized_top',
      ),
    );
    await cache.save(
      changed,
      const WearableAsset(
        clothingItemId: 'item-1',
        itemName: 'Top',
        status: WearableStatus.ready,
        slot: AvatarSlot.top,
        templateKey: 'oversized_top',
      ),
    );

    await cache.remove(item.id);

    expect(await cache.get(item), isNull);
    expect(await cache.get(changed), isNull);
  });

  test('serializes concurrent derived writes', () async {
    final item = _item(colorHexes: const ['#FFFFFF']);
    final changed = item.copyWith(colorHexes: const ['#111111']);
    final cache = WearableAssetCache();
    const asset = WearableAsset(
      clothingItemId: 'item-1',
      itemName: 'Top',
      status: WearableStatus.ready,
      slot: AvatarSlot.top,
      templateKey: 'oversized_top',
    );

    await Future.wait([cache.save(item, asset), cache.save(changed, asset)]);

    expect(await cache.get(item), isNotNull);
    expect(await cache.get(changed), isNotNull);
  });
}

ClothingItem _item({required List<String> colorHexes}) => ClothingItem(
  id: 'item-1',
  name: 'Oversized top',
  category: ClothingCategory.top,
  imageUrl: '',
  fit: ClothingFit.oversized,
  colorHexes: colorHexes,
);
