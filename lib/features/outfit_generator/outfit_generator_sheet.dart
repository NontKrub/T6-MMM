import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/outfit_card.dart';

class OutfitGeneratorSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const OutfitGeneratorSheet({super.key, required this.ref});

  @override
  ConsumerState<OutfitGeneratorSheet> createState() =>
      _OutfitGeneratorSheetState();
}

class _OutfitGeneratorSheetState extends ConsumerState<OutfitGeneratorSheet> {
  String _selectedStyle = 'casual';
  bool _usePersonalColor = false;
  bool _useLuckyColor = false;
  bool _matchWeather = false;
  List<Outfit> _generatedOutfits = [];
  bool _loading = false;

  static const _styles = ['casual', 'work', 'formal', 'sport', 'date'];
  final _weatherMock = '☀️ Sunny · 28°C';

  Future<void> _generate() async {
    setState(() => _loading = true);
    final outfits = await ref
        .read(outfitsProvider.notifier)
        .generateBackendOutfits(
          _selectedStyle,
          ref,
          usePersonalColor: _usePersonalColor,
          useLuckyColor: _useLuckyColor,
          matchWeather: _matchWeather,
        );
    setState(() {
      _generatedOutfits = outfits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wardrobe = ref.watch(wardrobeProvider);

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1628) : const Color(0xFFF8F7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Outfit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Style chips
                  Text('Style', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _styles.map((s) {
                      final sel = _selectedStyle == s;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStyle = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.seedColor
                                : AppColors.seedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.seedColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Filters
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  _FilterToggle(
                    label: 'Use my personal color season',
                    value: _usePersonalColor,
                    onChanged: (v) => setState(() => _usePersonalColor = v),
                  ),
                  _FilterToggle(
                    label: "Today's lucky color",
                    value: _useLuckyColor,
                    onChanged: (v) => setState(() => _useLuckyColor = v),
                  ),
                  _FilterToggle(
                    label: 'Match weather · $_weatherMock',
                    value: _matchWeather,
                    onChanged: (v) => setState(() => _matchWeather = v),
                  ),
                  const SizedBox(height: 24),
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(_loading ? 'Generating...' : 'Generate'),
                    ),
                  ),
                  // Generated results
                  if (_generatedOutfits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._generatedOutfits.asMap().entries.map((e) {
                      final outfit = e.value;
                      final items = outfit.itemIds
                          .map(
                            (id) =>
                                wardrobe.where((i) => i.id == id).firstOrNull,
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
                          )
                          .animate(delay: (e.key * 100).ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.seedColor,
            ),
          ],
        ),
      ),
    );
  }
}
