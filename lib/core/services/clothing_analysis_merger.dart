import '../../shared/models/clothing_analysis.dart';
import '../../shared/models/clothing_item.dart';

class ClothingAnalysisMerger {
  const ClothingAnalysisMerger();

  ClothingAnalysisResult merge({
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
    ClothingAnalysisCorrections? corrections,
  }) {
    final category = corrections?.contains('category') == true
        ? corrections!.category
        : _category(local, server);
    final hexes = corrections?.contains('dominant_colors') == true
        ? corrections!.colorHexes ?? const []
        : _mergeHexes(
            local?.colorHexes ?? const [],
            server?.colorHexes ?? const [],
          );
    final styles = corrections?.contains('styles') == true
        ? corrections!.clothingStyles ?? const []
        : _mergeStyles(
            local?.resolvedStyles ?? const [],
            server?.resolvedStyles ?? const [],
          );
    final source = _source(local, server, corrections);

    return ClothingAnalysisResult(
      category: category,
      subtype: corrections?.contains('subtype') == true
          ? corrections!.subtype
          : server?.subtype ?? local?.subtype,
      primaryColor: corrections?.contains('primary_color') == true
          ? corrections!.primaryColor
          : server?.primaryColor ??
                local?.primaryColor ??
                (server?.colorNames.firstOrNull ??
                    local?.colorNames.firstOrNull),
      colorHexes: hexes,
      colorNames: hexes.map(_coarseColorName).toList(),
      styles: styles.map((style) => style.name).toList(),
      clothingStyles: styles,
      pattern: corrections?.contains('pattern') == true
          ? corrections!.pattern ?? ClothingPattern.unknown
          : _preferKnown(
              server?.pattern,
              local?.pattern,
              ClothingPattern.unknown,
            ),
      material: corrections?.contains('material') == true
          ? corrections!.material ?? ClothingMaterial.unknown
          : _preferKnown(
              server?.material,
              local?.material,
              ClothingMaterial.unknown,
            ),
      fit: corrections?.contains('fit') == true
          ? corrections!.fit ?? ClothingFit.unknown
          : _preferKnown(server?.fit, local?.fit, ClothingFit.unknown),
      silhouette: corrections?.contains('silhouette') == true
          ? corrections!.silhouette ?? ClothingSilhouette.unknown
          : _preferKnown(
              server?.silhouette,
              local?.silhouette,
              ClothingSilhouette.unknown,
            ),
      formality: corrections?.contains('formality') == true
          ? corrections!.formality ?? ClothingFormality.unknown
          : _preferKnown(
              server?.formality,
              local?.formality,
              ClothingFormality.unknown,
            ),
      seasons: corrections?.contains('seasons') == true
          ? corrections!.seasons ?? const []
          : _mergeEnums(
              server?.seasons ?? const [],
              local?.seasons ?? const [],
            ),
      weatherSuitability: corrections?.contains('weather_suitability') == true
          ? corrections!.weatherSuitability ?? const []
          : _mergeEnums(
              server?.weatherSuitability ?? const [],
              local?.weatherSuitability ?? const [],
            ),
      warmthLevel: corrections?.contains('warmth_level') == true
          ? corrections!.warmthLevel
          : server?.warmthLevel ?? local?.warmthLevel,
      tags: corrections?.contains('tags') == true
          ? corrections!.tags ?? const []
          : server != null
          ? server.tags
          : local?.tags ?? const [],
      confidence: _confidence(local, server),
      classificationSource:
          server?.classificationSource ?? local?.classificationSource,
      colorSource: server?.colorSource ?? local?.colorSource,
      source: source,
      status: _status(local, server),
      analysisVersion: currentAnalysisVersion,
    );
  }

  ClothingItem mergeIntoItem(
    ClothingItem item, {
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
    ClothingAnalysisCorrections? corrections,
  }) {
    final preservedCorrections =
        corrections ??
        (item.effectiveCorrectedFields.isNotEmpty
            ? ClothingAnalysisCorrections.fromItem(
                item,
                item.effectiveCorrectedFields,
              )
            : null);
    final result = merge(
      local: local,
      server: server,
      corrections: preservedCorrections,
    );
    final now = DateTime.now();
    final correctedFields = {
      ...item.correctedFields,
      ...?preservedCorrections?.correctedFields,
    };
    final hasAnalysis = local != null || server != null;

    return item.copyWith(
      category: result.category ?? item.category,
      subtype: result.subtype ?? item.subtype,
      color:
          hasAnalysis || preservedCorrections?.contains('primary_color') == true
          ? result.primaryColor
          : item.color,
      colorHexes:
          hasAnalysis ||
              preservedCorrections?.contains('dominant_colors') == true
          ? result.colorHexes
          : item.colorHexes,
      pattern: result.pattern,
      material: result.material,
      fit: result.fit,
      silhouette: result.silhouette,
      styles: result.resolvedStyles,
      formality: result.formality,
      seasons: result.seasons,
      weatherSuitability: result.weatherSuitability,
      warmthLevel: result.warmthLevel ?? item.warmthLevel,
      tags: hasAnalysis || preservedCorrections?.contains('tags') == true
          ? result.tags
          : item.tags,
      analysisConfidence: result.confidence ?? item.analysisConfidence,
      classificationSource:
          result.classificationSource ?? item.classificationSource,
      colorSource: result.colorSource ?? item.colorSource,
      analysisSource: result.source,
      analysisStatus: result.status,
      analysisVersion: result.analysisVersion,
      correctedFields: correctedFields,
      userCorrected: item.userCorrected || correctedFields.isNotEmpty,
      analyzedAt: now,
      updatedAt: now,
    );
  }

  ClothingCategory? _category(
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
  ) {
    final localCategory = _knownCategory(local?.category);
    final serverCategory = _knownCategory(server?.category);
    if (localCategory == null) return serverCategory;
    if (serverCategory == null) return localCategory;
    if (localCategory == serverCategory) return localCategory;

    final localConfidence = local?.confidence ?? 0;
    final serverConfidence = server?.confidence ?? 0;
    return serverConfidence >= .75 && serverConfidence > localConfidence
        ? serverCategory
        : localCategory;
  }

  T _preferKnown<T extends Enum>(T? first, T? second, T unknown) {
    if (first != null && first != unknown) return first;
    if (second != null && second != unknown) return second;
    return unknown;
  }

  List<T> _mergeEnums<T extends Enum>(List<T> first, List<T> second) => [
    ...first,
    ...second,
  ].where((value) => value.name != 'unknown').toSet().toList();

  List<ClothingStyle> _mergeStyles(
    List<ClothingStyle> first,
    List<ClothingStyle> second,
  ) => [
    ...first,
    ...second,
  ].where((style) => style != ClothingStyle.unknown).toSet().toList();

  List<String> _mergeHexes(List<String> first, List<String> second) => [
    ...first,
    ...second,
  ].map(_normalizeHex).whereType<String>().toSet().take(5).toList();

  AnalysisSource _source(
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
    ClothingAnalysisCorrections? corrections,
  ) {
    if (corrections != null) {
      return local != null || server != null
          ? AnalysisSource.merged
          : AnalysisSource.manual;
    }
    if (local != null && server != null) return AnalysisSource.merged;
    if (server != null) return AnalysisSource.serverAI;
    if (local != null) return AnalysisSource.localVision;
    return AnalysisSource.unknown;
  }

  AnalysisStatus _status(
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
  ) {
    if (server?.status == AnalysisStatus.complete) {
      return AnalysisStatus.complete;
    }
    if (local != null && server != null) {
      return AnalysisStatus.partial;
    }
    if (local != null) {
      return AnalysisStatus.partial;
    }
    if (server?.status == AnalysisStatus.failed) return AnalysisStatus.failed;
    return AnalysisStatus.pending;
  }

  double? _confidence(
    ClothingAnalysisResult? local,
    ClothingAnalysisResult? server,
  ) =>
      [local?.confidence, server?.confidence].whereType<double>().fold<double?>(
        null,
        (best, value) => best == null || value > best ? value : best,
      );

  ClothingCategory? _knownCategory(ClothingCategory? value) =>
      value == null || value == ClothingCategory.unknown ? null : value;
}

String? _normalizeHex(String value) {
  final normalized = value.trim().toUpperCase();
  final withHash = normalized.startsWith('#') ? normalized : '#$normalized';
  return RegExp(r'^#[0-9A-F]{6}$').hasMatch(withHash) ? withHash : null;
}

String _coarseColorName(String hex) {
  const references = <String, String>{
    'black': '#111111',
    'white': '#F5F5F5',
    'gray': '#808080',
    'red': '#D32F2F',
    'blue': '#1976D2',
    'green': '#388E3C',
    'brown': '#795548',
    'beige': '#DFCCAA',
    'yellow': '#FBC02D',
    'orange': '#F57C00',
    'purple': '#7B1FA2',
    'pink': '#E91E63',
  };
  return references.entries.reduce((best, entry) {
    return _distance(hex, entry.value) < _distance(hex, best.value)
        ? entry
        : best;
  }).key;
}

double _distance(String first, String second) {
  final a = int.parse(first.substring(1), radix: 16);
  final b = int.parse(second.substring(1), radix: 16);
  final red = (a >> 16) - (b >> 16);
  final green = ((a >> 8) & 0xff) - ((b >> 8) & 0xff);
  final blue = (a & 0xff) - (b & 0xff);
  return (red * red + green * green + blue * blue).toDouble();
}
