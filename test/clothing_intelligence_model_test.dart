import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_merger.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test('loads rich metadata and safely preserves older fields', () {
    final item = ClothingItem.fromJson({
      'id': 'dress-1',
      'user_id': 'user-1',
      'name': 'Summer dress',
      'category': 'dress',
      'image_path': 'user-1/dress-1/original.jpg',
      'image_url': 'https://example.test/dress.jpg',
      'primary_color': 'navy',
      'dominant_colors': ['#112233', '#FFFFFF'],
      'subtype': 'midi dress',
      'material': 'linen',
      'fit': 'relaxed',
      'silhouette': 'a_line',
      'styles': ['casual', 'smartCasual'],
      'formality': 'casual',
      'seasons': ['summer'],
      'weather_suitability': ['warm', 'dry'],
      'warmth_level': 0.2,
      'tags': ['linen', 'navy'],
      'analysis_confidence': 0.91,
      'analysis_source': 'serverAI',
      'analysis_status': 'complete',
      'analysis_version': 'visual-v3',
      'user_corrected': true,
      'analyzed_at': '2026-08-30T10:00:00Z',
      'created_at': '2026-08-29T10:00:00Z',
      'updated_at': '2026-08-30T10:00:00Z',
    });

    expect(item.userId, 'user-1');
    expect(item.category, ClothingCategory.dress);
    expect(item.imagePath, 'user-1/dress-1/original.jpg');
    expect(item.primaryColor, 'navy');
    expect(item.dominantColors, ['#112233', '#FFFFFF']);
    expect(item.material, ClothingMaterial.linen);
    expect(item.fit, ClothingFit.relaxed);
    expect(item.styles, [ClothingStyle.casual, ClothingStyle.smartCasual]);
    expect(item.seasons, [Season.summer]);
    expect(item.weatherSuitability, [
      WeatherSuitability.warm,
      WeatherSuitability.dry,
    ]);
    expect(item.analysisSource, AnalysisSource.serverAI);
    expect(item.analysisStatus, AnalysisStatus.complete);
    expect(item.userCorrected, isTrue);
    expect(item.warmthLevel, 0.2);
  });

  test('unknown and malformed values degrade without crashing', () {
    final item = ClothingItem.fromJson({
      'id': 'legacy',
      'name': 'Legacy item',
      'category': 'not-a-category',
      'dominant_colors': 'not-an-array',
      'styles': [1, 'not-a-style'],
      'seasons': [null, 'not-a-season'],
      'warmth_level': 'unknown',
      'analysis_confidence': 4,
      'analysis_source': 'future-source',
      'analysis_status': 'future-status',
    });

    expect(item.category, ClothingCategory.unknown);
    expect(item.dominantColors, isEmpty);
    expect(item.styles, [ClothingStyle.unknown]);
    expect(item.seasons, [Season.unknown]);
    expect(item.warmthLevel, isNull);
    expect(item.analysisConfidence, 1);
    expect(item.analysisSource, AnalysisSource.unknown);
    expect(item.analysisStatus, AnalysisStatus.pending);
  });

  test(
    'merge gives corrections priority and rejects weak server conflicts',
    () {
      const local = ClothingAnalysisResult(
        category: ClothingCategory.top,
        colorHexes: ['#111111'],
        colorNames: ['black'],
        confidence: 0.84,
        source: AnalysisSource.localVision,
      );
      const server = ClothingAnalysisResult(
        category: ClothingCategory.accessory,
        colorHexes: ['#FFFFFF'],
        colorNames: ['white'],
        confidence: 0.48,
        source: AnalysisSource.serverAI,
        material: ClothingMaterial.cotton,
      );

      final merged = const ClothingAnalysisMerger().merge(
        local: local,
        server: server,
        corrections: ClothingAnalysisCorrections(
          correctedFields: const {'category'},
          category: ClothingCategory.dress,
        ),
      );

      expect(merged.category, ClothingCategory.dress);
      expect(merged.material, ClothingMaterial.cotton);
      expect(merged.source, AnalysisSource.merged);
      expect(merged.analysisVersion, currentAnalysisVersion);
    },
  );

  test('item reanalysis keeps only corrected metadata', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Corrected skirt',
      category: ClothingCategory.dress,
      imageUrl: '/managed/item.jpg',
      fit: ClothingFit.cropped,
      pattern: ClothingPattern.striped,
      correctedFields: const {'category'},
    );
    const server = ClothingAnalysisResult(
      category: ClothingCategory.pants,
      colorHexes: ['#FF0000'],
      colorNames: ['red'],
      fit: ClothingFit.slim,
      pattern: ClothingPattern.solid,
      confidence: 0.99,
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(merged.category, ClothingCategory.dress);
    expect(merged.fit, ClothingFit.slim);
    expect(merged.pattern, ClothingPattern.solid);
    expect(merged.colorHexes, ['#FF0000']);
    expect(merged.analysisSource, AnalysisSource.merged);
    expect(merged.analysisVersion, currentAnalysisVersion);
  });

  test('color corrections do not freeze unrelated metadata', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Colored top',
      category: ClothingCategory.top,
      imageUrl: '/managed/item.jpg',
      color: 'red',
      colorHexes: const ['#FF0000'],
      fit: ClothingFit.regular,
      correctedFields: const {'primary_color', 'dominant_colors'},
    );
    const server = ClothingAnalysisResult(
      category: ClothingCategory.outerwear,
      primaryColor: 'blue',
      colorHexes: ['#0000FF'],
      colorNames: ['blue'],
      fit: ClothingFit.slim,
      material: ClothingMaterial.denim,
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(merged.color, 'red');
    expect(merged.colorHexes, ['#FF0000']);
    expect(merged.category, ClothingCategory.outerwear);
    expect(merged.fit, ClothingFit.slim);
    expect(merged.material, ClothingMaterial.denim);
  });

  test('tag corrections do not freeze unrelated metadata', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Minimal top',
      category: ClothingCategory.top,
      imageUrl: '/managed/item.jpg',
      tags: const ['minimal'],
      fit: ClothingFit.regular,
      correctedFields: const {'tags'},
    );
    const server = ClothingAnalysisResult(
      colorHexes: [],
      colorNames: [],
      tags: ['sport'],
      fit: ClothingFit.relaxed,
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(merged.tags, ['minimal']);
    expect(merged.fit, ClothingFit.relaxed);
  });

  test('uncorrected reanalysis can replace automatic tags with none', () {
    const item = ClothingItem(
      id: 'item-1',
      name: 'Old top',
      category: ClothingCategory.top,
      imageUrl: '/managed/item.jpg',
      tags: ['automatic'],
    );
    const server = ClothingAnalysisResult(
      colorHexes: [],
      colorNames: [],
      tags: [],
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(merged.tags, isEmpty);
  });

  test('items without corrections fully accept refreshed metadata', () {
    const item = ClothingItem(
      id: 'item-1',
      name: 'Old top',
      category: ClothingCategory.top,
      imageUrl: '/managed/item.jpg',
      tags: ['old'],
      fit: ClothingFit.regular,
    );
    const server = ClothingAnalysisResult(
      category: ClothingCategory.pants,
      colorHexes: [],
      colorNames: [],
      tags: ['new'],
      fit: ClothingFit.slim,
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(merged.category, ClothingCategory.pants);
    expect(merged.tags, ['new']);
    expect(merged.fit, ClothingFit.slim);
    expect(merged.correctedFields, isEmpty);
    expect(merged.userCorrected, isFalse);
  });

  test('legacy corrected rows remain protected', () {
    final item = ClothingItem.fromJson({
      'id': 'legacy-corrected',
      'name': 'Legacy dress',
      'category': 'dress',
      'image_url': '/managed/item.jpg',
      'fit': 'regular',
      'tags': ['manual'],
      'user_corrected': true,
      'corrected_fields': [],
    });
    const server = ClothingAnalysisResult(
      category: ClothingCategory.pants,
      colorHexes: [],
      colorNames: [],
      fit: ClothingFit.slim,
      tags: ['server'],
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );

    expect(item.correctedFields, clothingAnalysisFieldNames);
    expect(merged.category, ClothingCategory.dress);
    expect(merged.fit, ClothingFit.regular);
    expect(merged.tags, ['manual']);
    expect(merged.userCorrected, isTrue);
  });

  test('aligned local and server outerwear remains outerwear', () {
    final local = mapClothingLabels([
      const ImageLabelPrediction(text: 'jacket', confidence: .95),
    ]);
    const server = ClothingAnalysisResult(
      category: ClothingCategory.outerwear,
      colorHexes: [],
      colorNames: [],
      confidence: .9,
      source: AnalysisSource.serverAI,
    );

    final merged = const ClothingAnalysisMerger().merge(
      local: local,
      server: server,
    );

    expect(merged.category, ClothingCategory.outerwear);
  });

  test('insert serialization includes scoped identity and timestamps', () {
    final createdAt = DateTime.utc(2026, 8, 29);
    final updatedAt = DateTime.utc(2026, 8, 30);
    final item = ClothingItem(
      id: 'item-1',
      name: 'Tee',
      category: ClothingCategory.top,
      imageUrl: 'https://example.test/tee.jpg',
      imagePath: 'old/path.jpg',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final json = item.toInsertJson(
      userId: 'user-1',
      imagePath: 'user-1/item-1/original.jpg',
    );

    expect(json['id'], isNull);
    expect(json['user_id'], 'user-1');
    expect(json['image_path'], 'user-1/item-1/original.jpg');
    expect(json['created_at'], createdAt.toIso8601String());
    expect(json['updated_at'], updatedAt.toIso8601String());
  });

  test('corrected fields round-trip through database JSON', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Corrected top',
      category: ClothingCategory.top,
      imageUrl: 'https://example.test/top.jpg',
      correctedFields: const {'tags', 'category'},
    );

    final json = item.toJson();
    final restored = ClothingItem.fromJson(json);

    expect(json['corrected_fields'], ['category', 'tags']);
    expect(restored.correctedFields, {'category', 'tags'});
    expect(restored.userCorrected, isTrue);
    expect(
      ClothingItem.fromJson(
        item.toInsertJson(
          userId: 'user-1',
          imagePath: 'user-1/item-1/original.jpg',
        ),
      ).correctedFields,
      {'category', 'tags'},
    );
  });

  test(
    'copyWith preserves omitted nullable values and clears explicit nulls',
    () {
      final timestamp = DateTime.utc(2026, 8, 30);
      final item = ClothingItem(
        id: 'item-1',
        name: 'Red jacket',
        brand: 'MMM',
        category: ClothingCategory.outerwear,
        subtype: 'bomber',
        imageUrl: 'https://example.test/jacket.jpg',
        imagePath: 'user-1/item-1/jacket.jpg',
        color: 'red',
        warmthLevel: .8,
        analysisConfidence: .9,
        classificationSource: 'vision',
        colorSource: 'vision',
        analyzedAt: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
        lastWorn: timestamp,
      );

      expect(item.copyWith().primaryColor, 'red');

      final cleared = item.copyWith(
        brand: null,
        subtype: null,
        color: null,
        imagePath: null,
        warmthLevel: null,
        analysisConfidence: null,
        classificationSource: null,
        colorSource: null,
        analyzedAt: null,
        updatedAt: null,
        lastWorn: null,
      );

      expect(cleared.brand, isNull);
      expect(cleared.subtype, isNull);
      expect(cleared.primaryColor, isNull);
      expect(cleared.imagePath, isNull);
      expect(cleared.warmthLevel, isNull);
      expect(cleared.analysisConfidence, isNull);
      expect(cleared.classificationSource, isNull);
      expect(cleared.colorSource, isNull);
      expect(cleared.analyzedAt, isNull);
      expect(cleared.updatedAt, isNull);
      expect(cleared.lastWorn, isNull);
      expect(cleared.toJson()['primary_color'], isNull);
      expect(cleared.toJson()['subtype'], isNull);
      expect(cleared.toJson()['warmth_level'], isNull);
    },
  );

  test('corrected null metadata clears stale values in merged item JSON', () {
    final item = ClothingItem(
      id: 'item-1',
      name: 'Corrected jacket',
      category: ClothingCategory.outerwear,
      subtype: 'bomber',
      imageUrl: 'https://example.test/jacket.jpg',
      color: 'red',
      warmthLevel: .8,
      correctedFields: const {'subtype', 'primary_color', 'warmth_level'},
    );
    final merged = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      corrections: const ClothingAnalysisCorrections(
        correctedFields: {'subtype', 'primary_color', 'warmth_level'},
      ),
    );

    expect(merged.subtype, isNull);
    expect(merged.primaryColor, isNull);
    expect(merged.warmthLevel, isNull);
    expect(merged.toJson()['primary_color'], isNull);
    expect(merged.toJson()['subtype'], isNull);
    expect(merged.toJson()['warmth_level'], isNull);
  });

  test('parses the server analysis contract defensively', () {
    final result = ClothingAnalysisResult.fromJson({
      'category': 'outerwear',
      'subtype': 'light jacket',
      'primary_color': 'black',
      'dominant_colors': ['#111111', '#FFFFFF', 'red'],
      'pattern': 'graphic',
      'material': 'cotton',
      'fit': 'oversized',
      'silhouette': 'relaxed',
      'styles': ['streetwear', 'casual'],
      'formality': 'casual',
      'seasons': ['spring'],
      'weather_suitability': ['mild', 'dry'],
      'warmth_level': 0.35,
      'tags': ['jacket', 'black'],
      'confidence': 0.9,
      'analysis_source': 'serverAI',
      'analysis_status': 'complete',
    });

    expect(result.category, ClothingCategory.outerwear);
    expect(result.colorHexes, ['#111111', '#FFFFFF']);
    expect(result.colorNames, ['red']);
    expect(result.styles, ['streetwear', 'casual']);
    expect(result.tags, ['jacket', 'black']);
    expect(result.source, AnalysisSource.serverAI);
    expect(result.status, AnalysisStatus.complete);

    final malformed = ClothingAnalysisResult.fromJson({
      'category': <String, Object?>{},
      'dominant_colors': 'not-an-array',
      'styles': [1],
      'confidence': 3,
      'warmth_level': -1,
    });
    expect(malformed.category, ClothingCategory.unknown);
    expect(malformed.styles, isEmpty);
    expect(malformed.confidence, 1);
    expect(malformed.warmthLevel, 0);
  });
}
