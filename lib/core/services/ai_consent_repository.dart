import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AiConsentPolicy {
  static const type = 'third_party_ai';
  static const currentVersion = '2026-09-04-v1';
}

class AiConsentRepository {
  AiConsentRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  Future<bool> hasCurrentConsent() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;
    final rows = await client
        .from('user_consents')
        .select('user_id')
        .eq('user_id', user.id)
        .eq('consent_type', AiConsentPolicy.type)
        .eq('policy_version', AiConsentPolicy.currentVersion)
        .isFilter('revoked_at', null)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> grantCurrentConsent() async {
    final client = _requiredClient;
    final user = client.auth.currentUser!;
    await client.from('user_consents').upsert({
      'user_id': user.id,
      'consent_type': AiConsentPolicy.type,
      'policy_version': AiConsentPolicy.currentVersion,
      'granted_at': DateTime.now().toUtc().toIso8601String(),
      'revoked_at': null,
    });
  }

  Future<void> revokeCurrentConsent() async {
    final client = _requiredClient;
    final user = client.auth.currentUser!;
    await client
        .from('user_consents')
        .update({'revoked_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', user.id)
        .eq('consent_type', AiConsentPolicy.type)
        .eq('policy_version', AiConsentPolicy.currentVersion)
        .isFilter('revoked_at', null);
  }

  SupabaseClient get _requiredClient {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('A signed-in account is required for AI consent.');
    }
    return client;
  }
}
