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
    final candidates = <OutfitCandidate>[];

    if (tops.isNotEmpty && bottoms.isNotEmpty) {
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
                if (candidates.length >= maxCandidates) return candidates;
              }
            }
          }
        }
      }
    }

    final dresses = _items(wardrobe, ClothingCategory.dress, context);
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
            if (candidates.length >= maxCandidates) return candidates;
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
  ) =>
      wardrobe
          .where(
            (item) =>
                item.category == category && _allowedByContext(item, context),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

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
