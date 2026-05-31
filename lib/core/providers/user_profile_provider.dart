import 'package:flutter_riverpod/legacy.dart';
import '../services/profile_repository.dart';
import '../../shared/models/user_profile.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier();
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
    : super(
        const UserProfile(
          id: 'mock_user',
          name: 'Alex',
          colorSeason: ColorSeason.winter,
          avatarType: AvatarType.human,
          stylePreferences: ['Minimal', 'Casual'],
          occasions: ['Work', 'Weekend'],
          onboardingComplete: false,
        ),
      ) {
    load();
  }

  final _repository = ProfileRepository();

  Future<void> load() async {
    try {
      final profile = await _repository.fetchProfile();
      if (profile != null) state = profile;
    } catch (_) {}
  }

  void _persist() {
    _repository.upsertProfile(state);
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
}
