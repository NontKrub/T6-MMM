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
    final headwear = _items(wardrobe, ClothingCategory.hat, context);
    final extras = _balancedExtras([
      _items(wardrobe, ClothingCategory.bag, context),
      _items(wardrobe, ClothingCategory.accessory, context),
    ]);
    final dresses = _items(wardrobe, ClothingCategory.dress, context);
    final candidates = <OutfitCandidate>[];
    final hasBasic = tops.isNotEmpty && bottoms.isNotEmpty;
    final hasDress = dresses.isNotEmpty;
    final basicPotential = hasBasic
        ? tops.length *
              bottoms.length *
              shoes.length *
              (outerwear.length + 1) *
              (headwear.length + 1) *
              (extras.length + 1)
        : 0;
    final dressPotential = hasDress
        ? dresses.length *
              shoes.length *
              (outerwear.length + 1) *
              (headwear.length + 1) *
              (extras.length + 1)
        : 0;
    var basicLimit = basicPotential < maxCandidates
        ? basicPotential
        : maxCandidates;
    var dressLimit = dressPotential < maxCandidates
        ? dressPotential
        : maxCandidates;
    if (hasBasic && hasDress) {
      var dressReservation = maxCandidates ~/ 4;
      if (dressReservation == 0) dressReservation = 1;
      if (dressReservation >= maxCandidates) {
        dressReservation = maxCandidates - 1;
      }
      final basicReservation = maxCandidates - dressReservation;
      basicLimit = basicPotential < basicReservation
          ? basicPotential
          : basicReservation;
      dressLimit = dressPotential < dressReservation
          ? dressPotential
          : dressReservation;

      var remaining = maxCandidates - basicLimit - dressLimit;
      final basicRoom = basicPotential - basicLimit;
      final basicExtra = remaining < basicRoom ? remaining : basicRoom;
      basicLimit += basicExtra;
      remaining -= basicExtra;
      final dressRoom = dressPotential - dressLimit;
      final dressExtra = remaining < dressRoom ? remaining : dressRoom;
      dressLimit += dressExtra;
    }

    if (hasBasic && basicLimit > 0) {
      var basicCount = 0;
      basic:
      for (final top in tops) {
        for (final bottom in bottoms) {
          for (final shoe in shoes) {
            for (final layer in [null, ...outerwear]) {
              for (final hat in [null, ...headwear]) {
                for (final extra in [null, ...extras]) {
                  candidates.add(
                    _candidate(
                      top: top,
                      bottom: bottom,
                      shoes: shoe,
                      outerwear: layer,
                      headwear: hat,
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
    }

    if (hasDress && dressLimit > 0) {
      var dressCount = 0;
      dress:
      for (final dress in dresses) {
        for (final shoe in shoes) {
          for (final layer in [null, ...outerwear]) {
            for (final hat in [null, ...headwear]) {
              for (final extra in [null, ...extras]) {
                candidates.add(
                  _candidate(
                    onePiece: dress,
                    shoes: shoe,
                    outerwear: layer,
                    headwear: hat,
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
          ..sort(_comparePracticality);
    return items.take(maxItemsPerCategory).toList();
  }

  List<ClothingItem> _balancedExtras(List<List<ClothingItem>> groups) {
    final extras = <ClothingItem>[];
    for (var index = 0; extras.length < maxAccessories; index++) {
      var added = false;
      for (final group in groups) {
        if (index >= group.length) continue;
        extras.add(group[index]);
        added = true;
        if (extras.length == maxAccessories) return extras;
      }
      if (!added) break;
    }
    return extras;
  }

  int _comparePracticality(ClothingItem a, ClothingItem b) {
    final wear = a.wearCount.compareTo(b.wearCount);
    if (wear != 0) return wear;

    if (a.lastWorn == null && b.lastWorn != null) return -1;
    if (a.lastWorn != null && b.lastWorn == null) return 1;
    if (a.lastWorn != null && b.lastWorn != null) {
      final worn = a.lastWorn!.compareTo(b.lastWorn!);
      if (worn != 0) return worn;
    }

    return a.id.compareTo(b.id);
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
    ClothingItem? headwear,
    ClothingItem? extra,
  }) {
    final items = [
      ?onePiece,
      ?top,
      ?bottom,
      ?outerwear,
      ?shoes,
      ?headwear,
      ?extra,
    ];
    final key = items.map((item) => item.id).toList()..sort();
    return OutfitCandidate(
      id: 'candidate_${key.join('|')}',
      top: top,
      bottom: bottom,
      shoes: shoes,
      outerwear: outerwear,
      onePiece: onePiece,
      accessories: [?headwear, ?extra],
    );
  }
}
