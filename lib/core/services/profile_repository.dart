import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/user_profile.dart';
import 'local_account_repository.dart';
import 'profile_image_storage_service.dart';
import 'supabase_service.dart';
import 'wardrobe_repository.dart';

const _profileImageUuid = Uuid();

class ProfileRepository {
  ProfileRepository({
    SupabaseClient? client,
    ProfileImageStorageService? imageStorage,
  }) : _clientOverride = client,
       _imageStorage = imageStorage ?? ProfileImageStorageService();

  final SupabaseClient? _clientOverride;
  final ProfileImageStorageService _imageStorage;
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
      return _resolveAvatar(profile, client);
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

  Future<UserProfile> updateIdentity({
    required String displayName,
    required ProfileAvatarMode avatarMode,
    String? avatarPath,
    Uint8List? customAvatarBytes,
    String customAvatarName = 'profile.png',
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) throw ArgumentError.value(displayName, 'displayName');
    final current =
        await fetchProfile() ??
        const UserProfile(id: 'local_guest', name: 'Guest');
    final client = _client;
    final user = client?.auth.currentUser;
    final oldPath = current.avatarMode == ProfileAvatarMode.custom
        ? current.avatarPath
        : null;
    var newPath = avatarPath;
    String? localNewPath;
    var uploadedCloudPath = false;

    if (avatarMode == ProfileAvatarMode.custom && customAvatarBytes != null) {
      final normalized = await _imageStorage.normalize(customAvatarBytes);
      if (client == null || user == null) {
        final file = await _imageStorage.persist(
          customAvatarBytes,
          customAvatarName,
        );
        newPath = file.path;
        localNewPath = newPath;
      } else {
        newPath = _cloudAvatarPath(user.id);
        try {
          await client.storage
              .from(WardrobeRepository.bucket)
              .uploadBinary(
                newPath,
                normalized,
                fileOptions: const FileOptions(
                  upsert: false,
                  contentType: 'image/png',
                ),
              );
          uploadedCloudPath = true;
        } catch (_) {
          await _deleteCloudAvatar(client, newPath);
          rethrow;
        }
      }
    }

    if (avatarMode == ProfileAvatarMode.custom &&
        customAvatarBytes == null &&
        newPath != null) {
      if (client == null || user == null) {
        if (!await _imageStorage.owns(newPath)) {
          throw StateError('The local profile image is not owned by MMM.');
        }
      } else if (!newPath.startsWith('${user.id}/profile/')) {
        throw StateError('The cloud profile image path is invalid.');
      }
    }

    if (avatarMode == ProfileAvatarMode.custom &&
        (newPath == null || newPath.isEmpty)) {
      throw StateError('A custom profile photo is required.');
    }
    if (avatarMode == ProfileAvatarMode.provider &&
        (current.avatarUrl == null || current.avatarUrl!.isEmpty)) {
      throw StateError('No account photo is available.');
    }

    final updated = current.copyWith(
      id: user?.id ?? current.id,
      name: name,
      avatarMode: avatarMode,
      avatarPath: avatarMode == ProfileAvatarMode.custom ? newPath : null,
      avatarDisplayUrl:
          avatarMode == ProfileAvatarMode.custom &&
              newPath != null &&
              (newPath.startsWith('/') || newPath.startsWith('file://'))
          ? newPath
          : null,
    );

    try {
      if (client == null || user == null) {
        await _local.upsertProfile(updated);
      } else {
        final rows = await client
            .from('profiles')
            .update({
              'display_name': name,
              'avatar_mode': avatarMode.name,
              'avatar_path': avatarMode == ProfileAvatarMode.custom
                  ? newPath
                  : null,
            })
            .eq('id', user.id)
            .select('id');
        if (rows.isEmpty) {
          throw StateError('The signed-in profile was not found.');
        }
      }
    } catch (error) {
      if (uploadedCloudPath && newPath != null) {
        await _deleteCloudAvatar(client, newPath);
      }
      if (localNewPath != null) {
        await _imageStorage.deleteOwned(localNewPath);
      }
      rethrow;
    }

    if (oldPath != null && oldPath != newPath) {
      if (client == null || user == null) {
        await _imageStorage.deleteOwned(oldPath);
      } else {
        await _deleteCloudAvatar(client, oldPath);
      }
    }

    final resolved = client == null || user == null
        ? updated
        : await _resolveAvatar(updated, client);
    if (client != null && user != null) {
      try {
        await _cacheCloudProfile(resolved, userId: user.id);
      } catch (_) {}
    }
    return resolved;
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

  Future<void> mergeGuestProfile(
    UserProfile guest, {
    Uint8List? guestAvatarBytes,
  }) async {
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
            existing.avatarMode == ProfileAvatarMode.none &&
            existing.avatarPath == null &&
            existing.stylePreferences.isEmpty &&
            existing.occasions.isEmpty &&
            !existing.onboardingComplete &&
            existing.bodyType == null &&
            existing.brandTier == .3 &&
            existing.birthDate == null);
    var merged = cloudIsDefault
        ? guest.copyWith()
        : existing.copyWith(
            stylePreferences: _union(
              existing.stylePreferences,
              guest.stylePreferences,
            ),
            occasions: _union(existing.occasions, guest.occasions),
          );

    String? uploadedCloudPath;
    if (cloudIsDefault &&
        guest.avatarMode == ProfileAvatarMode.custom &&
        guestAvatarBytes != null) {
      uploadedCloudPath = _cloudAvatarPath(user.id);
      try {
        final normalized = await _imageStorage.normalize(guestAvatarBytes);
        await client.storage
            .from(WardrobeRepository.bucket)
            .uploadBinary(
              uploadedCloudPath,
              normalized,
              fileOptions: const FileOptions(
                upsert: false,
                contentType: 'image/png',
              ),
            );
        merged = merged.copyWith(avatarPath: uploadedCloudPath);
      } catch (_) {
        await _deleteCloudAvatar(client, uploadedCloudPath);
        rethrow;
      }
    } else if (cloudIsDefault && guest.avatarMode == ProfileAvatarMode.custom) {
      merged = merged.copyWith(
        avatarMode: ProfileAvatarMode.none,
        avatarPath: null,
      );
    }

    try {
      await client.from('profiles').upsert({
        ...merged.toProfileJson(),
        'id': user.id,
      });
    } catch (error) {
      if (uploadedCloudPath != null) {
        await _deleteCloudAvatar(client, uploadedCloudPath);
      }
      rethrow;
    }

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

  String _cloudAvatarPath(String userId) =>
      '$userId/profile/avatar-${_profileImageUuid.v4()}.png';

  Future<UserProfile> _resolveAvatar(
    UserProfile profile,
    SupabaseClient client,
  ) async {
    if (profile.avatarMode != ProfileAvatarMode.custom ||
        profile.avatarPath == null ||
        profile.avatarPath!.isEmpty) {
      return profile;
    }
    try {
      final url = await client.storage
          .from(WardrobeRepository.bucket)
          .createSignedUrl(profile.avatarPath!, 60 * 60);
      return profile.copyWith(avatarDisplayUrl: url);
    } catch (error) {
      debugPrint('Unable to resolve profile avatar: $error');
      return profile;
    }
  }

  Future<void> _deleteCloudAvatar(SupabaseClient? client, String path) async {
    if (client == null || path.isEmpty) return;
    try {
      await client.storage.from(WardrobeRepository.bucket).remove([path]);
    } catch (error) {
      debugPrint('Unable to clean old profile avatar: $error');
    }
  }
}
