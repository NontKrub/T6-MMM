import '../../shared/models/user_profile.dart';
import 'local_account_repository.dart';
import 'supabase_service.dart';

class ProfileRepository {
  final _local = LocalAccountRepository();

  Future<UserProfile?> fetchProfile() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return _local.fetchProfile();

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

    return UserProfile.fromJson(
      Map<String, dynamic>.from(profileRow),
      styles: styles,
      occasions: occasions,
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final client = SupabaseService.client;
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
  }
}
