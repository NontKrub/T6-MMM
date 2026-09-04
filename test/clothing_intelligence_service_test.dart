import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/clothing_intelligence_service.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test(
    'server analysis is parsed before it enters the merge pipeline',
    () async {
      final service = ClothingIntelligenceService();

      final result = await service.runServer(
        () async => {
          'category': 'top',
          'primary_color': 'black',
          'dominant_colors': ['#111111'],
          'styles': ['streetwear'],
          'confidence': 0.91,
          'analysis_source': 'serverAI',
          'analysis_status': 'complete',
        },
      );

      expect(result.category, ClothingCategory.top);
      expect(result.colorHexes, ['#111111']);
      expect(result.source, AnalysisSource.serverAI);
      expect(result.confidence, 0.91);
    },
  );
}
