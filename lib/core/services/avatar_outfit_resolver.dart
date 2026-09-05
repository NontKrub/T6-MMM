import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/wearable_asset.dart';
import 'wearable_template_resolver.dart';

class AvatarOutfitLook {
  final String? baseModelPath;
  final List<WearableAsset> wearables;
  final List<String> suppressedItemIds;
  final List<String> missingItemIds;
  final List<String> fallbackItemIds;
  final String semanticsLabel;

  const AvatarOutfitLook({
    this.baseModelPath,
    this.wearables = const [],
    this.suppressedItemIds = const [],
    this.missingItemIds = const [],
    this.fallbackItemIds = const [],
    this.semanticsLabel = 'Avatar with no selected outfit.',
  });

  String? get primaryMaterialVariant {
    for (final wearable in wearables) {
      if (wearable.materialVariant != null) return wearable.materialVariant;
    }
    return null;
  }

  bool get hasRenderableModel =>
      baseModelPath != null && baseModelPath!.trim().isNotEmpty;
}

class AvatarOutfitResolver {
  const AvatarOutfitResolver({
    this.templates = const WearableTemplateResolver(),
  });

  final WearableTemplateResolver templates;

  AvatarOutfitLook resolve({
    required Outfit? outfit,
    required Iterable<ClothingItem> wardrobe,
    Map<String, WearableAsset> wearableAssets = const {},
    String? baseModelPath,
  }) {
    if (outfit == null) return const AvatarOutfitLook();

    final itemsById = {for (final item in wardrobe) item.id: item};
    final missing = <String>[];
    final fallback = <String>[];
    final candidates = <WearableAsset>[];

    for (final itemId in outfit.itemIds) {
      final item = itemsById[itemId];
      if (item == null) {
        missing.add(itemId);
        continue;
      }

      final supplied = wearableAssets[item.id];
      final wearable = supplied ?? templates.resolve(item);
      if (supplied != null && supplied.status != WearableStatus.ready) {
        candidates.add(templates.fallbackFor(item, status: supplied.status));
        fallback.add(item.id);
      } else if (wearable.slot != null &&
          wearable.status == WearableStatus.ready) {
        candidates.add(wearable);
      } else {
        missing.add(item.id);
      }
    }

    final selected = <AvatarSlot, WearableAsset>{};
    final suppressed = <String>[];
    final hasDress = candidates.any(
      (wearable) => wearable.slot == AvatarSlot.dress,
    );

    for (final wearable in candidates) {
      final slot = wearable.slot;
      if (slot == null) {
        missing.add(wearable.clothingItemId);
        continue;
      }
      if (hasDress && (slot == AvatarSlot.top || slot == AvatarSlot.bottom)) {
        suppressed.add(wearable.clothingItemId);
        continue;
      }
      if (selected.containsKey(slot)) {
        suppressed.add(wearable.clothingItemId);
        continue;
      }
      selected[slot] = wearable;
    }

    final ordered = <WearableAsset>[];
    for (final slot in AvatarSlot.values) {
      final wearable = selected[slot];
      if (wearable != null) ordered.add(wearable);
    }

    final names = ordered.map((wearable) => wearable.itemName).toList();
    final semantics = names.isEmpty
        ? 'Avatar with no renderable garments.'
        : 'Avatar wearing ${names.join(', ')}.';

    return AvatarOutfitLook(
      baseModelPath: baseModelPath,
      wearables: ordered,
      suppressedItemIds: suppressed,
      missingItemIds: missing,
      fallbackItemIds: fallback,
      semanticsLabel: semantics,
    );
  }
}
