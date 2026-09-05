enum WearableStatus { pending, processing, ready, unsupported, failed }

enum AvatarSlot { head, top, outerwear, bottom, dress, shoes, bag, accessory }

/// Rendering data derived from a wardrobe item.
///
/// [ClothingItem] remains the source of wardrobe truth. This model contains
/// only the representation needed by an avatar renderer and can therefore be
/// replaced without changing wardrobe persistence or outfit generation.
class WearableAsset {
  final String clothingItemId;
  final String itemName;
  final WearableStatus status;
  final AvatarSlot? slot;
  final String templateKey;
  final String? modelPath;
  final String? texturePath;
  final String? baseColorHex;
  final String? materialVariant;
  final Map<String, double> fitParameters;
  final int assetVersion;
  final bool isFallback;

  const WearableAsset({
    required this.clothingItemId,
    required this.itemName,
    required this.status,
    required this.slot,
    required this.templateKey,
    this.modelPath,
    this.texturePath,
    this.baseColorHex,
    this.materialVariant,
    this.fitParameters = const {},
    this.assetVersion = 1,
    this.isFallback = false,
  });

  bool get isUsable => slot != null && status == WearableStatus.ready;
}
