import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import '../services/wardrobe_repository.dart';
import '../../shared/models/clothing_analysis.dart';
import '../../shared/models/clothing_item.dart';

final wardrobeProvider =
    StateNotifierProvider<WardrobeNotifier, List<ClothingItem>>((ref) {
      return WardrobeNotifier();
    });

class WardrobeNotifier extends StateNotifier<List<ClothingItem>> {
  WardrobeNotifier({WardrobeRepository? repository})
    : _repository = repository ?? WardrobeRepository(),
      super(const []) {
    load();
  }

  final WardrobeRepository _repository;

  Future<void> load() async {
    try {
      final items = await _repository.fetchItems();
      state = items;
    } catch (_) {}
  }

  Future<void> addItem(ClothingItem item) async {
    final persisted = await _repository.insertItem(item);
    state = [...state, persisted];
  }

  Future<void> addUploadedItem({
    required Uint8List bytes,
    required String fileName,
    required String name,
    String? brand,
    required ClothingCategory fallbackCategory,
    List<String> tags = const [],
    List<String> colorHexes = const [],
    String? color,
    ClothingPattern pattern = ClothingPattern.unknown,
    ClothingSilhouette silhouette = ClothingSilhouette.unknown,
    double? analysisConfidence,
    String? classificationSource,
    String? colorSource,
    Set<String> correctedFields = const {},
    ClothingAnalysisResult? localAnalysis,
  }) async {
    final item = await _repository.uploadAndCreateItem(
      bytes: bytes,
      fileName: fileName,
      name: name,
      brand: brand,
      fallbackCategory: fallbackCategory,
      tags: tags,
      colorHexes: colorHexes,
      color: color,
      pattern: pattern,
      silhouette: silhouette,
      analysisConfidence: analysisConfidence,
      classificationSource: classificationSource,
      colorSource: colorSource,
      correctedFields: correctedFields,
      localAnalysis: localAnalysis,
    );
    if (item != null) {
      state = [...state, item];
    }
  }

  Future<void> removeItem(String id) async {
    await _repository.archiveItem(id);
    state = state.where((item) => item.id != id).toList();
  }

  Future<void> markWorn(String id) async {
    await _repository.recordWear(itemIds: [id]);
    final now = DateTime.now();
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(wearCount: item.wearCount + 1, lastWorn: now);
      }
      return item;
    }).toList();
  }

  Future<void> markOutfitWorn({
    String? outfitId,
    required List<String> itemIds,
    String? style,
    String source = 'manual',
  }) async {
    await _repository.recordWear(
      outfitId: outfitId,
      itemIds: itemIds,
      style: style,
      source: source,
    );
    final now = DateTime.now();
    state = state.map((item) {
      if (itemIds.contains(item.id)) {
        return item.copyWith(wearCount: item.wearCount + 1, lastWorn: now);
      }
      return item;
    }).toList();
  }

  Future<void> reanalyzeItem(String id) async {
    final updated = await _repository.reanalyzeItem(id);
    if (updated == null) return;
    state = state.map((item) => item.id == id ? updated : item).toList();
  }

  List<ClothingItem> byCategory(ClothingCategory category) {
    return state.where((item) => item.category == category).toList();
  }

  List<ClothingItem> search(String query) {
    final lower = query.toLowerCase();
    return state
        .where(
          (item) =>
              item.name.toLowerCase().contains(lower) ||
              (item.brand?.toLowerCase().contains(lower) ?? false) ||
              item.tags.any((t) => t.toLowerCase().contains(lower)),
        )
        .toList();
  }

  // Returns the dominant color tone worn recently (for repetition tracker)
  String? dominantRecentColor() {
    final recent = state
        .where(
          (i) =>
              i.lastWorn != null &&
              DateTime.now().difference(i.lastWorn!).inDays < 7,
        )
        .toList();
    if (recent.isEmpty) return null;
    final colorCounts = <String, int>{};
    for (final item in recent) {
      if (item.color != null) {
        colorCounts[item.color!] = (colorCounts[item.color!] ?? 0) + 1;
      }
    }
    if (colorCounts.isEmpty) return null;
    return colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
