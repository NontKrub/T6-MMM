import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/wearable_asset.dart';
import 'wearable_template_resolver.dart';

class WearableAssetCache {
  WearableAssetCache({WearableTemplateResolver? resolver})
    : _resolver = resolver ?? const WearableTemplateResolver();

  static const _storageKey = 'mmm.wearable_assets.v1';

  final WearableTemplateResolver _resolver;
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();
  Future<void> _writeQueue = Future.value();

  Future<WearableAsset?> get(ClothingItem item) async {
    await _writeQueue;
    final entries = await _read();
    final value = entries[_cacheKey(item)];
    if (value is! Map) return null;
    try {
      return WearableAsset.fromJson(value.cast<String, dynamic>());
    } on Object {
      return null;
    }
  }

  Future<void> save(ClothingItem item, WearableAsset asset) =>
      _update((entries) => entries[_cacheKey(item)] = asset.toJson());

  Future<void> invalidate(ClothingItem item) =>
      _update((entries) => entries.remove(_cacheKey(item)));

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

  static String cacheKey(ClothingItem item) => _cacheKey(item);

  static String _cacheKey(ClothingItem item) {
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
      'assetVersion': 1,
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
