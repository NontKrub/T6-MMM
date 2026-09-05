import 'user_profile.dart';
import 'wearable_asset.dart';

abstract final class AvatarAssetCatalog {
  static const femaleModelPath = 'assets/avatar/human_female_v1.glb';
  static const maleModelPath = 'assets/avatar/human_male_v1.glb';
  static const femalePosterPath = 'assets/avatar/posters/human_female.png';
  static const malePosterPath = 'assets/avatar/posters/human_male.png';

  static String modelPathFor(AvatarBodyShape bodyShape) =>
      bodyShape == AvatarBodyShape.male ? maleModelPath : femaleModelPath;

  static String posterPathFor(AvatarBodyShape bodyShape) =>
      bodyShape == AvatarBodyShape.male ? malePosterPath : femalePosterPath;
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
  });

  Map<String, dynamic> toJson({bool reduceMotion = false}) => {
    'bodyShape': bodyShape.name,
    'skinToneIndex': skinToneIndex.clamp(0, 6),
    'hairColorIndex': hairColorIndex.clamp(0, 5),
    'hairStyleIndex': hairStyleIndex.clamp(0, 5),
    'garments': garments.map((garment) => garment.toJson()).toList(),
    'animation': animation.jsonName,
    'reduceMotion': reduceMotion,
    'hasSelectedOutfit': hasSelectedOutfit,
  };
}
