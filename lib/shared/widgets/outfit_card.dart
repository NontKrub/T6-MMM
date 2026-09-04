import 'package:flutter/material.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/clothing_item.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'wardrobe_image.dart';

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
    final theme = Theme.of(context);
    final brand = MmmBrandTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.selection),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardBorder,
        color: brand.raisedSurface,
        border: Border.all(
          color: isSelected
              ? brand.primaryGradient.colors.first
              : brand.subtleBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            const SizedBox(width: AppSpacing.sm),
            // Name & style
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          outfit.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (outfit.score != null) ...[
                        const SizedBox(width: 8),
                        _ScorePill(score: outfit.score!),
                      ],
                    ],
                  ),
                  if (outfit.reason?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      outfit.reason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.72,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (outfit.style != null ||
                      outfit.selectionFactors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (outfit.style != null) _FactorChip(outfit.style!),
                        ...outfit.selectionFactors.take(4).map(_FactorChip.new),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Wear button
            if (onWear != null)
              FilledButton(
                onPressed: onWear,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(64, 44),
                ),
                child: Text(
                  l10n?.outfitWear ?? 'Wear',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: brand.subtleAccentSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        score.round().toString(),
        style: TextStyle(
          color: brand.primaryGradient.colors.first,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final String label;
  const _FactorChip(this.label);

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: brand.subtleAccentSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: brand.primaryGradient.colors.first,
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
        child: WardrobeImage(item: item),
      ),
    );
  }
}
