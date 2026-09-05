import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/avatar_outfit_resolver.dart';
import 'package:mix_match_mood/core/services/avatar_scene_mapper.dart';
import 'package:mix_match_mood/core/services/wearable_template_resolver.dart';
import 'package:mix_match_mood/shared/models/avatar_scene.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';
import 'package:mix_match_mood/shared/models/wearable_asset.dart';

void main() {
  test('maps wardrobe garments to a safe renderer payload', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Thai "blue" เสื้อ 👕',
      category: ClothingCategory.top,
      imageUrl: '',
      fit: ClothingFit.oversized,
      pattern: ClothingPattern.striped,
      material: ClothingMaterial.cotton,
      colorHexes: const ['#FFFFFF'],
    );
    final wearable = const WearableTemplateResolver().resolve(item);
    final look = const AvatarOutfitResolver().resolve(
      outfit: const Outfit(id: 'look-1', name: 'Daily', itemIds: ['item-1']),
      wardrobe: [item],
    );
    final scene = const AvatarSceneMapper().resolve(
      avatarType: AvatarType.human,
      bodyShape: AvatarBodyShape.female,
      skinToneIndex: 99,
      hairColorIndex: -2,
      hairStyleIndex: 7,
      outfitLook: look,
    );
    final payload = jsonDecode(jsonEncode(scene.toJson()));

    expect(wearable.templateKey, 'oversized_top');
    expect(payload['garments'][0]['template'], 'oversized_top');
    expect(payload['garments'][0]['pattern'], 'stripe');
    expect(payload['garments'][0]['color'], '#FFFFFF');
    expect(payload['garments'][0]['clothingItemId'], 'item-1');
    expect(payload['skinToneIndex'], 6);
    expect(payload['hairColorIndex'], 0);
    expect(payload['hairStyleIndex'], 5);
    expect(scene.modelPath, AvatarAssetCatalog.femaleModelPath);
  });

  test('selects the male model without changing the outfit contract', () {
    final scene = const AvatarSceneMapper().resolve(
      avatarType: AvatarType.human,
      bodyShape: AvatarBodyShape.male,
      skinToneIndex: 0,
      hairColorIndex: 5,
      hairStyleIndex: 0,
    );

    expect(scene.modelPath, AvatarAssetCatalog.maleModelPath);
    expect(scene.posterPath, AvatarAssetCatalog.malePosterPath);
    expect(scene.garments, isEmpty);
  });

  test('keeps pets on the existing fallback renderer', () {
    final scene = const AvatarSceneMapper().resolve(
      avatarType: AvatarType.dog,
      bodyShape: AvatarBodyShape.female,
      skinToneIndex: 1,
      hairColorIndex: 1,
      hairStyleIndex: 3,
    );

    expect(scene.modelPath, isEmpty);
    expect(scene.posterPath, isNull);
  });

  test('skips an unsupported wearable without crashing the scene mapper', () {
    final scene = const AvatarSceneMapper().resolve(
      avatarType: AvatarType.human,
      bodyShape: AvatarBodyShape.female,
      skinToneIndex: 1,
      hairColorIndex: 1,
      hairStyleIndex: 3,
      outfitLook: AvatarOutfitLook(
        hasSelectedOutfit: true,
        wearables: [
          WearableAsset(
            clothingItemId: 'unsupported',
            itemName: 'Unknown',
            status: WearableStatus.unsupported,
            slot: null,
            templateKey: 'unsupported',
          ),
        ],
      ),
    );

    expect(scene.garments, isEmpty);
  });

  test('maps garment materials to restrained PBR values', () {
    const mapper = AvatarMaterialMapper();

    expect(mapper.resolve('denim').roughness, .78);
    expect(mapper.resolve('leather').roughness, .32);
    expect(mapper.resolve('satin').roughness, .28);
    expect(mapper.resolve('unknown').metallic, 0);
  });

  test('keeps outfit changes tied to the real wardrobe item IDs', () {
    final wardrobe = [
      ClothingItem(
        id: 'shirt-1',
        name: 'White oversized shirt',
        category: ClothingCategory.top,
        imageUrl: '',
        fit: ClothingFit.oversized,
        colorHexes: const ['#FFFFFF'],
      ),
      ClothingItem(
        id: 'jeans-1',
        name: 'Blue wide-leg jeans',
        category: ClothingCategory.pants,
        imageUrl: '',
        silhouette: ClothingSilhouette.wideLeg,
        colorHexes: const ['#3B5E9D'],
      ),
      ClothingItem(
        id: 'sneakers-1',
        name: 'White sneakers',
        category: ClothingCategory.shoes,
        imageUrl: '',
        colorHexes: const ['#FFFFFF'],
      ),
      ClothingItem(
        id: 'tee-2',
        name: 'Black tee',
        category: ClothingCategory.top,
        imageUrl: '',
        colorHexes: const ['#111111'],
      ),
      ClothingItem(
        id: 'skirt-2',
        name: 'Black skirt',
        category: ClothingCategory.pants,
        imageUrl: '',
        subtype: 'skirt',
        colorHexes: const ['#111111'],
      ),
      ClothingItem(
        id: 'boots-2',
        name: 'Black boots',
        category: ClothingCategory.shoes,
        imageUrl: '',
        subtype: 'boot',
        colorHexes: const ['#111111'],
      ),
    ];
    const resolver = AvatarOutfitResolver();
    const mapper = AvatarSceneMapper();

    AvatarSceneState sceneFor(List<String> ids) => mapper.resolve(
      avatarType: AvatarType.human,
      bodyShape: AvatarBodyShape.female,
      skinToneIndex: 1,
      hairColorIndex: 1,
      hairStyleIndex: 3,
      outfitLook: resolver.resolve(
        outfit: Outfit(id: 'look', name: 'Look', itemIds: ids),
        wardrobe: wardrobe,
      ),
    );

    final first = sceneFor(const ['shirt-1', 'jeans-1', 'sneakers-1']);
    final second = sceneFor(const ['tee-2', 'skirt-2', 'boots-2']);

    expect(first.garments.map((garment) => garment.clothingItemId), [
      'shirt-1',
      'jeans-1',
      'sneakers-1',
    ]);
    expect(first.garments.map((garment) => garment.templateKey), [
      'oversized_top',
      'wide_leg_pants',
      'sneaker',
    ]);
    expect(second.garments.map((garment) => garment.clothingItemId), [
      'tee-2',
      'skirt-2',
      'boots-2',
    ]);
    expect(second.garments.map((garment) => garment.templateKey), [
      'regular_tee',
      'skirt',
      'boot',
    ]);
  });

  test('resolver catalog matches generated asset catalog', () {
    final catalog =
        jsonDecode(File('assets/avatar/avatar_catalog.json').readAsStringSync())
            as Map<String, dynamic>;
    final catalogTemplates = (catalog['templates'] as List).cast<String>();
    final catalogAnimations = (catalog['animations'] as List).cast<String>();

    expect(catalogTemplates.toSet(), WearableTemplateResolver.templateKeys);
    expect(
      catalogAnimations,
      containsAll(<String>['idle', 'blink', 'wave', 'look', 'outfit_reveal']),
    );
    expect(catalog['hairStyles'], 6);
    expect(catalog['skinTones'], 7);
    expect(catalog['hairColors'], 6);
  });
}
