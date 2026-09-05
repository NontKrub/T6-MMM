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
  final String patternKey;
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
    this.patternKey = 'solid',
    this.fitParameters = const {},
    this.assetVersion = 1,
    this.isFallback = false,
  });

  bool get isUsable => slot != null && status == WearableStatus.ready;

  factory WearableAsset.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'failed';
    final slotName = json['slot'] as String?;
    final status = WearableStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => WearableStatus.failed,
    );
    final slot = slotName == null
        ? null
        : AvatarSlot.values.firstWhere(
            (value) => value.name == slotName,
            orElse: () => AvatarSlot.accessory,
          );
    final fit = json['fitParameters'];
    return WearableAsset(
      clothingItemId: json['clothingItemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      status: status,
      slot: slot,
      templateKey: json['templateKey'] as String? ?? 'unsupported',
      modelPath: json['modelPath'] as String?,
      texturePath: json['texturePath'] as String?,
      baseColorHex: json['baseColorHex'] as String?,
      materialVariant: json['materialVariant'] as String?,
      patternKey: json['patternKey'] as String? ?? 'solid',
      fitParameters: fit is Map
          ? fit.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            )
          : const {},
      assetVersion: (json['assetVersion'] as num?)?.toInt() ?? 1,
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'clothingItemId': clothingItemId,
    'itemName': itemName,
    'status': status.name,
    'slot': slot?.name,
    'templateKey': templateKey,
    'modelPath': modelPath,
    'texturePath': texturePath,
    'baseColorHex': baseColorHex,
    'materialVariant': materialVariant,
    'patternKey': patternKey,
    'fitParameters': fitParameters,
    'assetVersion': assetVersion,
    'isFallback': isFallback,
  };
}
