import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_theme.dart';
import '../../../core/theme/app_radii.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/wardrobe_image.dart';

class OutfitFlatlay extends StatelessWidget {
  const OutfitFlatlay({
    super.key,
    required this.items,
    required this.semanticLabel,
    this.onItemTap,
  });

  final List<ClothingItem> items;
  final String semanticLabel;
  final ValueChanged<ClothingItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: brand.neutralSurface,
          borderRadius: AppRadii.emphasizedCardBorder,
          border: Border.all(color: brand.subtleBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              for (final item in items)
                _FlatlayItem(
                  item: item,
                  placement: OutfitFlatlayPlacement.forCategory(item.category),
                  canvasSize: constraints.biggest,
                  onTap: onItemTap == null ? null : () => onItemTap!(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class OutfitFlatlayPlacement {
  const OutfitFlatlayPlacement(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  static OutfitFlatlayPlacement forCategory(ClothingCategory category) {
    switch (category) {
      case ClothingCategory.dress:
        return const OutfitFlatlayPlacement(.27, .08, .46, .70);
      case ClothingCategory.top:
        return const OutfitFlatlayPlacement(.30, .06, .38, .36);
      case ClothingCategory.outerwear:
        return const OutfitFlatlayPlacement(.12, .08, .36, .42);
      case ClothingCategory.pants:
        return const OutfitFlatlayPlacement(.12, .39, .42, .47);
      case ClothingCategory.shoes:
        return const OutfitFlatlayPlacement(.48, .67, .39, .23);
      case ClothingCategory.bag:
        return const OutfitFlatlayPlacement(.67, .36, .23, .29);
      case ClothingCategory.hat:
        return const OutfitFlatlayPlacement(.65, .08, .23, .20);
      case ClothingCategory.accessory:
        return const OutfitFlatlayPlacement(.70, .20, .17, .16);
      case ClothingCategory.unknown:
        return const OutfitFlatlayPlacement(.63, .49, .20, .22);
    }
  }
}

class _FlatlayItem extends StatelessWidget {
  const _FlatlayItem({
    required this.item,
    required this.placement,
    required this.canvasSize,
    required this.onTap,
  });

  final ClothingItem item;
  final OutfitFlatlayPlacement placement;
  final Size canvasSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: AppRadii.compactBorder,
      child: WardrobeImage(item: item, fit: BoxFit.contain),
    );
    return Positioned(
      left: placement.left * canvasSize.width,
      top: placement.top * canvasSize.height,
      width: placement.width * canvasSize.width,
      height: placement.height * canvasSize.height,
      child: onTap == null
          ? ExcludeSemantics(child: child)
          : Semantics(
              button: true,
              label: item.name,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadii.compactBorder,
                  child: child,
                ),
              ),
            ),
    );
  }
}
