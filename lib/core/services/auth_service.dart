import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'profile_repository.dart';
import 'supabase_service.dart';

class AppleDeletionCredential {
  const AppleDeletionCredential({
    required this.authorizationCode,
    required this.identityToken,
    required this.rawNonce,
  });

  final String authorizationCode;
  final String identityToken;
  final String rawNonce;

  Map<String, String> toJson() => {
    'apple_authorization_code': authorizationCode,
    'apple_identity_token': identityToken,
    'apple_nonce': rawNonce,
  };
}

class AuthService {
  final ProfileRepository _profiles;

  AuthService({ProfileRepository? profiles})
    : _profiles = profiles ?? ProfileRepository();

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
    if (!AppConfig.enableFacebookAuth) {
      throw StateError('Facebook sign-in is not enabled.');
    }
    await _signInWithOAuth(OAuthProvider.facebook);
  }

  Future<void> signInWithApple() async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Could not find an ID token from the Apple credential.',
      );
    }

    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    final displayName = appleDisplayName(
      credential.givenName,
      credential.familyName,
    );
    if (displayName != null && response.user != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'name': displayName, 'full_name': displayName}),
      );
      await _profiles.updateDisplayNameIfDefault(displayName);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    await client.auth.signInWithOAuth(
      provider,
      redirectTo: AppConfig.authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No signed-in account is available to delete.');
    }

    AppleDeletionCredential? appleCredential;
    final hasAppleIdentity =
        user.identities?.any((identity) => identity.provider == 'apple') ??
        false;
    if (hasAppleIdentity) {
      appleCredential = await _reauthenticateWithApple();
    }

    final response = await client.functions.invoke(
      'delete-account',
      body: appleCredential?.toJson() ?? const <String, String>{},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Account deletion failed (${response.status}).');
    }
    await client.auth.signOut(scope: SignOutScope.local);
  }

  Future<AppleDeletionCredential> _reauthenticateWithApple() async {
    final client = _client!;
    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null || credential.authorizationCode.isEmpty) {
      throw const AuthException(
        'Fresh Sign in with Apple authorization is required to delete the account.',
      );
    }
    return AppleDeletionCredential(
      authorizationCode: credential.authorizationCode,
      identityToken: idToken,
      rawNonce: rawNonce,
    );
  }
}

String? appleDisplayName(String? givenName, String? familyName) {
  final name = [givenName, familyName]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' ');
  return name.isEmpty ? null : name;
}
