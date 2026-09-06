import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import '../services/profile_repository.dart';
import '../../shared/models/user_profile.dart';
import 'avatar_customization_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier(ref, ref.read(profileRepositoryProvider));
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._ref, [ProfileRepository? repository])
    : _repository = repository ?? ProfileRepository(),
      super(
        const UserProfile(
          id: 'local_guest',
          name: 'Guest',
          colorSeason: ColorSeason.spring,
          avatarType: AvatarType.human,
          onboardingComplete: false,
        ),
      ) {
    _loadProfile(initial: true);
  }

  final dynamic _ref;
  final ProfileRepository _repository;
  Future<void> _writeQueue = Future.value();
  int _loadGeneration = 0;
  int _mutationGeneration = 0;

  Future<void> load() => _loadProfile(initial: false);

  Future<void> _loadProfile({required bool initial}) async {
    final requestGeneration = ++_loadGeneration;
    final mutationGeneration = _mutationGeneration;
    try {
      final profile = await _repository.fetchProfile();
      if (profile == null ||
          !mounted ||
          requestGeneration != _loadGeneration ||
          (initial && mutationGeneration != _mutationGeneration)) {
        return;
      }
      state = profile;
      if (_ref == null || !mounted) return;
      _ref.read(skinToneIndexProvider.notifier).state = profile.skinToneIndex;
      _ref.read(hairColorIndexProvider.notifier).state = profile.hairColorIndex;
      _ref.read(bodyShapeProvider.notifier).state = profile.bodyShape;
      _ref.read(hairStyleIndexProvider.notifier).state = profile.hairStyleIndex;
    } catch (_) {}
  }

  void _markMutation() => _mutationGeneration++;

  void _persist() {
    unawaited(_enqueue(() => _repository.upsertProfile(state)));
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _writeQueue.then((_) => operation());
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        debugPrint('Profile persistence failed: $error');
      },
    );
    return result;
  }

  Future<void> _saveProfileMutation(
    UserProfile Function(UserProfile current) mutation,
  ) {
    _markMutation();
    return _enqueue(() async {
      final updated = mutation(state);
      await _repository.upsertProfile(updated);
      if (mounted) state = updated;
    });
  }

  Future<void> saveColorSeason(ColorSeason season) =>
      _saveProfileMutation((current) => current.copyWith(colorSeason: season));

  Future<void> saveStylePreferences(List<String> prefs) => _saveProfileMutation(
    (current) => current.copyWith(stylePreferences: prefs.toList()),
  );

  Future<void> saveOccasions(List<String> occasions) => _saveProfileMutation(
    (current) => current.copyWith(occasions: occasions.toList()),
  );

  Future<void> flush() => _writeQueue;

  Future<void> updateIdentity({
    required String displayName,
    required ProfileAvatarMode avatarMode,
    String? avatarPath,
    Uint8List? customAvatarBytes,
    String customAvatarName = 'profile.png',
  }) async {
    _markMutation();
    await flush();
    final updated = await _repository.updateIdentity(
      displayName: displayName,
      avatarMode: avatarMode,
      avatarPath: avatarPath,
      customAvatarBytes: customAvatarBytes,
      customAvatarName: customAvatarName,
    );
    if (mounted) state = updated;
  }

  void updateColorSeason(ColorSeason season) {
    _updateAndPersist((current) => current.copyWith(colorSeason: season));
  }

  void updateAvatarType(AvatarType type) {
    _updateAndPersist((current) => current.copyWith(avatarType: type));
  }

  void updateStylePreferences(List<String> prefs) {
    _updateAndPersist((current) => current.copyWith(stylePreferences: prefs));
  }

  void updateOccasions(List<String> occasions) {
    _updateAndPersist((current) => current.copyWith(occasions: occasions));
  }

  void completeOnboarding() {
    _updateAndPersist((current) => current.copyWith(onboardingComplete: true));
  }

  void updateName(String name) {
    _updateAndPersist((current) => current.copyWith(name: name));
  }

  void updateBirthDate(DateTime date) {
    _updateAndPersist(
      (current) =>
          current.copyWith(birthDate: date, birthWeekday: date.weekday),
    );
  }

  void updateOnboardingDetails({
    String? bodyType,
    ColorSeason? colorSeason,
    double? brandTier,
  }) {
    _updateAndPersist(
      (current) => current.copyWith(
        bodyType: bodyType,
        colorSeason: colorSeason,
        brandTier: brandTier,
      ),
    );
  }

  void updateBodyShape(AvatarBodyShape shape) {
    _updateAndPersist((current) => current.copyWith(bodyShape: shape));
  }

  void updateSkinToneIndex(int i) {
    _updateAndPersist((current) => current.copyWith(skinToneIndex: i));
  }

  void updateHairColorIndex(int i) {
    _updateAndPersist((current) => current.copyWith(hairColorIndex: i));
  }

  void updateHairStyleIndex(int i) {
    _updateAndPersist((current) => current.copyWith(hairStyleIndex: i));
  }

  void _updateAndPersist(UserProfile Function(UserProfile current) mutation) {
    _markMutation();
    state = mutation(state);
    _persist();
  }
}
