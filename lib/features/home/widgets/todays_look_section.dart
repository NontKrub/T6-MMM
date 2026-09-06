import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/widgets/mmm_gradient_button.dart';
import '../../../shared/widgets/mmm_secondary_button.dart';
import 'outfit_flatlay.dart';

class TodaysLookSection extends StatefulWidget {
  const TodaysLookSection({
    super.key,
    required this.outfits,
    required this.itemsForOutfit,
    required this.onGenerate,
    required this.onSelect,
    required this.onOpenItem,
    required this.title,
    required this.tryAnotherLabel,
    required this.generateLabel,
    required this.whyThisWorksLabel,
    required this.wearLabel,
  });

  final List<Outfit> outfits;
  final List<ClothingItem> Function(Outfit) itemsForOutfit;
  final VoidCallback onGenerate;
  final ValueChanged<Outfit> onSelect;
  final ValueChanged<ClothingItem> onOpenItem;
  final String title;
  final String tryAnotherLabel;
  final String generateLabel;
  final String whyThisWorksLabel;
  final String wearLabel;

  @override
  State<TodaysLookSection> createState() => _TodaysLookSectionState();
}

class _TodaysLookSectionState extends State<TodaysLookSection> {
  late final PageController _controller;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = MmmBrandTheme.of(context);
    if (widget.outfits.isEmpty) {
      return _NoLook(
        title: widget.title,
        label: widget.generateLabel,
        onGenerate: widget.onGenerate,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 430,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.outfits.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final outfit = widget.outfits[index];
              final items = widget.itemsForOutfit(outfit);
              final style = outfit.style?.trim();
              final explanation = outfit.reason?.trim().isNotEmpty == true
                  ? outfit.reason!.trim()
                  : outfit.selectionFactors.isEmpty
                  ? null
                  : outfit.selectionFactors.first.replaceAll('_', ' ');
              return Semantics(
                label: 'Look ${index + 1} of ${widget.outfits.length}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (style?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          style!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Expanded(
                      child: OutfitFlatlay(
                        items: items,
                        semanticLabel: items.isEmpty
                            ? outfit.name
                            : '${outfit.name}: ${items.map((item) => item.name).join(', ')}',
                        onItemTap: widget.onOpenItem,
                      ),
                    ),
                    if (explanation?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.whyThisWorksLabel,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(explanation!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.outfits.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Look ${_page + 1} of ${widget.outfits.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.outfits.length,
                (index) => Container(
                  width: index == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? brand.primaryGradient.colors.first
                        : brand.subtleBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: MmmSecondaryButton(
                label: widget.tryAnotherLabel,
                icon: Icons.refresh_rounded,
                onPressed: widget.outfits.length == 1
                    ? widget.onGenerate
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MmmGradientButton(
                label: widget.wearLabel,
                icon: Icons.check_rounded,
                onPressed: () => widget.onSelect(widget.outfits[_page]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoLook extends StatelessWidget {
  const _NoLook({
    required this.title,
    required this.label,
    required this.onGenerate,
  });

  final String title;
  final String label;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      MmmGradientButton(
        label: label,
        icon: Icons.auto_awesome_rounded,
        onPressed: onGenerate,
      ),
    ],
  );
}
