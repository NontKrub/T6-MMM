import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/user_profile.dart';
import 'local_account_repository.dart';
import 'supabase_service.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  final _local = LocalAccountRepository();
  static const _cachedCloudProfileKey = 'mmm_cached_cloud_profile';

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  Future<UserProfile?> fetchProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return _local.fetchProfile();

    try {
      final profileRow = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profileRow == null) return null;

      final preferenceRows = await client
          .from('style_preferences')
          .select('kind,value')
          .eq('user_id', user.id);
      final styles = <String>[];
      final occasions = <String>[];
      for (final row in preferenceRows) {
        if (row['kind'] == 'style') styles.add(row['value'] as String);
        if (row['kind'] == 'occasion') occasions.add(row['value'] as String);
      }

      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(profileRow),
        styles: styles,
        occasions: occasions,
      );
      try {
        await _cacheCloudProfile(profile, userId: user.id);
      } catch (_) {
        // Cache writes are best effort; a healthy remote profile must still load.
      }
      return profile;
    } catch (_) {
      final cached = await fetchCachedCloudProfile(user.id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<UserProfile?> fetchCachedCloudProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedCloudProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (json['id'] != userId) return null;
      return UserProfile.fromJson(
        json,
        styles:
            (json['style_preferences'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        occasions:
            (json['occasions'] as List?)?.whereType<String>().toList() ??
            const [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheCloudProfile(UserProfile profile, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheProfile = userId == null
        ? profile
        : profile.copyWith(id: userId);
    await prefs.setString(
      _cachedCloudProfileKey,
      jsonEncode(cacheProfile.toJson()),
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _local.upsertProfile(profile);
      return;
    }

    await client.from('profiles').upsert({
      ...profile.toProfileJson(),
      'id': user.id,
    });

    await client.from('style_preferences').delete().eq('user_id', user.id);
    final preferences = [
      ...profile.stylePreferences.map(
        (value) => {'user_id': user.id, 'kind': 'style', 'value': value},
      ),
      ...profile.occasions.map(
        (value) => {'user_id': user.id, 'kind': 'occasion', 'value': value},
      ),
    ];
    if (preferences.isNotEmpty) {
      await client.from('style_preferences').insert(preferences);
    }
    try {
      await _cacheCloudProfile(profile, userId: user.id);
    } catch (_) {
      // Cache writes are best effort; remote persistence remains authoritative.
    }
  }

  Future<void> updateDisplayNameIfDefault(String displayName) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final row = await client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();
    final currentName = row?['display_name'] as String?;
    if (currentName == null ||
        currentName.isEmpty ||
        currentName == 'MMM User') {
      await client
          .from('profiles')
          .update({'display_name': displayName})
          .eq('id', user.id);
    }
  }

  Future<void> mergeGuestProfile(UserProfile guest) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError(
        'A signed-in account is required to import a guest account.',
      );
    }

    final existing = await fetchProfile();
    final cloudIsDefault =
        existing == null ||
        (existing.name == 'MMM User' &&
            existing.avatarUrl == null &&
            existing.stylePreferences.isEmpty &&
            existing.occasions.isEmpty &&
            !existing.onboardingComplete &&
            existing.bodyType == null &&
            existing.brandTier == .3 &&
            existing.birthDate == null);
    final merged = cloudIsDefault
        ? guest.copyWith()
        : existing.copyWith(
            stylePreferences: _union(
              existing.stylePreferences,
              guest.stylePreferences,
            ),
            occasions: _union(existing.occasions, guest.occasions),
          );

    await client.from('profiles').upsert({
      ...merged.toProfileJson(),
      'id': user.id,
    });

    final preferences = [
      ...merged.stylePreferences.map(
        (value) => {'user_id': user.id, 'kind': 'style', 'value': value},
      ),
      ...merged.occasions.map(
        (value) => {'user_id': user.id, 'kind': 'occasion', 'value': value},
      ),
    ];
    if (preferences.isNotEmpty) {
      await client
          .from('style_preferences')
          .upsert(
            preferences,
            onConflict: 'user_id,kind,value',
            ignoreDuplicates: true,
          );
    }
    try {
      await _cacheCloudProfile(merged, userId: user.id);
    } catch (_) {
      // Cache writes are best effort; remote persistence remains authoritative.
    }
  }

  List<String> _union(List<String> first, List<String> second) {
    return <String>{
      ...first,
      ...second,
    }.where((value) => value.isNotEmpty).toList();
  }
}
