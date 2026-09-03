class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'mmm://login-callback',
  );
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const enableFacebookAuth = bool.fromEnvironment(
    'ENABLE_FACEBOOK_AUTH',
    defaultValue: false,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
