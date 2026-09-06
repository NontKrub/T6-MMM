import 'user_profile.dart';
import 'garment_visual_fingerprint.dart';
import 'wearable_asset.dart';

enum AvatarAssetVersion { v1, v2 }

class AvatarAssetCatalogVersion {
  final String femaleModelPath;
  final String maleModelPath;
  final String femalePosterPath;
  final String malePosterPath;

  const AvatarAssetCatalogVersion({
    required this.femaleModelPath,
    required this.maleModelPath,
    required this.femalePosterPath,
    required this.malePosterPath,
  });
}

abstract final class AvatarAssetCatalog {
  static const activeVersion = AvatarAssetVersion.v1;

  static const v1 = AvatarAssetCatalogVersion(
    femaleModelPath: 'assets/avatar/human_female_v1.glb',
    maleModelPath: 'assets/avatar/human_male_v1.glb',
    femalePosterPath: 'assets/avatar/posters/human_female.png',
    malePosterPath: 'assets/avatar/posters/human_male.png',
  );

  static const v2 = AvatarAssetCatalogVersion(
    femaleModelPath: 'assets/avatar/human_female_v2.glb',
    maleModelPath: 'assets/avatar/human_male_v2.glb',
    femalePosterPath: 'assets/avatar/posters/human_female_v2.png',
    malePosterPath: 'assets/avatar/posters/human_male_v2.png',
  );

  static const femaleModelPath = 'assets/avatar/human_female_v1.glb';
  static const maleModelPath = 'assets/avatar/human_male_v1.glb';
  static const femalePosterPath = 'assets/avatar/posters/human_female.png';
  static const malePosterPath = 'assets/avatar/posters/human_male.png';

  static AvatarAssetCatalogVersion forVersion(AvatarAssetVersion version) =>
      switch (version) {
        AvatarAssetVersion.v1 => v1,
        AvatarAssetVersion.v2 => v2,
      };

  static String modelPathFor(
    AvatarBodyShape bodyShape, {
    AvatarAssetVersion? version,
  }) {
    final catalog = forVersion(version ?? activeVersion);
    return bodyShape == AvatarBodyShape.male
        ? catalog.maleModelPath
        : catalog.femaleModelPath;
  }

  static String posterPathFor(
    AvatarBodyShape bodyShape, {
    AvatarAssetVersion? version,
  }) {
    final catalog = forVersion(version ?? activeVersion);
    return bodyShape == AvatarBodyShape.male
        ? catalog.malePosterPath
        : catalog.femalePosterPath;
  }
}

enum AvatarSceneAnimation { idle, blink, wave, look, outfitReveal }

extension AvatarSceneAnimationJson on AvatarSceneAnimation {
  String get jsonName => switch (this) {
    AvatarSceneAnimation.idle => 'idle',
    AvatarSceneAnimation.blink => 'blink',
    AvatarSceneAnimation.wave => 'wave',
    AvatarSceneAnimation.look => 'look',
    AvatarSceneAnimation.outfitReveal => 'outfit_reveal',
  };
}

class AvatarRenderedGarment {
  final String clothingItemId;
  final AvatarSlot slot;
  final String templateKey;
  final String? colorHex;
  final String? texturePath;
  final String? textureDigest;
  final String? textureDataUri;
  final GarmentTextureKind textureKind;
  final List<double>? frontGraphicRect;
  final String materialKey;
  final String patternKey;
  final double roughness;
  final double metallic;
  final bool isFallback;

  const AvatarRenderedGarment({
    required this.clothingItemId,
    required this.slot,
    required this.templateKey,
    this.colorHex,
    this.texturePath,
    this.textureDigest,
    this.textureDataUri,
    this.textureKind = GarmentTextureKind.solid,
    this.frontGraphicRect,
    this.materialKey = 'synthetic',
    this.patternKey = 'solid',
    this.roughness = 0.65,
    this.metallic = 0,
    this.isFallback = false,
  });

  Map<String, dynamic> toJson() => {
    'clothingItemId': clothingItemId,
    'slot': slot.name,
    'template': templateKey,
    'color': colorHex,
    'texture': texturePath,
    'textureDigest': textureDigest,
    'textureDataUri': textureDataUri,
    'textureKind': textureKind.name,
    'frontGraphicRect': frontGraphicRect,
    'material': materialKey,
    'pattern': patternKey,
    'roughness': roughness,
    'metallic': metallic,
    'fallback': isFallback,
  };
}

class AvatarSceneState {
  final String modelPath;
  final String? posterPath;
  final AvatarBodyShape bodyShape;
  final int skinToneIndex;
  final int hairColorIndex;
  final int hairStyleIndex;
  final List<AvatarRenderedGarment> garments;
  final AvatarSceneAnimation animation;
  final bool hasSelectedOutfit;
  final String semanticsLabel;
  final int schemaVersion;
  final bool texturesEnabled;

  const AvatarSceneState({
    required this.modelPath,
    this.posterPath,
    required this.bodyShape,
    required this.skinToneIndex,
    required this.hairColorIndex,
    required this.hairStyleIndex,
    this.garments = const [],
    this.animation = AvatarSceneAnimation.idle,
    this.hasSelectedOutfit = false,
    this.semanticsLabel = 'Avatar',
    this.schemaVersion = 2,
    this.texturesEnabled = false,
  });

  Map<String, dynamic> toJson({bool reduceMotion = false}) => {
    'schemaVersion': schemaVersion,
    'bodyShape': bodyShape.name,
    'skinToneIndex': skinToneIndex.clamp(0, 6),
    'hairColorIndex': hairColorIndex.clamp(0, 5),
    'hairStyleIndex': hairStyleIndex.clamp(0, 5),
    'garments': garments.map((garment) => garment.toJson()).toList(),
    'animation': animation.jsonName,
    'reduceMotion': reduceMotion,
    'hasSelectedOutfit': hasSelectedOutfit,
    'texturesEnabled': texturesEnabled,
  };
}
