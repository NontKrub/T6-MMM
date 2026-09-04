import 'package:flutter/material.dart';
import '../../shared/models/clothing_item.dart';
import 'mmm_choice_chip.dart';

class CategoryTabs extends StatelessWidget {
  final ClothingCategory? selected;
  final ValueChanged<ClothingCategory?> onSelect;

  const CategoryTabs({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final all = [null, ...ClothingCategory.values];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = all[i];
          final label = cat?.label ?? 'All';
          return MmmChoiceChip(
            label: label,
            selected: cat == selected,
            onSelected: (_) => onSelect(cat),
          );
        },
      ),
    );
  }
}
