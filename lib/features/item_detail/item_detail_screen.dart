import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/outfit_card.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobe = ref.watch(wardrobeProvider);
    final item = wardrobe.where((i) => i.id == itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item not found')),
        body: const Center(child: Text('This item has been removed.')),
      );
    }

    final allOutfits = ref.watch(outfitsProvider);
    final outfitsWithItem = allOutfits
        .where((o) => o.itemIds.contains(item.id))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'item_${item.id}',
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: item.category.color.withOpacity(0.2),
                    child: Icon(
                      item.category.icon,
                      size: 80,
                      color: item.category.color,
                    ),
                  ),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                  iconSize: 20,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(context, ref, item),
                    iconSize: 20,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name & Brand
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (item.brand != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.brand!,
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.7),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.category.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.category.icon,
                            size: 14,
                            color: item.category.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.category.label,
                            style: TextStyle(
                              color: item.category.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 16),
                // Tags
                if (item.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.seedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: AppColors.seedColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 20),
                // Wear stats
                _WearStatsCard(
                  item: item,
                ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
                const SizedBox(height: 20),
                // Outfits with this item
                if (outfitsWithItem.isNotEmpty) ...[
                  Text(
                    'Outfits featuring this item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...outfitsWithItem.map((outfit) {
                    final items = outfit.itemIds
                        .map(
                          (id) => wardrobe.where((i) => i.id == id).firstOrNull,
                        )
                        .whereType<ClothingItem>()
                        .toList();
                    return OutfitCard(
                      outfit: outfit,
                      items: items,
                      onWear: () {
                        ref
                            .read(outfitsProvider.notifier)
                            .selectOutfit(outfit, ref);
                        Navigator.pop(context);
                      },
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms);
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ClothingItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(wardrobeProvider.notifier).removeItem(item.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _WearStatsCard extends StatelessWidget {
  final ClothingItem item;
  const _WearStatsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _Stat(label: 'Times worn', value: '${item.wearCount}x'),
          _Divider(),
          _Stat(
            label: 'Last worn',
            value: item.lastWorn != null
                ? _formatDate(item.lastWorn!)
                : 'Never',
          ),
          _Divider(),
          _Stat(
            label: 'Cost per wear',
            value: item.wearCount > 0 ? '—' : 'Not worn yet',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${diff ~/ 7}w ago';
    return '${diff ~/ 30}mo ago';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
