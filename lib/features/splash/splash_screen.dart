import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final hasChosen = await LocaleNotifier.hasChosenLanguage();
      if (!mounted) return;
      if (!hasChosen) {
        context.go('/language');
        return;
      }
      final localAccount = LocalAccountRepository();
      final profile = await localAccount.fetchProfile();
      if (!mounted) return;
      if (SupabaseService.isSignedIn) {
        context.go('/home');
      } else if (profile != null && profile.onboardingComplete) {
        context.go('/home');
      } else {
        context.go('/auth');
      }
    });
  }

  String _tagline(BuildContext ctx) =>
      AppLocalizations.of(ctx)?.appTagline ??
      'match your wardrobe to your mood';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0E1A), Color(0xFF1A0E2E), Color(0xFF0E1A2E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo mark
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.seedColor.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              Text(
                    'Mix Match Mood',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Builder(
                builder: (ctx) => Text(
                  _tagline(ctx),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 60),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.seedColor.withValues(alpha: 0.6),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
