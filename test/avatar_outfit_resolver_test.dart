import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/avatar_outfit_resolver.dart';
import 'package:mix_match_mood/core/services/wearable_template_resolver.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';
import 'package:mix_match_mood/shared/models/wearable_asset.dart';

void main() {
  const templates = WearableTemplateResolver();
  const resolver = AvatarOutfitResolver(templates: templates);

  test(
    'maps clothing intelligence to a template without changing the item',
    () {
      final item = _item(
        'top-1',
        'Oversized shirt',
        ClothingCategory.top,
        fit: ClothingFit.oversized,
        colorHexes: const ['#FFFFFF'],
      );

      final wearable = templates.resolve(item);

      expect(wearable.slot, AvatarSlot.top);
      expect(wearable.templateKey, 'oversized_top');
      expect(wearable.baseColorHex, '#FFFFFF');
      expect(wearable.status, WearableStatus.ready);
      expect(item.category, ClothingCategory.top);
    },
  );

  test('resolves outfit IDs into deterministic garment layers', () {
    final outfit = Outfit(
      id: 'look-1',
      name: 'Dress look',
      itemIds: const ['dress-1', 'top-1', 'pants-1', 'shoes-1'],
    );
    final look = resolver.resolve(
      outfit: outfit,
      wardrobe: [
        _item('dress-1', 'Black dress', ClothingCategory.dress),
        _item('top-1', 'White top', ClothingCategory.top),
        _item('pants-1', 'Blue pants', ClothingCategory.pants),
        _item('shoes-1', 'White sneakers', ClothingCategory.shoes),
      ],
    );

    expect(look.wearables.map((wearable) => wearable.slot), [
      AvatarSlot.dress,
      AvatarSlot.shoes,
    ]);
    expect(look.suppressedItemIds, containsAll(<String>['top-1', 'pants-1']));
    expect(look.missingItemIds, isEmpty);
    expect(look.semanticsLabel, contains('Black dress'));
  });

  test('keeps one item per slot and reports unknown outfit IDs', () {
    final look = resolver.resolve(
      outfit: const Outfit(
        id: 'look-2',
        name: 'Duplicate top',
        itemIds: ['top-1', 'top-2', 'missing'],
      ),
      wardrobe: [
        _item('top-1', 'First top', ClothingCategory.top),
        _item('top-2', 'Second top', ClothingCategory.top),
      ],
    );

    expect(look.wearables.single.itemName, 'First top');
    expect(look.suppressedItemIds, ['top-2']);
    expect(look.missingItemIds, ['missing']);
  });

  test('falls back to a category template when wearable processing fails', () {
    final item = _item(
      'pants-1',
      'Wide jeans',
      ClothingCategory.pants,
      silhouette: ClothingSilhouette.wideLeg,
    );
    final look = resolver.resolve(
      outfit: const Outfit(
        id: 'look-3',
        name: 'Fallback look',
        itemIds: ['pants-1'],
      ),
      wardrobe: [item],
      wearableAssets: {
        'pants-1': const WearableAsset(
          clothingItemId: 'pants-1',
          itemName: 'Wide jeans',
          status: WearableStatus.failed,
          slot: AvatarSlot.bottom,
          templateKey: 'remote_pants',
        ),
      },
    );

    expect(look.fallbackItemIds, ['pants-1']);
    expect(look.wearables.single.isFallback, isTrue);
    expect(look.wearables.single.templateKey, 'wide_leg_pants');
    expect(look.wearables.single.status, WearableStatus.failed);
  });
}

ClothingItem _item(
  String id,
  String name,
  ClothingCategory category, {
  ClothingFit fit = ClothingFit.unknown,
  ClothingSilhouette silhouette = ClothingSilhouette.unknown,
  String? subtype,
  List<String> colorHexes = const [],
}) => ClothingItem(
  id: id,
  name: name,
  category: category,
  imageUrl: '',
  fit: fit,
  silhouette: silhouette,
  subtype: subtype,
  colorHexes: colorHexes,
);
