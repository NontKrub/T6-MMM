import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/garment_visual_fingerprint.dart';
import '../../shared/models/wearable_asset.dart';
import 'garment_segmentation_service.dart';
import 'garment_texture_composer.dart';
import 'wearable_template_resolver.dart';

class WearableAssetCache {
  WearableAssetCache({
    WearableTemplateResolver? resolver,
    GarmentTextureComposer? composer,
    GarmentSegmentationService? segmentation,
  }) : _resolver = resolver ?? const WearableTemplateResolver(),
       _composer = composer ?? GarmentTextureComposer(),
       _segmentation = segmentation ?? GarmentSegmentationService();

  static const _storageKey = 'mmm.wearable_assets.v1';

  final WearableTemplateResolver _resolver;
  final GarmentTextureComposer _composer;
  final GarmentSegmentationService _segmentation;
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();
  Future<void> _writeQueue = Future.value();

  Future<WearableAsset?> get(ClothingItem item) async {
    return _get(item, assetVersion: 1);
  }

  Future<WearableAsset?> getV2(ClothingItem item) async {
    return _get(item, assetVersion: 2);
  }

  Future<WearableAsset?> _get(
    ClothingItem item, {
    required int assetVersion,
  }) async {
    await _writeQueue;
    final entries = await _read();
    final value = entries[_cacheKey(item, assetVersion)];
    if (value is! Map) return null;
    try {
      return WearableAsset.fromJson(value.cast<String, dynamic>());
    } on Object {
      return null;
    }
  }

  Future<void> save(ClothingItem item, WearableAsset asset) => _update(
    (entries) => entries[_cacheKey(item, asset.assetVersion)] = asset.toJson(),
  );

  Future<void> invalidate(ClothingItem item) => _update((entries) {
    entries
      ..remove(_cacheKey(item, 1))
      ..remove(_cacheKey(item, 2));
  });

  Future<void> remove(String clothingItemId) => _update(
    (entries) => entries.removeWhere((_, value) {
      return value is Map && value['clothingItemId'] == clothingItemId;
    }),
  );

  Future<WearableAsset> rebuild(ClothingItem item) async {
    final asset = _resolver.resolve(item);
    await save(item, asset);
    return asset;
  }

  Future<WearableAsset> rebuildV2(
    ClothingItem item, {
    Uint8List? sourceBytes,
    GarmentSegmentationResult? segmentation,
  }) async {
    final resolved = _resolver.resolve(item);
    final resolvedSegmentation =
        segmentation ??
        (sourceBytes == null ? null : await _segmentation.segment(sourceBytes));
    final composed = await _composer.compose(
      item,
      sourceBytes: sourceBytes,
      segmentation: resolvedSegmentation,
    );
    final asset = WearableAsset(
      clothingItemId: resolved.clothingItemId,
      itemName: resolved.itemName,
      status: resolved.status,
      slot: resolved.slot,
      templateKey: resolved.templateKey,
      modelPath: resolved.modelPath,
      texturePath: composed.texturePath,
      baseColorHex:
          composed.fingerprint.primaryColorHex ?? resolved.baseColorHex,
      materialVariant: resolved.materialVariant,
      patternKey: resolved.patternKey,
      fitParameters: resolved.fitParameters,
      assetVersion: 2,
      isFallback:
          composed.fingerprint.kind == GarmentTextureKind.photoApproximation,
      textureKind: composed.fingerprint.kind,
      textureDigest: composed.textureDigest,
      fallbackReason: composed.fingerprint.fallbackReason,
      frontGraphicRect: composed.fingerprint.frontGraphicRect,
    );
    await save(item, asset);
    return asset;
  }

  static String cacheKey(ClothingItem item) => _cacheKey(item, 1);

  static String _cacheKey(ClothingItem item, int assetVersion) {
    final source = jsonEncode({
      'id': item.id,
      'category': item.category.name,
      'subtype': item.subtype,
      'fit': item.fit.name,
      'silhouette': item.silhouette.name,
      'color': item.color,
      'colorHexes': item.colorHexes,
      'pattern': item.pattern.name,
      'material': item.material.name,
      'imageUrl': item.imageUrl,
      'imagePath': item.imagePath,
      'analysisVersion': item.analysisVersion,
      'assetVersion': assetVersion,
    });
    return sha256.convert(utf8.encode(source)).toString();
  }

  Future<void> _update(void Function(Map<String, dynamic>) update) {
    final operation = _writeQueue.then<void>((_) async {
      final entries = await _read();
      update(entries);
      await _write(entries);
    });
    _writeQueue = operation.catchError((_) {});
    return operation;
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      final preferences = await _preferences;
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : {};
    } on Object {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> entries) async {
    try {
      final preferences = await _preferences;
      await preferences.setString(_storageKey, jsonEncode(entries));
    } on Object {
      // Derived avatar state is best-effort and never blocks wardrobe data.
    }
  }
}
