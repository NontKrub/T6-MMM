import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/user_profile.dart';

const _uuid = Uuid();

class LocalAccountRepository {
  static const _guestEnabledKey = 'mmm_guest_enabled';
  static const _profileKey = 'mmm_guest_profile';
  static const _wardrobeKey = 'mmm_guest_wardrobe';

  Future<bool> hasGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestEnabledKey) ?? false;
  }

  Future<UserProfile> startGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);

    final existing = await fetchProfile();
    if (existing != null) return existing;

    const profile = UserProfile(id: 'local_guest', name: 'Guest');
    await upsertProfile(profile);
    return profile;
  }

  Future<void> clearGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestEnabledKey);
    await prefs.remove(_profileKey);
    await prefs.remove(_wardrobeKey);
  }

  Future<UserProfile?> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_guestEnabledKey) ?? false)) return null;

    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile.fromJson(
      json,
      styles:
          (json['style_preferences'] as List?)?.whereType<String>().toList() ??
          const [],
      occasions:
          (json['occasions'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<List<ClothingItem>> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_guestEnabledKey) ?? false)) return const [];

    final raw = prefs.getString(_wardrobeKey);
    if (raw == null || raw.isEmpty) return const [];

    final rows = (jsonDecode(raw) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return rows.map(ClothingItem.fromJson).toList();
  }

  Future<ClothingItem> insertItem(ClothingItem item) async {
    final itemWithId = item.id.isEmpty ? item.copyWithWithId(_uuid.v4()) : item;
    final items = await fetchItems();
    await _saveItems([
      itemWithId,
      ...items.where((i) => i.id != itemWithId.id),
    ]);
    return itemWithId;
  }

  Future<void> archiveItem(String id) async {
    final items = await fetchItems();
    await _saveItems(items.where((item) => item.id != id).toList());
  }

  Future<void> updateItems(List<ClothingItem> items) => _saveItems(items);

  Future<void> _saveItems(List<ClothingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEnabledKey, true);
    await prefs.setString(
      _wardrobeKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

extension on ClothingItem {
  ClothingItem copyWithWithId(String id) {
    return ClothingItem(
      id: id,
      name: name,
      brand: brand,
      category: category,
      imageUrl: imageUrl,
      tags: tags,
      color: color,
      wearCount: wearCount,
      lastWorn: lastWorn,
    );
  }
}
