import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/outfit_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/widgets/outfit_card.dart';
import '../../shared/widgets/wardrobe_image.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wardrobe = ref.watch(wardrobeProvider);
    final item = wardrobe.where((entry) => entry.id == itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.itemNotFound ?? 'Item not found')),
        body: Center(
          child: Text(
            l10n?.itemNotFoundMessage ?? 'This item has been removed.',
          ),
        ),
      );
    }

    final outfits = ref
        .watch(outfitsProvider)
        .where((outfit) => outfit.itemIds.contains(item.id))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'item_${item.id}',
                child: WardrobeImage(item: item),
              ),
            ),
            leading: _ImageAction(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<_ItemAction>(
                tooltip: l10n?.itemMoreActions ?? 'More actions',
                icon: const _ImageActionIcon(Icons.more_horiz_rounded),
                onSelected: (action) {
                  if (action == _ItemAction.delete) {
                    _confirmDelete(context, ref, item, l10n);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _ItemAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: MmmBrandTheme.of(context).destructive,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n?.itemDeleteConfirm ?? 'Remove'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ItemHeader(item: item),
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: item.tags
                        .map((tag) => _Tag(tag: tag))
                        .toList(growable: false),
                  ),
                ],
                if (item.analysisStatus == AnalysisStatus.failed ||
                    item.analysisStatus == AnalysisStatus.partial) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AnalysisNotice(item: item, l10n: l10n),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('item-retry-analysis'),
                    onPressed: () => _retryAnalysis(context, ref, item),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n?.itemRetryAnalysis ?? 'Retry analysis'),
                  ),
                ],
                if (item.colorHexes.isNotEmpty ||
                    item.pattern != ClothingPattern.unknown ||
                    item.silhouette != ClothingSilhouette.unknown) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Details(item: item, l10n: l10n),
                ],
                const SizedBox(height: AppSpacing.xl),
                _WearStatsCard(item: item, l10n: l10n),
                if (outfits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n?.itemOutfitsTitle ?? 'Outfits featuring this item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...outfits.map((outfit) {
                    final items = outfit.itemIds
                        .map(
                          (id) => wardrobe
                              .where((wardrobeItem) => wardrobeItem.id == id)
                              .firstOrNull,
                        )
                        .whereType<ClothingItem>()
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: OutfitCard(
                        outfit: outfit,
                        items: items,
                        onWear: () {
                          ref
                              .read(outfitsProvider.notifier)
                              .selectOutfit(outfit, ref);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryAnalysis(
    BuildContext context,
    WidgetRef ref,
    ClothingItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(wardrobeProvider.notifier).reanalyzeItem(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.itemAnalysisUpdated ?? 'Analysis updated.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.itemAnalysisRetryFailed ??
                'Could not retry analysis. Try again.',
          ),
        ),
      );
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ClothingItem item,
    AppLocalizations? l10n,
  ) {
    MmmDialog.show<void>(
      context: context,
      title: Text(l10n?.itemDeleteTitle ?? 'Remove Item'),
      content: Text(
        l10n?.itemDeleteMessage(item.name) ??
            'Remove "${item.name}" from your wardrobe?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.itemDeleteCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(wardrobeProvider.notifier).removeItem(item.id);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: MmmBrandTheme.of(context).destructive,
          ),
          child: Text(l10n?.itemDeleteConfirm ?? 'Remove'),
        ),
      ],
    );
  }
}

enum _ItemAction { delete }

class _ImageAction extends StatelessWidget {
  const _ImageAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xs),
    child: Material(
      color: MmmBrandTheme.of(context).raisedSurface.withValues(alpha: .88),
      borderRadius: AppRadii.compactBorder,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    ),
  );
}

class _ImageActionIcon extends StatelessWidget {
  const _ImageActionIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
    color: MmmBrandTheme.of(context).raisedSurface.withValues(alpha: .88),
    borderRadius: AppRadii.compactBorder,
    child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20)),
  );
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
            if (item.brand != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.brand!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      _CategoryLabel(item: item),
    ],
  );
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: item.category.color.withValues(alpha: .15),
      borderRadius: AppRadii.compactBorder,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.category.icon, size: 16, color: item.category.color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          item.category.label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: brand.neutralSurface,
        borderRadius: AppRadii.compactBorder,
        border: Border.all(color: brand.subtleBorder),
      ),
      child: Text(tag, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _AnalysisNotice extends StatelessWidget {
  const _AnalysisNotice({required this.item, required this.l10n});

  final ClothingItem item;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final failed = item.analysisStatus == AnalysisStatus.failed;
    final brand = MmmBrandTheme.of(context);
    return MmmSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: brand.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failed
                  ? (l10n?.itemAnalysisFailed ??
                        'Analysis failed. Your item is still saved.')
                  : (l10n?.itemAnalysisPartial ??
                        'Some details may be incomplete.'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.item, required this.l10n});

  final ClothingItem item;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) => MmmSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.itemDetails ?? 'Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (item.colorHexes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n?.itemColors ?? 'Colors',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: item.colorHexes.map(_ColorToken.new).toList(),
          ),
        ],
        if (item.pattern != ClothingPattern.unknown ||
            item.silhouette != ClothingSilhouette.unknown) ...[
          const SizedBox(height: AppSpacing.md),
          if (item.pattern != ClothingPattern.unknown)
            _DetailRow(
              label: l10n?.itemPattern ?? 'Pattern',
              value: item.pattern.name,
            ),
          if (item.silhouette != ClothingSilhouette.unknown)
            _DetailRow(
              label: l10n?.itemSilhouette ?? 'Silhouette',
              value: item.silhouette.value,
            ),
        ],
      ],
    ),
  );
}

class _ColorToken extends StatelessWidget {
  const _ColorToken(this.hex);

  final String hex;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: brand.neutralSurface,
        borderRadius: AppRadii.compactBorder,
        border: Border.all(color: brand.subtleBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _colorFromHex(hex),
              shape: BoxShape.circle,
              border: Border.all(color: brand.subtleBorder),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(hex, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Color _colorFromHex(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? Colors.transparent : Color(0xFF000000 | parsed);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _WearStatsCard extends StatelessWidget {
  const _WearStatsCard({required this.item, this.l10n});

  final ClothingItem item;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) => MmmSurfaceCard(
    child: Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        _Stat(
          label: l10n?.itemStatsTimesWorn ?? 'Times worn',
          value: '${item.wearCount}x',
        ),
        _Stat(
          label: l10n?.itemStatsLastWorn ?? 'Last worn',
          value: item.lastWorn == null
              ? l10n?.itemStatsNever ?? 'Never'
              : _formatDate(item.lastWorn!),
        ),
        _Stat(
          label: l10n?.itemStatsCostPerWear ?? 'Cost per wear',
          value: item.wearCount > 0
              ? '—'
              : l10n?.itemStatsNotWornYet ?? 'Not worn yet',
        ),
      ],
    ),
  );

  String _formatDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) {
      return l10n?.itemStatsToday ?? 'Today';
    }
    if (days == 1) {
      return l10n?.itemStatsYesterday ?? 'Yesterday';
    }
    if (days < 7) {
      return l10n?.itemStatsDaysAgo(days) ?? '$days days ago';
    }
    if (days < 30) {
      return l10n?.itemStatsWeeksAgo(days ~/ 7) ?? '${days ~/ 7}w ago';
    }
    return l10n?.itemStatsMonthsAgo(days ~/ 30) ?? '${days ~/ 30}mo ago';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
