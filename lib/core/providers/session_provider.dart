import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/local_account_repository.dart';
import '../services/supabase_service.dart';

class AppSession {
  final bool hasGuestAccount;
  final bool isSupabaseAuthenticated;

  const AppSession({
    required this.hasGuestAccount,
    required this.isSupabaseAuthenticated,
  });

  bool get isGuest => hasGuestAccount && !isSupabaseAuthenticated;
  bool get requiresLoginForAi => !isSupabaseAuthenticated;
}

final sessionProvider = FutureProvider<AppSession>((ref) async {
  return AppSession(
    hasGuestAccount: await LocalAccountRepository().hasGuestAccount(),
    isSupabaseAuthenticated: SupabaseService.isSignedIn,
  );
});

final authUnavailableMessageProvider = Provider<String?>((ref) {
  if (AppConfig.isSupabaseConfigured) return null;
  return 'Sign in is unavailable until Supabase is configured.';
});
