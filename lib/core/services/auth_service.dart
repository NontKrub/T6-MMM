import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient? get _client => SupabaseService.client;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange;
  }

  User? get currentUser => _client?.auth.currentUser;

  Future<void> signInWithGoogle() async {
    await _signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithFacebook() async {
    await _signInWithOAuth(OAuthProvider.facebook);
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await client.auth.signInWithOAuth(
      provider,
      redirectTo: AppConfig.authRedirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
