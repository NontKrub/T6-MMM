import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_item.dart';
import 'supabase_service.dart';

const _uuid = Uuid();

class WardrobeRepository {
  static const bucket = 'wardrobe-images';

  SupabaseClient? get _client => SupabaseService.client;

  Future<List<ClothingItem>> fetchItems() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return const [];

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
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final itemId = _uuid.v4();
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

    Map<String, dynamic>? analysis;
    try {
      final response = await client.functions.invoke(
        'analyze-clothing-image',
        body: {
          'image_path': imagePath,
          'name': name,
          'brand': brand,
          'tags': tags,
        },
      );
      analysis = Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      analysis = null;
    }

    final imageUrl = await client.storage
        .from(bucket)
        .createSignedUrl(imagePath, 60 * 60);
    final row = await client
        .from('clothing_items')
        .insert({
          'id': itemId,
          'user_id': user.id,
          'name': name.isNotEmpty
              ? name
              : analysis?['suggested_name'] ?? 'Wardrobe item',
          'brand': brand,
          'category': analysis?['category'] ?? fallbackCategory.value,
          'image_path': imagePath,
          'image_url': imageUrl,
          'tags': analysis?['tags'] ?? tags,
          'dominant_colors': analysis?['dominant_colors'] ?? <String>[],
          'primary_color': analysis?['primary_color'],
          'detected_attributes': analysis?['attributes'] ?? <String, dynamic>{},
          'ai_confidence': analysis?['confidence'],
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
    if (client == null || user == null) return;

    await client
        .from('clothing_items')
        .insert(item.toInsertJson(userId: user.id, imagePath: item.imageUrl));
  }

  Future<void> archiveItem(String id) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;
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
    if (client == null || client.auth.currentUser == null) return;
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
