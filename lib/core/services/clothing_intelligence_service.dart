import 'dart:typed_data';

import '../../shared/models/clothing_item.dart';
import 'clothing_analysis_merger.dart';
import 'clothing_analysis_service.dart';

typedef ServerClothingAnalysisRequest = Future<Map<String, dynamic>> Function();

class ClothingIntelligenceService {
  ClothingIntelligenceService({
    ClothingAnalysisService? localAnalyzer,
    ClothingAnalysisMerger? merger,
  }) : _localAnalyzer = localAnalyzer ?? const ClothingAnalysisService(),
       _merger = merger ?? const ClothingAnalysisMerger();

  final ClothingAnalysisService _localAnalyzer;
  final ClothingAnalysisMerger _merger;

  Future<ClothingAnalysisResult> runLocal(Uint8List bytes) {
    return _localAnalyzer.analyze(bytes);
  }

  Future<ClothingAnalysisResult> runServer(
    ServerClothingAnalysisRequest request,
  ) async {
    return ClothingAnalysisResult.fromJson(await request());
  }

  ClothingAnalysisResult merge({
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
    ClothingAnalysisCorrections? corrections,
  }) => _merger.merge(local: local, server: server, corrections: corrections);

  ClothingItem mergeIntoItem(
    ClothingItem item, {
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
    ClothingAnalysisCorrections? corrections,
  }) => _merger.mergeIntoItem(
    item,
    local: local,
    server: server,
    corrections: corrections,
  );
}
