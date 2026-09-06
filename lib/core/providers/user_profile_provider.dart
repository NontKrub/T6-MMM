import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import '../services/profile_repository.dart';
import '../../shared/models/user_profile.dart';
import 'avatar_customization_provider.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier(ref);
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._ref)
    : super(
        const UserProfile(
          id: 'local_guest',
          name: 'Guest',
          colorSeason: ColorSeason.spring,
          avatarType: AvatarType.human,
          onboardingComplete: false,
        ),
      ) {
    load();
  }

  final dynamic _ref;
  final _repository = ProfileRepository();
  Future<void> _writeQueue = Future.value();

  Future<void> load() async {
    try {
      final profile = await _repository.fetchProfile();
      if (profile != null) {
        state = profile;
        _ref.read(skinToneIndexProvider.notifier).state = profile.skinToneIndex;
        _ref.read(hairColorIndexProvider.notifier).state =
            profile.hairColorIndex;
        _ref.read(bodyShapeProvider.notifier).state = profile.bodyShape;
        _ref.read(hairStyleIndexProvider.notifier).state =
            profile.hairStyleIndex;
      }
    } catch (_) {}
  }

  void _persist() {
    final snapshot = state;
    _writeQueue = _writeQueue
        .then((_) => _repository.upsertProfile(snapshot))
        .catchError((_) {});
  }

  Future<void> flush() => _writeQueue;

  Future<void> updateIdentity({
    required String displayName,
    required ProfileAvatarMode avatarMode,
    String? avatarPath,
    Uint8List? customAvatarBytes,
    String customAvatarName = 'profile.png',
  }) async {
    await flush();
    final updated = await _repository.updateIdentity(
      displayName: displayName,
      avatarMode: avatarMode,
      avatarPath: avatarPath,
      customAvatarBytes: customAvatarBytes,
      customAvatarName: customAvatarName,
    );
    state = updated;
  }

  void updateColorSeason(ColorSeason season) {
    state = state.copyWith(colorSeason: season);
    _persist();
  }

  void updateAvatarType(AvatarType type) {
    state = state.copyWith(avatarType: type);
    _persist();
  }

  void updateStylePreferences(List<String> prefs) {
    state = state.copyWith(stylePreferences: prefs);
    _persist();
  }

  void updateOccasions(List<String> occasions) {
    state = state.copyWith(occasions: occasions);
    _persist();
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
    _persist();
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
    _persist();
  }

  void updateBirthDate(DateTime date) {
    state = state.copyWith(birthDate: date, birthWeekday: date.weekday);
    _persist();
  }

  void updateOnboardingDetails({
    String? bodyType,
    ColorSeason? colorSeason,
    double? brandTier,
  }) {
    state = state.copyWith(
      bodyType: bodyType,
      colorSeason: colorSeason,
      brandTier: brandTier,
    );
    _persist();
  }

  void updateBodyShape(AvatarBodyShape shape) {
    state = state.copyWith(bodyShape: shape);
    _persist();
  }

  void updateSkinToneIndex(int i) {
    state = state.copyWith(skinToneIndex: i);
    _persist();
  }

  void updateHairColorIndex(int i) {
    state = state.copyWith(hairColorIndex: i);
    _persist();
  }

  void updateHairStyleIndex(int i) {
    state = state.copyWith(hairStyleIndex: i);
    _persist();
  }
}
