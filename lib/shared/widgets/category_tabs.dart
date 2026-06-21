import 'package:flutter/material.dart';
import '../../shared/models/clothing_item.dart';
import '../../core/theme/app_colors.dart';

class CategoryTabs extends StatelessWidget {
  final ClothingCategory? selected;
  final ValueChanged<ClothingCategory?> onSelect;

  const CategoryTabs({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final all = [null, ...ClothingCategory.values];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = all[i];
          final isSelected = cat == selected;
          final color = cat?.color ?? AppColors.accentGold;
          final label = cat?.label ?? 'All';

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
