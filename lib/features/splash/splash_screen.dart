import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/services/profile_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_brand_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
    final hasChosenLanguage = await LocaleNotifier.hasChosenLanguage();
    if (!mounted) return;
    if (!hasChosenLanguage) {
      context.go('/language');
      return;
    }

    final profile = SupabaseService.isSignedIn
        ? await ProfileRepository().fetchProfile()
        : await LocalAccountRepository().fetchProfile();
    if (!mounted) return;
    if (profile?.onboardingComplete ?? false) {
      context.go('/home');
    } else if (SupabaseService.isSignedIn) {
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
