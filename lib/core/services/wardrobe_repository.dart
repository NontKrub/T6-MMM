import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_item.dart';
import 'local_account_repository.dart';
import 'image_storage_service.dart';
import 'supabase_service.dart';

const _uuid = Uuid();

class WardrobeRepository {
  static const bucket = 'wardrobe-images';

  SupabaseClient? get _client => SupabaseService.client;
  final _local = LocalAccountRepository();
  final _imageStorage = ImageStorageService();

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
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    final itemId = _uuid.v4();
    if (client == null || user == null) {
      final item = ClothingItem(
        id: itemId,
        name: name.isNotEmpty ? name : 'Wardrobe item',
        brand: brand,
        category: fallbackCategory,
        imageUrl: fileName,
        tags: tags,
        color: color,
        colorHexes: colorHexes,
        pattern: pattern,
        silhouette: silhouette,
        analysisConfidence: analysisConfidence,
      );
      return _local.insertItem(item);
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

    final imageUrl = await client.storage
        .from(bucket)
        .createSignedUrl(imagePath, 60 * 60);
    final row = await client
        .from('clothing_items')
        .insert({
          'id': itemId,
          'user_id': user.id,
          'name': name.isNotEmpty ? name : 'Wardrobe item',
          'brand': brand,
          'category': fallbackCategory.value,
          'image_path': imagePath,
          'image_url': imageUrl,
          'tags': tags,
          'dominant_colors': colorHexes,
          'primary_color': color,
          'detected_attributes': {
            'pattern': pattern.name,
            'silhouette': silhouette.value,
            'analysis_source': 'on_device_pixels',
          },
          'ai_confidence': analysisConfidence,
        })
        .select()
        .single();

    final data = Map<String, dynamic>.from(row);
    data['image_url'] = imageUrl;
    return ClothingItem.fromJson(data);
  }

  Future<void> insertItem(ClothingItem item) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _local.insertItem(item);
      return;
    }

    await client
        .from('clothing_items')
        .insert(item.toInsertJson(userId: user.id, imagePath: item.imageUrl));
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
      await _local.recordWearCombination(itemIds);
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
}
