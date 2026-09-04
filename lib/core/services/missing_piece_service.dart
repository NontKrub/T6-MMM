import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';

enum MissingPiecePriority { low, medium, high }

enum MissingPieceReason {
  missingRequiredCategory,
  wardrobeImbalance,
  lowCompatibilityCoverage,
}

class StructuredMissingPieceRecommendation {
  const StructuredMissingPieceRecommendation({
    required this.category,
    required this.priority,
    required this.reason,
  });

  final ClothingCategory category;
  final MissingPiecePriority priority;
  final MissingPieceReason reason;
}

class MissingPieceService {
  const MissingPieceService();

  List<StructuredMissingPieceRecommendation> analyze(
    Iterable<ClothingItem> source, {
    Iterable<OutfitCandidate>? candidates,
  }) {
    final items = source.toList(growable: false);
    final counts = <ClothingCategory, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    final recommendations = <StructuredMissingPieceRecommendation>[];
    void add(
      ClothingCategory category,
      MissingPiecePriority priority,
      MissingPieceReason reason,
    ) {
      if (recommendations.any((entry) => entry.category == category)) return;
      recommendations.add(
        StructuredMissingPieceRecommendation(
          category: category,
          priority: priority,
          reason: reason,
        ),
      );
    }

    final tops = counts[ClothingCategory.top] ?? 0;
    final pants = counts[ClothingCategory.pants] ?? 0;
    final shoes = counts[ClothingCategory.shoes] ?? 0;
    final dresses = counts[ClothingCategory.dress] ?? 0;

    if (tops > 0 && pants == 0 && dresses == 0) {
      add(
        ClothingCategory.pants,
        MissingPiecePriority.high,
        MissingPieceReason.missingRequiredCategory,
      );
    }
    if (pants > 0 && tops == 0 && dresses == 0) {
      add(
        ClothingCategory.top,
        MissingPiecePriority.high,
        MissingPieceReason.missingRequiredCategory,
      );
    }
    if ((tops > 0 && pants > 0 || dresses > 0) && shoes == 0) {
      add(
        ClothingCategory.shoes,
        MissingPiecePriority.high,
        MissingPieceReason.missingRequiredCategory,
      );
    }

    if (tops >= 4 && pants > 0 && tops >= pants * 3) {
      add(
        ClothingCategory.pants,
        MissingPiecePriority.high,
        MissingPieceReason.wardrobeImbalance,
      );
    } else if (pants >= 4 && tops > 0 && pants >= tops * 3) {
      add(
        ClothingCategory.top,
        MissingPiecePriority.high,
        MissingPieceReason.wardrobeImbalance,
      );
    }

    final candidateList = candidates?.toList(growable: false);
    if (tops > 0 &&
        pants > 0 &&
        shoes > 0 &&
        candidateList != null &&
        candidateList.every((candidate) => !candidate.isComplete)) {
      add(
        ClothingCategory.shoes,
        MissingPiecePriority.medium,
        MissingPieceReason.lowCompatibilityCoverage,
      );
    }

    return recommendations;
  }
}
