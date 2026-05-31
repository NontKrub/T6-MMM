import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../shared/models/clothing_item.dart';

class MissingPiecesScreen extends ConsumerWidget {
  const MissingPiecesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobe = ref.watch(wardrobeProvider);
    final recommendations = _generateRecommendations(wardrobe);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your wardrobe needs…',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Curated to fill the gaps in your collection',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                itemCount: recommendations.length,
                itemBuilder: (context, i) =>
                    _RecommendationCard(rec: recommendations[i])
                        .animate(delay: (i * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Recommendation> _generateRecommendations(List<ClothingItem> wardrobe) {
    final recs = <_Recommendation>[];
    final categories = wardrobe.map((i) => i.category).toSet();

    if (!categories.contains(ClothingCategory.hat)) {
      recs.add(
        _Recommendation(
          category: ClothingCategory.hat,
          title: 'A versatile cap or beanie',
          reason:
              'You have no headwear — a neutral hat completes casual looks and protects from the sun.',
          suggestion: 'Try a wool bucket hat in tan or black.',
          priority: 'Nice to have',
          priorityColor: AppColors.colorHats,
        ),
      );
    }

    final tops = wardrobe
        .where((i) => i.category == ClothingCategory.top)
        .length;
    final pants = wardrobe
        .where((i) => i.category == ClothingCategory.pants)
        .length;

    if (tops > 3 && pants < 2) {
      recs.add(
        _Recommendation(
          category: ClothingCategory.pants,
          title: 'A second pair of trousers',
          reason:
              'You have $tops tops but only $pants bottom(s) — your outfit variety is limited.',
          suggestion:
              'Slim-fit chinos in khaki or grey expand your options by 3x.',
          priority: 'High impact',
          priorityColor: AppColors.seedColor,
        ),
      );
    }

    recs.addAll([
      _Recommendation(
        category: ClothingCategory.top,
        title: 'A quality white shirt',
        reason:
            'A crisp white shirt works with every bottom you own and dresses up or down.',
        suggestion:
            'Oxford cloth button-down or poplin — COS, Uniqlo, or A.P.C.',
        priority: 'Essential',
        priorityColor: const Color(0xFF10B981),
      ),
      _Recommendation(
        category: ClothingCategory.shoes,
        title: 'Smart casual loafers',
        reason:
            'Bridges the gap between sneakers and formal shoes for 80% of occasions.',
        suggestion:
            'Penny loafers in tan suede or leather. Tod\'s, Clarks, or Mango.',
        priority: 'Versatile',
        priorityColor: AppColors.colorShoes,
      ),
      _Recommendation(
        category: ClothingCategory.accessory,
        title: 'A minimal leather wallet',
        reason: 'Elevates the perceived quality of any outfit when visible.',
        suggestion:
            'Slim card holder in black or dark brown. Bellroy, Fjällräven.',
        priority: 'Nice to have',
        priorityColor: AppColors.colorAccessories,
      ),
    ]);

    return recs;
  }
}

class _Recommendation {
  final ClothingCategory category;
  final String title;
  final String reason;
  final String suggestion;
  final String priority;
  final Color priorityColor;

  const _Recommendation({
    required this.category,
    required this.title,
    required this.reason,
    required this.suggestion,
    required this.priority,
    required this.priorityColor,
  });
}

class _RecommendationCard extends StatefulWidget {
  final _Recommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.rec;

    return GlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rec.category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  rec.category.icon,
                  color: rec.category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rec.priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rec.priority,
                        style: TextStyle(
                          color: rec.priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Browse button
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.seedColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text('Browse', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          // Why expandable
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Why?',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 14,
                          color: Colors.grey.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Text(
              rec.reason,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.suggestion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentGold,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
