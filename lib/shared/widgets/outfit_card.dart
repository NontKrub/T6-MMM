import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/clothing_item.dart';
import '../../core/theme/app_colors.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final List<ClothingItem> items;
  final VoidCallback? onWear;
  final bool isSelected;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.items,
    this.onWear,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1A1628) : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.seedColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Item thumbnails
            SizedBox(
              height: 64,
              width: 160,
              child: Stack(
                children: [
                  for (int i = 0; i < items.length && i < 4; i++)
                    Positioned(
                      left: i * 32.0,
                      child: _ItemThumb(item: items[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Name & style
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (outfit.style != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.seedColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        outfit.style!,
                        style: TextStyle(
                          color: AppColors.seedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Wear button
            if (onWear != null)
              FilledButton(
                onPressed: onWear,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Wear', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  final ClothingItem item;
  const _ItemThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: item.category.color.withOpacity(0.2),
            child: Icon(
              item.category.icon,
              size: 20,
              color: item.category.color,
            ),
          ),
        ),
      ),
    );
  }
}
