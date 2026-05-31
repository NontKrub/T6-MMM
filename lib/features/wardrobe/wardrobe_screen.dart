import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/category_tabs.dart';
import '../../shared/widgets/clothing_item_card.dart';
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
  Widget build(BuildContext context) {
    final allItems = ref.watch(wardrobeProvider);

    List<ClothingItem> filtered = _searchQuery.isNotEmpty
        ? ref.read(wardrobeProvider.notifier).search(_searchQuery)
        : (_selectedCategory != null
              ? allItems.where((i) => i.category == _selectedCategory).toList()
              : allItems);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wardrobe',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${allItems.length} items',
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, brand, or tag…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            // Category tabs
            CategoryTabs(
              selected: _selectedCategory,
              onSelect: (cat) => setState(() => _selectedCategory = cat),
            ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            // Grid
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(hasSearch: _searchQuery.isNotEmpty)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          ClothingItemCard(
                                item: filtered[i],
                                onTap: () =>
                                    context.push('/item/${filtered[i].id}'),
                              )
                              .animate(delay: (i * 50).ms)
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                                duration: 300.ms,
                              ),
                    ),
            ),
          ],
        ),
      ),
      // Upload FAB (bottom-left)
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 68),
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddItemSheet(),
          ),
          backgroundColor: AppColors.seedColor,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.checkroom_outlined,
            size: 56,
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'No items found' : 'Your wardrobe is empty',
            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 15),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 6),
            Text(
              'Tap + to add your first item',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
