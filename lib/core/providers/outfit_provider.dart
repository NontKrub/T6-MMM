import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../shared/models/outfit.dart';
import '../../shared/models/clothing_item.dart';
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
  OutfitNotifier() : super(const []) {
    load();
  }

  final _repository = OutfitRepository();

  Future<void> load() async {
    try {
      final outfits = await _repository.fetchOutfits();
      state = outfits;
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

  Future<List<Outfit>> generateBackendOutfits(
    String style,
    WidgetRef ref, {
    bool usePersonalColor = false,
    bool useLuckyColor = false,
    bool matchWeather = false,
  }) async {
    final generated = await _repository.generateOutfits(
      style: style,
      usePersonalColor: usePersonalColor,
      useLuckyColor: useLuckyColor,
      matchWeather: matchWeather,
    );
    state = [...generated, ...state];
    ref.read(generatedOutfitsProvider.notifier).state = generated;
    return generated;
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

    if (tops.isEmpty || pants.isEmpty || shoes.isEmpty) {
      throw StateError('Add at least one top, pants, and shoes first.');
    }

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
    final outfit = await _repository.rushOutfit();
    if (outfit == null) {
      throw StateError('Rush outfit requires a signed-in account.');
    }
    state = [outfit, ...state];
    return outfit;
  }
}
