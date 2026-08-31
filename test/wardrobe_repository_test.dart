import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
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
}
