import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/services/mock_data.dart';
import '../services/outfit_repository.dart';
import 'wardrobe_provider.dart';

final outfitsProvider = StateNotifierProvider<OutfitNotifier, List<Outfit>>((
  ref,
) {
  return OutfitNotifier();
});

final currentOutfitProvider = StateProvider<Outfit?>((ref) => null);

final generatedOutfitsProvider = StateProvider<List<Outfit>>((ref) => []);

class OutfitNotifier extends StateNotifier<List<Outfit>> {
  OutfitNotifier() : super(MockData.outfits) {
    load();
  }

  final _repository = OutfitRepository();

  Future<void> load() async {
    try {
      final outfits = await _repository.fetchOutfits();
      if (outfits.isNotEmpty) state = outfits;
    } catch (_) {}
  }

  void selectOutfit(Outfit outfit, WidgetRef ref) {
    ref.read(currentOutfitProvider.notifier).state = outfit;
    ref
        .read(wardrobeProvider.notifier)
        .markOutfitWorn(
          outfitId: outfit.id,
          itemIds: outfit.itemIds,
          style: outfit.style,
        );
  }

  List<Outfit> generateOutfits(String style, WidgetRef ref) {
    final wardrobe = ref.read(wardrobeProvider);
    // Mock generation: filter by style tag, build combinations
    final tops = wardrobe
        .where(
          (i) =>
              i.category == ClothingCategory.top &&
              (style == 'all' || i.tags.contains(style)),
        )
        .toList();
    final pants = wardrobe
        .where(
          (i) =>
              i.category == ClothingCategory.pants &&
              (style == 'all' || i.tags.contains(style)),
        )
        .toList();
    final shoes = wardrobe
        .where((i) => i.category == ClothingCategory.shoes)
        .toList();
    final accessories = wardrobe
        .where((i) => i.category == ClothingCategory.accessory)
        .toList();

    if (tops.isEmpty || pants.isEmpty || shoes.isEmpty) return [];

    final generated = <Outfit>[];
    for (var i = 0; i < 3 && i < tops.length; i++) {
      generated.add(
        Outfit(
          id: 'gen_$i',
          name: 'Generated Look ${i + 1}',
          itemIds: [
            tops[i % tops.length].id,
            pants[i % pants.length].id,
            shoes[i % shoes.length].id,
            if (accessories.isNotEmpty) accessories[i % accessories.length].id,
          ],
          style: style,
        ),
      );
    }

    ref.read(generatedOutfitsProvider.notifier).state = generated;
    return generated;
  }

  Future<List<Outfit>> generateBackendOutfits(
    String style,
    WidgetRef ref, {
    bool usePersonalColor = false,
    bool useLuckyColor = false,
    bool matchWeather = false,
  }) async {
    try {
      final generated = await _repository.generateOutfits(
        style: style,
        usePersonalColor: usePersonalColor,
        useLuckyColor: useLuckyColor,
        matchWeather: matchWeather,
      );
      if (generated.isNotEmpty) {
        state = [...generated, ...state];
        ref.read(generatedOutfitsProvider.notifier).state = generated;
        return generated;
      }
    } catch (_) {}
    return generateOutfits(style, ref);
  }

  Outfit rushOutfit(WidgetRef ref) {
    final wardrobe = ref.read(wardrobeProvider);
    final tops = wardrobe
        .where((i) => i.category == ClothingCategory.top)
        .toList();
    final pants = wardrobe
        .where((i) => i.category == ClothingCategory.pants)
        .toList();
    final shoes = wardrobe
        .where((i) => i.category == ClothingCategory.shoes)
        .toList();

    if (tops.isEmpty || pants.isEmpty || shoes.isEmpty) return state.first;

    tops.shuffle();
    pants.shuffle();
    shoes.shuffle();

    return Outfit(
      id: 'rush_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Rush Outfit',
      itemIds: [tops.first.id, pants.first.id, shoes.first.id],
    );
  }

  Future<Outfit> rushBackendOutfit(WidgetRef ref) async {
    try {
      final outfit = await _repository.rushOutfit();
      if (outfit != null) {
        state = [outfit, ...state];
        return outfit;
      }
    } catch (_) {}
    return rushOutfit(ref);
  }
}
