import '../../shared/models/avatar_scene.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/wearable_asset.dart';
import 'avatar_outfit_resolver.dart';

class AvatarMaterialProfile {
  final double roughness;
  final double metallic;

  const AvatarMaterialProfile({
    required this.roughness,
    required this.metallic,
  });
}

class AvatarMaterialMapper {
  const AvatarMaterialMapper();

  AvatarMaterialProfile resolve(String? materialKey) => switch (materialKey) {
    'leather' => const AvatarMaterialProfile(roughness: 0.32, metallic: 0.02),
    'satin' ||
    'silk' => const AvatarMaterialProfile(roughness: 0.28, metallic: 0),
    'denim' => const AvatarMaterialProfile(roughness: 0.78, metallic: 0),
    'wool' ||
    'knit' => const AvatarMaterialProfile(roughness: 0.88, metallic: 0),
    'cotton' ||
    'linen' => const AvatarMaterialProfile(roughness: 0.72, metallic: 0),
    _ => const AvatarMaterialProfile(roughness: 0.65, metallic: 0),
  };
}

class AvatarSceneMapper {
  const AvatarSceneMapper({this.materials = const AvatarMaterialMapper()});

  final AvatarMaterialMapper materials;

  AvatarSceneState resolve({
    required AvatarType avatarType,
    required AvatarBodyShape bodyShape,
    required int skinToneIndex,
    required int hairColorIndex,
    required int hairStyleIndex,
    AvatarOutfitLook? outfitLook,
  }) {
    final human = avatarType == AvatarType.human;
    final wearables = outfitLook?.wearables ?? const <WearableAsset>[];
    return AvatarSceneState(
      modelPath: human ? AvatarAssetCatalog.modelPathFor(bodyShape) : '',
      posterPath: human ? AvatarAssetCatalog.posterPathFor(bodyShape) : null,
      bodyShape: bodyShape,
      skinToneIndex: skinToneIndex,
      hairColorIndex: hairColorIndex,
      hairStyleIndex: hairStyleIndex,
      garments: wearables
          .where((wearable) => wearable.slot != null)
          .map(_mapGarment)
          .toList(growable: false),
      hasSelectedOutfit: outfitLook?.hasSelectedOutfit ?? false,
      semanticsLabel: outfitLook?.semanticsLabel ?? 'Avatar',
    );
  }

  AvatarRenderedGarment _mapGarment(WearableAsset wearable) {
    final profile = materials.resolve(wearable.materialVariant);
    return AvatarRenderedGarment(
      clothingItemId: wearable.clothingItemId,
      slot: wearable.slot!,
      templateKey: wearable.templateKey,
      colorHex: wearable.baseColorHex,
      texturePath: wearable.texturePath,
      materialKey: wearable.materialVariant ?? 'synthetic',
      patternKey: wearable.patternKey,
      roughness: profile.roughness,
      metallic: profile.metallic,
      isFallback: wearable.isFallback,
    );
  }
}
