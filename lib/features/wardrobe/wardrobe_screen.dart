import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/mmm_empty_state.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/wardrobe_image.dart';
import 'add_item_sheet.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  ClothingCategory? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allItems = ref.watch(wardrobeProvider);
    final filtered = _searchQuery.isNotEmpty
        ? ref.read(wardrobeProvider.notifier).search(_searchQuery)
        : _selectedCategory == null
        ? allItems
        : allItems.where((item) => item.category == _selectedCategory).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.wardrobeTitle ?? 'Wardrobe',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n?.wardrobeItemCount(allItems.length) ??
                              '${allItems.length} items',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n?.commonAddItem ?? 'Add item',
                    child: IconButton.filled(
                      onPressed: _showAddItem,
                      icon: const Icon(Icons.add_rounded),
                      tooltip: l10n?.commonAddItem ?? 'Add item',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.screen,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText:
                      l10n?.wardrobeSearchHint ??
                      'Search by name, brand, or tag…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          tooltip: l10n?.commonClearSearch ?? 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CategoryFilter(
              selected: _selectedCategory,
              onSelect: (category) =>
                  setState(() => _selectedCategory = category),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: filtered.isEmpty
                  ? _WardrobeEmptyState(
                      hasSearch: _searchQuery.isNotEmpty,
                      onAdd: _showAddItem,
                    )
                  : ListView.separated(
                      key: const Key('wardrobe-list'),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _WardrobeItemCard(
                        key: ValueKey('wardrobe-item-${filtered[index].id}'),
                        item: filtered[index],
                        onTap: () =>
                            context.push('/item/${filtered[index].id}'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItem() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddItemSheet(),
  );
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelect});

  final ClothingCategory? selected;
  final ValueChanged<ClothingCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = <ClothingCategory?>[null, ...ClothingCategory.values];
    final brand = MmmBrandTheme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          final l10n = AppLocalizations.of(context);
          final allLabel = l10n?.wardrobeAll ?? 'All';
          final label = category == null
              ? allLabel
              : _localizedCategoryLabel(l10n, category);
          return Semantics(
            button: true,
            selected: isSelected,
            label: label,
            child: Material(
              color: isSelected
                  ? brand.subtleAccentSurface
                  : brand.raisedSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.compactBorder,
                side: BorderSide(
                  color: isSelected
                      ? brand.primaryGradient.colors.first
                      : brand.subtleBorder,
                ),
              ),
              child: InkWell(
                onTap: () => onSelect(category),
                borderRadius: AppRadii.compactBorder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? brand.primaryGradient.colors.first
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WardrobeItemCard extends StatelessWidget {
  const _WardrobeItemCard({super.key, required this.item, required this.onTap});

  final ClothingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final categoryLabel = _localizedCategoryLabel(l10n, item.category);
    final brandLabel = item.brand?.trim();
    final semanticsLabel = brandLabel == null || brandLabel.isEmpty
        ? '${item.name}, $categoryLabel'
        : '${item.name}, $brandLabel, $categoryLabel';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: MmmSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.xs),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadii.controlBorder,
                child: ColoredBox(
                  color: brand.neutralSurface,
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: WardrobeImage(item: item, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (brandLabel != null && brandLabel.isNotEmpty)
                      Text(
                        brandLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _localizedCategoryLabel(
  AppLocalizations? l10n,
  ClothingCategory category,
) => switch (category) {
  ClothingCategory.hat => l10n?.clothingCategoryHat ?? category.label,
  ClothingCategory.top => l10n?.clothingCategoryTop ?? category.label,
  ClothingCategory.pants => l10n?.clothingCategoryPants ?? category.label,
  ClothingCategory.shoes => l10n?.clothingCategoryShoes ?? category.label,
  ClothingCategory.outerwear =>
    l10n?.clothingCategoryOuterwear ?? category.label,
  ClothingCategory.dress => l10n?.clothingCategoryDress ?? category.label,
  ClothingCategory.bag => l10n?.clothingCategoryBag ?? category.label,
  ClothingCategory.accessory =>
    l10n?.clothingCategoryAccessory ?? category.label,
  ClothingCategory.unknown => l10n?.clothingCategoryUnknown ?? category.label,
};

class _WardrobeEmptyState extends StatelessWidget {
  const _WardrobeEmptyState({required this.hasSearch, required this.onAdd});

  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (hasSearch) {
      return MmmEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n?.wardrobeNoResults ?? 'No items found',
        message:
            l10n?.wardrobeNoResultsHint ??
            'Try a different name, brand, or tag.',
      );
    }
    return MmmEmptyState(
      icon: Icons.auto_awesome_outlined,
      title: l10n?.wardrobeEmpty ?? 'Your wardrobe is empty',
      message:
          l10n?.wardrobeEmptyMessage ??
          'Your wardrobe is ready for its first piece.',
      actionLabel: l10n?.wardrobeEmptyAdd ?? 'Add an item',
      onAction: onAdd,
    );
  }
}
