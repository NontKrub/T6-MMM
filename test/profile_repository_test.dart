import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('profile copies can adopt the authenticated cache identity', () {
    const guest = UserProfile(id: 'local_guest', name: 'Nont');

    expect(guest.copyWith(id: 'user-1').id, 'user-1');
    expect(guest.id, 'local_guest');
  });

  test('cached cloud profile is scoped to the signed-in user', () async {
    const profile = UserProfile(
      id: 'user-1',
      name: 'Nont',
      onboardingComplete: true,
      stylePreferences: ['casual'],
      occasions: ['work'],
    );
    SharedPreferences.setMockInitialValues({
      'mmm_cached_cloud_profile': jsonEncode(profile.toJson()),
    });

    final repository = ProfileRepository();
    expect(await repository.fetchCachedCloudProfile('user-1'), isNotNull);
    expect(await repository.fetchCachedCloudProfile('user-2'), isNull);
  });
}
