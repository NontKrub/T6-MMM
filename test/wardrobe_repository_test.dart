import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_merger.dart';
import 'package:mix_match_mood/core/services/clothing_intelligence_service.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/core/services/wardrobe_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'local reanalysis updates one item without overwriting correction',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'mmm-reanalysis-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final imagePath = '${directory.path}/item.jpg';
      await File(imagePath).writeAsBytes(
        await File('assets/images/vision_test_white_shirt.jpg').readAsBytes(),
      );

      final local = LocalAccountRepository();
      await local.startGuestAccount();
      await local.insertItem(
        ClothingItem(
          id: 'item-1',
          name: 'Corrected skirt',
          category: ClothingCategory.dress,
          imageUrl: imagePath,
          imagePath: imagePath,
          userCorrected: true,
        ),
      );
      final intelligence = ClothingIntelligenceService(
        localAnalyzer: ClothingAnalysisService(
          classifier: (_) async => [
            const ImageLabelPrediction(text: 'pants', confidence: .99),
          ],
        ),
      );
      final repository = WardrobeRepository(
        local: local,
        intelligence: intelligence,
      );

      final updated = await repository.reanalyzeItem('item-1');
      final stored = await local.fetchItems();

      expect(updated?.category, ClothingCategory.dress);
      expect(stored, hasLength(1));
      expect(stored.single.category, ClothingCategory.dress);
      expect(stored.single.analysisVersion, currentAnalysisVersion);
    },
  );

  test(
    'analysis update payload preserves analysis-owned category and tags',
    () {
      const item = ClothingItem(
        id: 'item-1',
        userId: 'user-1',
        name: 'Jacket',
        category: ClothingCategory.top,
        imageUrl: 'https://example.test/jacket.jpg',
        tags: ['old-tag'],
      );
      const server = ClothingAnalysisResult(
        category: ClothingCategory.outerwear,
        colorHexes: [],
        colorNames: [],
        tags: ['jacket', 'black'],
        confidence: .9,
        source: AnalysisSource.serverAI,
      );

      final payload = analysisUpdatePayload(
        const ClothingAnalysisMerger().mergeIntoItem(item, server: server),
      );

      expect(payload['category'], 'outerwear');
      expect(payload['tags'], ['jacket', 'black']);
      expect(payload, isNot(contains('id')));
      expect(payload, isNot(contains('user_id')));
      expect(payload, isNot(contains('name')));
      expect(payload, isNot(contains('image_path')));
      expect(payload, isNot(contains('wear_count')));
    },
  );

  test('analysis update payload keeps corrected category and tags', () {
    const item = ClothingItem(
      id: 'item-1',
      name: 'Corrected dress',
      category: ClothingCategory.dress,
      imageUrl: 'https://example.test/dress.jpg',
      tags: ['manual-dress'],
      userCorrected: true,
    );
    const server = ClothingAnalysisResult(
      category: ClothingCategory.pants,
      colorHexes: [],
      colorNames: [],
      tags: ['server-pants'],
      confidence: .99,
      source: AnalysisSource.serverAI,
    );

    final updated = const ClothingAnalysisMerger().mergeIntoItem(
      item,
      server: server,
    );
    final payload = analysisUpdatePayload(updated);

    expect(payload['category'], 'dress');
    expect(payload['tags'], ['manual-dress']);
  });

  test('guest upload passes only explicit corrections into the item', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    await local.startGuestAccount();
    final repository = WardrobeRepository(local: local);

    final item = await repository.uploadAndCreateItem(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'item.jpg',
      name: 'Corrected item',
      fallbackCategory: ClothingCategory.dress,
      correctedFields: const {'category'},
      localAnalysis: const ClothingAnalysisResult(
        category: ClothingCategory.top,
        colorHexes: ['#111111'],
        colorNames: ['black'],
        fit: ClothingFit.regular,
        pattern: ClothingPattern.striped,
      ),
    );

    expect(item?.category, ClothingCategory.dress);
    expect(item?.fit, ClothingFit.regular);
    expect(item?.pattern, ClothingPattern.striped);
    expect(item?.correctedFields, {'category'});
    expect(item?.userCorrected, isTrue);
  });
}
