import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/services/profile_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/mmm_brand_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.loadProfile,
    this.hasChosenLanguage,
    this.signedIn,
    this.profileTimeout = const Duration(seconds: 4),
  });

  final Future<UserProfile?> Function()? loadProfile;
  final Future<bool> Function()? hasChosenLanguage;
  final bool? signedIn;
  final Duration profileTimeout;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    bool hasChosenLanguage;
    try {
      hasChosenLanguage =
          await (widget.hasChosenLanguage ??
              LocaleNotifier.hasChosenLanguage)();
    } catch (error) {
      debugPrint('Splash language state failed: $error');
      if (!mounted) return;
      context.go('/language');
      return;
    }
    if (!mounted) return;
    if (!hasChosenLanguage) {
      context.go('/language');
      return;
    }

    final signedIn = widget.signedIn ?? SupabaseService.isSignedIn;
    var profileLoadFailed = false;
    UserProfile? profile;
    try {
      profile =
          await (widget.loadProfile ??
                  (signedIn
                      ? ProfileRepository().fetchProfile
                      : LocalAccountRepository().fetchProfile))()
              .timeout(widget.profileTimeout);
    } catch (error) {
      profileLoadFailed = true;
      debugPrint('Splash profile load failed: $error');
    }
    if (!mounted) return;
    if (profile?.onboardingComplete ?? false) {
      context.go('/home');
    } else if (signedIn && profileLoadFailed) {
      // A signed-in user can still use cached/local data when the network is down.
      context.go('/home');
    } else if (signedIn) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: l10n?.splashLoading ?? 'Loading Mix Match Mood',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MmmBrandWordmark(width: 220),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              Text(
                l10n?.appTagline ?? 'Match your wardrobe to your mood',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
