import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../shared/models/outfit.dart';
import '../services/outfit_repository.dart';
import 'app_settings_provider.dart';
import 'repetition_insight_provider.dart';
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

  Future<void> selectOutfit(Outfit outfit, WidgetRef ref) async {
    ref.read(currentOutfitProvider.notifier).state = outfit;
    await ref
        .read(wardrobeProvider.notifier)
        .markOutfitWorn(
          outfitId: outfit.id,
          itemIds: outfit.itemIds,
          style: outfit.style,
        );

    if (ref.read(appSettingsProvider).learnPreferences) {
      await _recordPreferenceSelection(outfit, ref);
    }
    ref.invalidate(repetitionInsightProvider);
  }

  Future<void> _recordPreferenceSelection(Outfit outfit, WidgetRef ref) async {
    if (!_isLearnableSelection(outfit, ref)) return;

    final selectedItems = ref
        .read(wardrobeProvider)
        .where((item) => outfit.itemIds.contains(item.id))
        .toList();
    if (selectedItems.isEmpty) return;

    final tags = <String>{};
    final colors = <String>{};
    for (final item in selectedItems) {
      tags.addAll(item.tags.map((tag) => tag.trim().toLowerCase()));
      final color = item.color?.trim().toLowerCase();
      if (color != null && color.isNotEmpty) {
        colors.add(color);
      }
    }

    await _repository.recordPreferenceEvent(
      outfit: outfit,
      itemIds: selectedItems.map((item) => item.id).toList(),
      tags: tags.toList(),
      colors: colors.toList(),
      source: _sourceFor(outfit),
    );
  }

  bool _isLearnableSelection(Outfit outfit, WidgetRef ref) {
    final isRush = (outfit.style ?? '').trim().toLowerCase() == 'rush';
    if (isRush) return true;
    final fromCurrentGeneration = ref
        .read(generatedOutfitsProvider)
        .any((entry) => entry.id == outfit.id);
    final looksGenerated =
        outfit.selectionFactors.isNotEmpty && outfit.itemIds.length >= 3;
    return fromCurrentGeneration || looksGenerated;
  }

  String _sourceFor(Outfit outfit) {
    final style = (outfit.style ?? '').trim().toLowerCase();
    if (style == 'rush') return 'rush';
    return 'generated';
  }

  Future<List<Outfit>> generateBackendOutfits(
    String style,
    WidgetRef ref, {
    bool usePersonalColor = false,
    bool useLuckyColor = false,
    bool matchWeather = false,
    String? targetHex,
  }) async {
    final appSettings = ref.read(appSettingsProvider);
    final generated = await _repository.generateOutfits(
      style: style,
      usePersonalColor: usePersonalColor,
      useLuckyColor: useLuckyColor,
      matchWeather: matchWeather,
      luckyColorMethod: appSettings.luckyColorMethod,
      weatherLocationMode: appSettings.weatherLocationMode,
      learnPreferences: appSettings.learnPreferences,
      targetHex: targetHex,
    );
    state = [...generated, ...state];
    ref.read(generatedOutfitsProvider.notifier).state = generated;
    return generated;
  }

  Future<Outfit> rushBackendOutfit(WidgetRef ref) async {
    final outfit = await _repository.rushOutfit();
    if (outfit == null) {
      throw StateError('Rush outfit requires a signed-in account.');
    }
    state = [outfit, ...state];
    return outfit;
  }

  Future<int> repeatCountFor(Outfit outfit) =>
      _repository.repeatCountFor(outfit.itemIds);
}
