import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';

class OutfitCandidateGenerator {
  const OutfitCandidateGenerator({
    this.maxItemsPerCategory = 12,
    this.maxCandidates = 200,
    this.maxAccessories = 4,
  });

  final int maxItemsPerCategory;
  final int maxCandidates;
  final int maxAccessories;

  List<OutfitCandidate> generate(
    List<ClothingItem> wardrobe, {
    OutfitContext? context,
  }) {
    if (maxItemsPerCategory <= 0 || maxCandidates <= 0) return const [];

    final tops = _items(wardrobe, ClothingCategory.top, context);
    final bottoms = _items(wardrobe, ClothingCategory.pants, context);
    final shoes = _items(wardrobe, ClothingCategory.shoes, context);
    if (shoes.isEmpty) return const [];

    final outerwear = _items(wardrobe, ClothingCategory.outerwear, context);
    final extras = [
      ..._items(wardrobe, ClothingCategory.hat, context),
      ..._items(wardrobe, ClothingCategory.bag, context),
      ..._items(wardrobe, ClothingCategory.accessory, context),
    ].take(maxAccessories).toList();
    final dresses = _items(wardrobe, ClothingCategory.dress, context);
    final candidates = <OutfitCandidate>[];
    final hasBasic = tops.isNotEmpty && bottoms.isNotEmpty;
    final hasDress = dresses.isNotEmpty;
    var basicLimit = maxCandidates;
    var dressLimit = maxCandidates;
    if (hasBasic && hasDress) {
      basicLimit = (maxCandidates * 3) ~/ 4;
      if (basicLimit == 0) basicLimit = 1;
      if (basicLimit >= maxCandidates) basicLimit = maxCandidates - 1;
      dressLimit = maxCandidates - basicLimit;
    }

    if (hasBasic && basicLimit > 0) {
      var basicCount = 0;
      basic:
      for (final top in tops) {
        for (final bottom in bottoms) {
          for (final shoe in shoes) {
            for (final layer in [null, ...outerwear]) {
              for (final extra in [null, ...extras]) {
                candidates.add(
                  _candidate(
                    top: top,
                    bottom: bottom,
                    shoes: shoe,
                    outerwear: layer,
                    extra: extra,
                  ),
                );
                basicCount++;
                if (basicCount >= basicLimit) break basic;
              }
            }
          }
        }
      }
    }

    if (hasDress && dressLimit > 0) {
      var dressCount = 0;
      dress:
      for (final dress in dresses) {
        for (final shoe in shoes) {
          for (final layer in [null, ...outerwear]) {
            for (final extra in [null, ...extras]) {
              candidates.add(
                _candidate(
                  onePiece: dress,
                  shoes: shoe,
                  outerwear: layer,
                  extra: extra,
                ),
              );
              dressCount++;
              if (dressCount >= dressLimit) break dress;
            }
          }
        }
      }
    }
    return candidates;
  }

  List<ClothingItem> _items(
    List<ClothingItem> wardrobe,
    ClothingCategory category,
    OutfitContext? context,
  ) {
    final items =
        wardrobe
            .where(
              (item) =>
                  item.category == category && _allowedByContext(item, context),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    return items.take(maxItemsPerCategory).toList();
  }

  bool _allowedByContext(ClothingItem item, OutfitContext? context) {
    final weather = context?.weather;
    if (weather == null) return true;
    final warmth = item.warmthLevel;
    if (warmth != null && weather.temperatureC >= 32 && warmth > .95) {
      return false;
    }
    if (warmth != null && weather.temperatureC < 12 && warmth < .05) {
      return false;
    }
    if (weather.raining && item.category == ClothingCategory.shoes) {
      final tokens = [
        ...item.tags,
        item.subtype ?? item.name,
      ].join(' ').toLowerCase();
      if (tokens.contains('open') || tokens.contains('sandal')) return false;
    }
    return true;
  }

  OutfitCandidate _candidate({
    ClothingItem? top,
    ClothingItem? bottom,
    ClothingItem? shoes,
    ClothingItem? outerwear,
    ClothingItem? onePiece,
    ClothingItem? extra,
  }) {
    final items = [?onePiece, ?top, ?bottom, ?outerwear, ?shoes, ?extra];
    final key = items.map((item) => item.id).toList()..sort();
    return OutfitCandidate(
      id: 'candidate_${key.join('|')}',
      top: top,
      bottom: bottom,
      shoes: shoes,
      outerwear: outerwear,
      onePiece: onePiece,
      accessories: extra == null ? const [] : [extra],
    );
  }
}
