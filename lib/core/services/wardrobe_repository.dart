import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_analysis.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit_intelligence.dart';
import 'clothing_intelligence_service.dart';
import 'local_account_repository.dart';
import 'image_storage_service.dart';
import 'supabase_service.dart';

const _uuid = Uuid();
const _serverAnalysisTimeout = Duration(seconds: 20);

class WardrobeRepository {
  static const bucket = 'wardrobe-images';

  WardrobeRepository({
    LocalAccountRepository? local,
    ImageStorageService? imageStorage,
    ClothingIntelligenceService? intelligence,
  }) : _local = local ?? LocalAccountRepository(),
       _imageStorage = imageStorage ?? ImageStorageService(),
       _intelligence = intelligence ?? ClothingIntelligenceService();

  SupabaseClient? get _client => SupabaseService.client;
  final LocalAccountRepository _local;
  final ImageStorageService _imageStorage;
  final ClothingIntelligenceService _intelligence;

  Future<List<ClothingItem>> fetchItems() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return _local.fetchItems();
    }

    final rows = await client
        .from('clothing_items')
        .select()
        .isFilter('archived_at', null)
        .order('created_at', ascending: false);

    final items = <ClothingItem>[];
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row);
      final imagePath = data['image_path'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          data['image_url'] = await client.storage
              .from(bucket)
              .createSignedUrl(imagePath, 60 * 60);
        } catch (_) {
          data['image_url'] = data['image_url'] ?? '';
        }
      }
      items.add(ClothingItem.fromJson(data));
    }
    return items;
  }

  Future<ClothingItem?> uploadAndCreateItem({
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
    ClothingAnalysisResult? localAnalysis,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    final itemId = _uuid.v4();
    final localResult =
        localAnalysis ??
        _fallbackAnalysis(
          category: fallbackCategory,
          color: color,
          colorHexes: colorHexes,
          tags: tags,
          pattern: pattern,
          silhouette: silhouette,
          confidence: analysisConfidence,
          classificationSource: classificationSource,
          colorSource: colorSource,
        );
    final corrections = _correctionsForInput(
      fallbackCategory: fallbackCategory,
      color: color,
      colorHexes: colorHexes,
      tags: tags,
      pattern: pattern,
      silhouette: silhouette,
      classificationSource: classificationSource,
      colorSource: colorSource,
    );
    final localMerged = _intelligence.merge(
      local: localResult,
      corrections: corrections,
    );
    if (client == null || user == null) {
      return _local.insertItem(
        _itemFromAnalysis(
          id: itemId,
          name: name,
          brand: brand,
          imageUrl: fileName,
          imagePath: fileName,
          fallbackCategory: fallbackCategory,
          requestedTags: tags,
          analysis: localMerged,
          userCorrected: corrections != null,
        ),
      );
    }

    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final imagePath = '${user.id}/$itemId/original.$safeExtension';

    await client.storage
        .from(bucket)
        .uploadBinary(
          imagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    var imageUrl = '';
    try {
      imageUrl = await client.storage
          .from(bucket)
          .createSignedUrl(imagePath, 60 * 60);
    } catch (error) {
      _log('Unable to create wardrobe image URL: $error');
    }

    ClothingItem finalItem;
    try {
      final serverResult = await _requestServerAnalysis(
        client: client,
        imagePath: imagePath,
        name: name,
        brand: brand,
        tags: tags,
      );
      _log('Server clothing analysis completed for $itemId');
      final merged = _intelligence.merge(
        local: localResult,
        server: serverResult,
        corrections: corrections,
      );
      finalItem = _itemFromAnalysis(
        id: itemId,
        name: name,
        brand: brand,
        imageUrl: imageUrl,
        imagePath: imagePath,
        fallbackCategory: fallbackCategory,
        requestedTags: tags,
        analysis: merged,
        userCorrected: corrections != null,
      );
    } catch (error) {
      _log('Server clothing analysis failed for $itemId: $error');
      finalItem =
          _itemFromAnalysis(
            id: itemId,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            imagePath: imagePath,
            fallbackCategory: fallbackCategory,
            requestedTags: tags,
            analysis: localMerged,
            userCorrected: corrections != null,
          ).copyWith(
            analysisStatus: AnalysisStatus.failed,
            analyzedAt: DateTime.now(),
            analysisVersion: currentAnalysisVersion,
          );
    }

    try {
      final payload = finalItem.toInsertJson(
        userId: user.id,
        imagePath: imagePath,
      )..['id'] = itemId;
      final row = await client
          .from('clothing_items')
          .insert(payload)
          .select()
          .single();

      final data = Map<String, dynamic>.from(row);
      data['image_url'] = imageUrl;
      return ClothingItem.fromJson(data);
    } catch (error) {
      try {
        await client.storage.from(bucket).remove([imagePath]);
      } catch (cleanupError) {
        _log('Could not clean failed wardrobe upload: $cleanupError');
      }
      rethrow;
    }
  }

  Future<ClothingItem> insertItem(ClothingItem item) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return _local.insertItem(item);
    }

    final row = await client
        .from('clothing_items')
        .insert(
          item.toInsertJson(
            userId: user.id,
            imagePath: item.imagePath ?? item.imageUrl,
          )..['id'] = item.id,
        )
        .select()
        .single();
    return ClothingItem.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> archiveItem(String id) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      final item = (await _local.fetchItems())
          .where((item) => item.id == id)
          .firstOrNull;
      if (item != null) await _imageStorage.deleteOwned(item.imageUrl);
      await _local.archiveItem(id);
      return;
    }
    await client
        .from('clothing_items')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<ClothingItem?> reanalyzeItem(String id) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      final items = await _local.fetchItems();
      final item = items.where((entry) => entry.id == id).firstOrNull;
      if (item == null) return null;
      final path = item.imagePath ?? item.imageUrl;
      if (path.isEmpty || !await File(path).exists()) {
        throw StateError('The original clothing image is unavailable.');
      }
      final local = await _intelligence.runLocal(
        await File(path).readAsBytes(),
      );
      final updated = _intelligence.mergeIntoItem(item, local: local);
      await _local.updateItems(
        items.map((entry) => entry.id == id ? updated : entry).toList(),
      );
      return updated;
    }

    final row = await client
        .from('clothing_items')
        .select()
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    final data = Map<String, dynamic>.from(row);
    final item = ClothingItem.fromJson(data);
    final imagePath = item.imagePath ?? data['image_path'] as String?;
    if (imagePath == null || imagePath.isEmpty) {
      throw StateError('The original clothing image is unavailable.');
    }
    final server = await _requestServerAnalysis(
      client: client,
      imagePath: imagePath,
      name: item.name,
      brand: item.brand,
      tags: item.tags,
    );
    final updated = _intelligence.mergeIntoItem(item, server: server);
    await client
        .from('clothing_items')
        .update(_analysisUpdateJson(updated))
        .eq('id', id)
        .eq('user_id', user.id);
    return updated;
  }

  Future<void> recordWear({
    String? outfitId,
    required List<String> itemIds,
    String? style,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      final items = await _local.fetchItems();
      final now = DateTime.now();
      await _local.updateItems(
        items.map((item) {
          if (!itemIds.contains(item.id)) return item;
          return item.copyWith(wearCount: item.wearCount + 1, lastWorn: now);
        }).toList(),
      );
      await _local.recordWearEvent(
        WearEvent(
          outfitId: outfitId,
          itemIds: itemIds,
          wornAt: now,
          source: 'manual',
        ),
      );
      return;
    }
    await client.rpc(
      'record_wear_event',
      params: {
        'p_outfit_id': outfitId,
        'p_clothing_item_ids': itemIds,
        'p_style': style,
      },
    );
  }

  Future<ClothingAnalysisResult> _requestServerAnalysis({
    required SupabaseClient client,
    required String imagePath,
    required String name,
    required String? brand,
    required List<String> tags,
  }) {
    return _intelligence.runServer(() async {
      final response = await client.functions
          .invoke(
            'analyze-clothing-image',
            body: {
              'image_path': imagePath,
              'name': name,
              'brand': brand,
              'tags': tags,
            },
          )
          .timeout(_serverAnalysisTimeout);
      if (response.status < 200 || response.status >= 300) {
        throw StateError(
          'Clothing analysis failed with status ${response.status}.',
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw StateError('Clothing analysis returned an invalid payload.');
      }
      return Map<String, dynamic>.from(data);
    });
  }

  ClothingAnalysisResult _fallbackAnalysis({
    required ClothingCategory category,
    required String? color,
    required List<String> colorHexes,
    required List<String> tags,
    required ClothingPattern pattern,
    required ClothingSilhouette silhouette,
    required double? confidence,
    required String? classificationSource,
    required String? colorSource,
  }) => ClothingAnalysisResult(
    category: category,
    colorHexes: colorHexes,
    colorNames: color == null ? const [] : [color],
    primaryColor: color,
    styles: tags,
    tags: tags,
    pattern: pattern,
    silhouette: silhouette,
    confidence: confidence,
    classificationSource: classificationSource,
    colorSource: colorSource,
    source: classificationSource == 'manual'
        ? AnalysisSource.manual
        : AnalysisSource.localVision,
    status: AnalysisStatus.partial,
  );

  ClothingAnalysisCorrections? _correctionsForInput({
    required ClothingCategory fallbackCategory,
    required String? color,
    required List<String> colorHexes,
    required List<String> tags,
    required ClothingPattern pattern,
    required ClothingSilhouette silhouette,
    required String? classificationSource,
    required String? colorSource,
  }) {
    final corrected =
        classificationSource == 'manual' || colorSource == 'manual';
    if (!corrected) return null;
    return ClothingAnalysisCorrections(
      category: fallbackCategory,
      primaryColor: color,
      colorHexes: colorHexes,
      pattern: pattern == ClothingPattern.unknown ? null : pattern,
      silhouette: silhouette == ClothingSilhouette.unknown ? null : silhouette,
      tags: tags,
    );
  }

  ClothingItem _itemFromAnalysis({
    required String id,
    required String name,
    required String? brand,
    required String imageUrl,
    required String imagePath,
    required ClothingCategory fallbackCategory,
    required List<String> requestedTags,
    required ClothingAnalysisResult analysis,
    required bool userCorrected,
  }) {
    final now = DateTime.now();
    final colors = analysis.colorHexes.isEmpty
        ? const <String>[]
        : analysis.colorHexes;
    return ClothingItem(
      id: id,
      name: name.isNotEmpty ? name : 'Wardrobe item',
      brand: brand,
      category: analysis.category ?? fallbackCategory,
      subtype: analysis.subtype,
      imageUrl: imageUrl,
      imagePath: imagePath,
      tags: {...requestedTags, ...analysis.tags}.toList(),
      color: analysis.primaryColor,
      colorHexes: colors,
      pattern: analysis.pattern,
      material: analysis.material,
      fit: analysis.fit,
      silhouette: analysis.silhouette,
      styles: analysis.resolvedStyles,
      formality: analysis.formality,
      seasons: analysis.seasons,
      weatherSuitability: analysis.weatherSuitability,
      warmthLevel: analysis.warmthLevel,
      analysisConfidence: analysis.confidence,
      classificationSource: analysis.classificationSource,
      colorSource: analysis.colorSource,
      analysisSource: analysis.source,
      analysisStatus: analysis.status,
      analysisVersion: analysis.analysisVersion,
      userCorrected: userCorrected || analysis.source == AnalysisSource.manual,
      analyzedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> _analysisUpdateJson(ClothingItem item) {
    final json = item.toJson();
    for (final key in const [
      'id',
      'user_id',
      'name',
      'brand',
      'category',
      'image_url',
      'image_path',
      'tags',
      'wear_count',
      'last_worn',
      'created_at',
      'updated_at',
    ]) {
      json.remove(key);
    }
    return json;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('Clothing intelligence: $message');
  }
}
