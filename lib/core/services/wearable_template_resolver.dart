import '../../shared/models/clothing_item.dart';
import '../../shared/models/wearable_asset.dart';

class WearableTemplateResolver {
  const WearableTemplateResolver();

  static const templateKeys = <String>{
    'hat',
    'regular_tee',
    'fitted_top',
    'oversized_top',
    'shirt_blouse',
    'sweater_hoodie',
    'jacket',
    'blazer',
    'coat',
    'regular_pants',
    'slim_pants',
    'wide_leg_pants',
    'shorts',
    'skirt',
    'straight_dress',
    'a_line_dress',
    'sneaker',
    'dress_shoe',
    'boot',
    'bag',
    'accessory',
  };

  WearableAsset resolve(ClothingItem item) {
    final slot = _slotFor(item.category);
    if (slot == null) {
      return WearableAsset(
        clothingItemId: item.id,
        itemName: item.name,
        status: WearableStatus.unsupported,
        slot: null,
        templateKey: 'unsupported',
        baseColorHex: _baseColor(item),
      );
    }

    return WearableAsset(
      clothingItemId: item.id,
      itemName: item.name,
      status: WearableStatus.ready,
      slot: slot,
      templateKey: _templateFor(item, slot),
      baseColorHex: _baseColor(item),
      patternKey: _patternKey(item),
      materialVariant: item.material == ClothingMaterial.unknown
          ? null
          : item.material.name,
      fitParameters: _fitParameters(item),
    );
  }

  WearableAsset fallbackFor(
    ClothingItem item, {
    WearableStatus status = WearableStatus.failed,
  }) {
    final resolved = resolve(item);
    return WearableAsset(
      clothingItemId: item.id,
      itemName: item.name,
      status: status,
      slot: resolved.slot,
      templateKey: resolved.templateKey,
      baseColorHex: resolved.baseColorHex,
      materialVariant: resolved.materialVariant,
      patternKey: resolved.patternKey,
      fitParameters: resolved.fitParameters,
      isFallback: true,
    );
  }

  AvatarSlot? _slotFor(ClothingCategory category) => switch (category) {
    ClothingCategory.hat => AvatarSlot.head,
    ClothingCategory.top => AvatarSlot.top,
    ClothingCategory.outerwear => AvatarSlot.outerwear,
    ClothingCategory.pants => AvatarSlot.bottom,
    ClothingCategory.dress => AvatarSlot.dress,
    ClothingCategory.shoes => AvatarSlot.shoes,
    ClothingCategory.bag => AvatarSlot.bag,
    ClothingCategory.accessory => AvatarSlot.accessory,
    ClothingCategory.unknown => null,
  };

  String _templateFor(ClothingItem item, AvatarSlot slot) {
    final subtype = _normalized(item.subtype);
    return switch (slot) {
      AvatarSlot.head => 'hat',
      AvatarSlot.top => _topTemplate(item, subtype),
      AvatarSlot.outerwear => _outerwearTemplate(item, subtype),
      AvatarSlot.bottom => _bottomTemplate(item, subtype),
      AvatarSlot.dress =>
        item.silhouette == ClothingSilhouette.aLine
            ? 'a_line_dress'
            : 'straight_dress',
      AvatarSlot.shoes => _shoeTemplate(item, subtype),
      AvatarSlot.bag => 'bag',
      AvatarSlot.accessory => 'accessory',
    };
  }

  String _topTemplate(ClothingItem item, String subtype) {
    if (_containsAny(subtype, ['hoodie', 'sweater', 'knit'])) {
      return 'sweater_hoodie';
    }
    if (_containsAny(subtype, ['shirt', 'blouse'])) return 'shirt_blouse';
    if (item.fit == ClothingFit.oversized ||
        item.silhouette == ClothingSilhouette.oversized) {
      return 'oversized_top';
    }
    if (item.fit == ClothingFit.slim ||
        item.silhouette == ClothingSilhouette.fitted) {
      return 'fitted_top';
    }
    return 'regular_tee';
  }

  String _outerwearTemplate(ClothingItem item, String subtype) {
    if (_containsAny(subtype, ['coat']) ||
        item.formality == ClothingFormality.formal) {
      return 'coat';
    }
    if (_containsAny(subtype, ['blazer'])) return 'blazer';
    return 'jacket';
  }

  String _bottomTemplate(ClothingItem item, String subtype) {
    if (_containsAny(subtype, ['short'])) return 'shorts';
    if (_containsAny(subtype, ['skirt'])) return 'skirt';
    if (item.fit == ClothingFit.wide ||
        item.silhouette == ClothingSilhouette.wideLeg) {
      return 'wide_leg_pants';
    }
    if (item.fit == ClothingFit.slim ||
        item.silhouette == ClothingSilhouette.slim) {
      return 'slim_pants';
    }
    return 'regular_pants';
  }

  String _shoeTemplate(ClothingItem item, String subtype) {
    if (_containsAny(subtype, ['boot'])) return 'boot';
    if (item.formality == ClothingFormality.formal ||
        _containsAny(subtype, ['dress', 'loafer', 'heel'])) {
      return 'dress_shoe';
    }
    return 'sneaker';
  }

  Map<String, double> _fitParameters(ClothingItem item) => {
    'fit': switch (item.fit) {
      ClothingFit.slim => .25,
      ClothingFit.regular => .5,
      ClothingFit.relaxed => .65,
      ClothingFit.oversized => .85,
      ClothingFit.cropped => .45,
      ClothingFit.wide => .8,
      ClothingFit.unknown => .5,
    },
    'silhouette': switch (item.silhouette) {
      ClothingSilhouette.fitted => .25,
      ClothingSilhouette.slim => .3,
      ClothingSilhouette.regular => .5,
      ClothingSilhouette.straight => .5,
      ClothingSilhouette.relaxed => .65,
      ClothingSilhouette.oversized => .85,
      ClothingSilhouette.cropped => .4,
      ClothingSilhouette.wideLeg => .85,
      ClothingSilhouette.aLine => .75,
      ClothingSilhouette.unknown => .5,
    },
  };

  String? _baseColor(ClothingItem item) {
    if (item.colorHexes.isNotEmpty) return item.colorHexes.first;
    final color = item.color?.trim().toUpperCase();
    if (color == null || color.isEmpty) return null;
    final normalized = color.startsWith('#') ? color : '#$color';
    return RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized) ? normalized : null;
  }

  String _patternKey(ClothingItem item) => switch (item.pattern) {
    ClothingPattern.striped => 'stripe',
    ClothingPattern.checked => 'plaid',
    ClothingPattern.floral => 'floral',
    ClothingPattern.graphic => 'graphic',
    ClothingPattern.textured => 'textured',
    _ => 'solid',
  };

  String _normalized(String? value) =>
      (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[_\s-]+'), '');

  bool _containsAny(String value, Iterable<String> terms) =>
      terms.any((term) => value.contains(term));
}
