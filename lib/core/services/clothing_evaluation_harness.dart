import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../shared/models/clothing_analysis.dart';

class ClothingEvaluationFixture {
  const ClothingEvaluationFixture({
    required this.name,
    required this.path,
    required this.expectedCategory,
    this.expectedPrimaryColor,
    this.conditions = const [],
  });

  factory ClothingEvaluationFixture.fromJson(
    String name,
    Map<String, dynamic> json,
  ) {
    return ClothingEvaluationFixture(
      name: name,
      path: json['path'] as String? ?? name,
      expectedCategory: json['category'] as String? ?? 'unknown',
      expectedPrimaryColor: json['primaryColor'] as String?,
      conditions: (json['conditions'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  final String name;
  final String path;
  final String expectedCategory;
  final String? expectedPrimaryColor;
  final List<String> conditions;
}

class ClothingEvaluationRecord {
  const ClothingEvaluationRecord({
    required this.fixture,
    required this.local,
    this.server,
  });

  final ClothingEvaluationFixture fixture;
  final ClothingAnalysisResult local;
  final ClothingAnalysisResult? server;

  Map<String, dynamic> toJson() => {
    'fixture': fixture.name,
    'expected_category': fixture.expectedCategory,
    'conditions': fixture.conditions,
    'local_predicted_category': local.category?.name,
    'local_confidence': local.confidence,
    'server_predicted_category': server?.category?.name,
    'server_confidence': server?.confidence,
    'user_review_requested': local.category == null,
  };
}

class ClothingEvaluationSummary {
  const ClothingEvaluationSummary({
    required this.evaluatedCount,
    required this.correctCount,
    required this.accuracy,
    required this.perCategoryAccuracy,
    required this.confusion,
    required this.manualReviewRate,
  });

  final int evaluatedCount;
  final int correctCount;
  final double accuracy;
  final Map<String, double> perCategoryAccuracy;
  final Map<String, Map<String, int>> confusion;
  final double manualReviewRate;

  Map<String, dynamic> toJson() => {
    'evaluated_count': evaluatedCount,
    'correct_count': correctCount,
    'accuracy': accuracy,
    'per_category_accuracy': perCategoryAccuracy,
    'confusion': confusion,
    'manual_review_rate': manualReviewRate,
  };
}

class ClothingEvaluationHarness {
  static const requiredCategoryCounts = <String, int>{
    'top': 5,
    'pants': 5,
    'shoes': 5,
    'hat': 5,
    'outerwear': 5,
    'dress': 5,
    'bag': 5,
    'accessory': 5,
  };

  Future<List<ClothingEvaluationRecord>> evaluate(
    Iterable<ClothingEvaluationFixture> fixtures, {
    required Future<ClothingAnalysisResult> Function(Uint8List bytes)
    localAnalyzer,
    Future<ClothingAnalysisResult> Function(Uint8List bytes)? serverAnalyzer,
  }) async {
    final records = <ClothingEvaluationRecord>[];
    for (final fixture in fixtures) {
      final bytes = await File(fixture.path).readAsBytes();
      final local = await localAnalyzer(bytes);
      final server = serverAnalyzer == null
          ? null
          : await serverAnalyzer(bytes);
      records.add(
        ClothingEvaluationRecord(
          fixture: fixture,
          local: local,
          server: server,
        ),
      );
    }
    return records;
  }

  static Map<String, int> categoryCounts(
    Iterable<ClothingEvaluationFixture> fixtures,
  ) {
    final counts = <String, int>{};
    for (final fixture in fixtures) {
      counts[fixture.expectedCategory] =
          (counts[fixture.expectedCategory] ?? 0) + 1;
    }
    return counts;
  }

  static List<String> missingCoverage(
    Iterable<ClothingEvaluationFixture> fixtures,
  ) {
    final counts = categoryCounts(fixtures);
    return requiredCategoryCounts.entries
        .where((entry) => (counts[entry.key] ?? 0) < entry.value)
        .map(
          (entry) => '${entry.key}: ${counts[entry.key] ?? 0}/${entry.value}',
        )
        .toList();
  }

  static ClothingEvaluationSummary summarize(
    Iterable<ClothingEvaluationRecord> records,
  ) {
    final list = records.toList();
    final categoryTotals = <String, int>{};
    final categoryCorrect = <String, int>{};
    final confusion = <String, Map<String, int>>{};
    var evaluatedCount = 0;
    var correctCount = 0;
    var reviewCount = 0;

    for (final record in list) {
      if (record.local.category == null) reviewCount++;
      final expected = record.fixture.expectedCategory;
      if (expected == 'unknown') continue;
      evaluatedCount++;
      categoryTotals[expected] = (categoryTotals[expected] ?? 0) + 1;
      final predicted =
          record.server?.category?.name ??
          record.local.category?.name ??
          'unknown';
      final predictions = confusion.putIfAbsent(expected, () => {});
      predictions[predicted] = (predictions[predicted] ?? 0) + 1;
      if (predicted == expected) {
        correctCount++;
        categoryCorrect[expected] = (categoryCorrect[expected] ?? 0) + 1;
      }
    }

    return ClothingEvaluationSummary(
      evaluatedCount: evaluatedCount,
      correctCount: correctCount,
      accuracy: evaluatedCount == 0 ? 0 : correctCount / evaluatedCount,
      perCategoryAccuracy: {
        for (final category in categoryTotals.keys)
          category:
              (categoryCorrect[category] ?? 0) / categoryTotals[category]!,
      },
      confusion: confusion,
      manualReviewRate: list.isEmpty ? 0 : reviewCount / list.length,
    );
  }

  static String encodeResults(Iterable<ClothingEvaluationRecord> records) {
    final list = records.toList();
    return const JsonEncoder.withIndent('  ').convert({
      'records': list.map((record) => record.toJson()).toList(),
      'summary': summarize(list).toJson(),
    });
  }
}
