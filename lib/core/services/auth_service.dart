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
    required this.rawNonce,
  });

  final String authorizationCode;
  final String rawNonce;

  Map<String, String> toJson() => {
    'apple_authorization_code': authorizationCode,
    'apple_nonce': rawNonce,
  };
}

class AccountDeletionException implements Exception {
  const AccountDeletionException({required this.code, this.status});

  final String code;
  final int? status;
}

class AccountDeletionCoordinator {
  AccountDeletionCoordinator({
    required this.invokeDeletion,
    required this.requestAppleCredential,
  });

  final Future<void> Function(Map<String, String> body) invokeDeletion;
  final Future<AppleDeletionCredential> Function() requestAppleCredential;

  Future<void> deleteAccount() async {
    try {
      await invokeDeletion(const <String, String>{});
      return;
    } on AccountDeletionException catch (error) {
      if (error.code != 'apple_reauthentication_required') rethrow;
    }
    final credential = await requestAppleCredential();
    await invokeDeletion(credential.toJson());
  }
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

  Future<bool> signInWithGoogle() async {
    return _signInWithOAuth(OAuthProvider.google);
  }

  Future<bool> signInWithFacebook() async {
    if (!AppConfig.enableFacebookAuth) {
      throw StateError('Facebook sign-in is not enabled.');
    }
    return _signInWithOAuth(OAuthProvider.facebook);
  }

  Future<bool> signInWithApple() async {
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
    return true;
  }

  Future<bool> _signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    return client.auth.signInWithOAuth(
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
    if (client == null || client.auth.currentUser == null) {
      throw StateError('No signed-in account is available to delete.');
    }

    await AccountDeletionCoordinator(
      invokeDeletion: _invokeDeleteAccount,
      requestAppleCredential: _reauthenticateWithApple,
    ).deleteAccount();
    await client.auth.signOut(scope: SignOutScope.local);
  }

  Future<void> _invokeDeleteAccount(Map<String, String> body) async {
    final client = _client!;
    try {
      final response = await client.functions.invoke(
        'delete-account',
        body: body,
      );
      if (response.status < 200 || response.status >= 300) {
        throw AccountDeletionException(
          code: _functionErrorCode(response.data) ?? 'account_deletion_failed',
          status: response.status,
        );
      }
    } on AccountDeletionException {
      rethrow;
    } on FunctionException catch (error) {
      throw AccountDeletionException(
        code: _functionErrorCode(error.details) ?? 'account_deletion_failed',
        status: error.status,
      );
    } catch (_) {
      throw const AccountDeletionException(code: 'account_deletion_failed');
    }
  }

  String? _functionErrorCode(Object? value) {
    if (value is Map && value['code'] is String) {
      return value['code'] as String;
    }
    return null;
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
    if (credential.authorizationCode.isEmpty) {
      throw const AuthException(
        'Fresh Sign in with Apple authorization is required to delete the account.',
      );
    }
    return AppleDeletionCredential(
      authorizationCode: credential.authorizationCode,
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
