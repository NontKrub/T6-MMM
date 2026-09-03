import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/ai_consent_provider.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/guest_account_migration_service.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    if (AppConfig.isSupabaseConfigured) {
      _authSub = AuthService().authStateChanges.listen(_onAuthStateChange);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChange(AuthState authState) async {
    if (authState.event != AuthChangeEvent.signedIn) return;
    ref.invalidate(aiConsentProvider);
    await ref.read(userProfileProvider.notifier).load();
    final migration = GuestAccountMigrationService();
    if (await migration.hasPendingMigration() && mounted) {
      final shouldImport = await _askToImportGuestData();
      if (shouldImport) {
        final result = await _runGuestMigration(migration);
        if (result.completed) {
          await ref.read(userProfileProvider.notifier).load();
          ref.invalidate(wardrobeProvider);
          ref.invalidate(outfitsProvider);
        } else if (mounted && result.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.authImportFailed ?? 'Local wardrobe import failed'}: ${result.error}',
              ),
            ),
          );
        }
      }
    }
    final profile = ref.read(userProfileProvider);
    if (!mounted) return;
    context.go(profile.onboardingComplete ? '/home' : '/onboarding');
  }

  Future<bool> _askToImportGuestData() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(
                l10n?.authImportGuestTitle ?? 'Import your guest wardrobe?',
              ),
              content: Text(
                l10n?.authImportGuestMessage ??
                    'MMM found a local guest wardrobe. Import it into this signed-in account?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n?.authContinueWithoutImport ?? 'Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n?.authImportGuest ?? 'Import wardrobe'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<GuestMigrationResult> _runGuestMigration(
    GuestAccountMigrationService migration,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.authImportingGuest ??
                    'Importing local wardrobe…',
              ),
            ),
          ],
        ),
      ),
    );
    final result = await migration.migrate();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    return result;
  }

  Future<void> _handleGuestLogin() async {
    await LocalAccountRepository().startGuestAccount();
    ref.invalidate(sessionProvider);
    await ref.read(userProfileProvider.notifier).load();
    if (!mounted) return;
    context.go('/onboarding', extra: {'isGuest': true});
  }

  Future<void> _handleOAuth(Future<void> Function() action) async {
    if (!AppConfig.isSupabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.authUnavailable ??
                'Sign in is unavailable until Supabase is configured.',
          ),
        ),
      );
      return;
    }
    try {
      await action();
      // Navigation is handled by _onAuthStateChange once the deep-link
      // callback returns the session to the app.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final showApple = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient + orbs
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0E1A),
                  Color(0xFF1A0E2E),
                  Color(0xFF0E1A2E),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.seedColor.withValues(alpha: 0.3),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GlowOrb(
              color: AppColors.gradientEnd.withValues(alpha: 0.2),
              size: 320,
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.1),
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 28),
                  Text(
                        l10n?.authHeroTitle ?? 'Your wardrobe,\nreimagined.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                      )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.authHeroSubtitle ??
                        'AI-powered outfit suggestions,\npersonalized just for you.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
                  const Spacer(),
                  // Auth buttons
                  GlassContainer(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n?.authGetStarted ?? 'Get started',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (showApple) ...[
                              _SocialButton(
                                icon: Icons.apple,
                                label:
                                    l10n?.authContinueWithApple ??
                                    'Continue with Apple',
                                onTap: () =>
                                    _handleOAuth(AuthService().signInWithApple),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label:
                                  l10n?.authContinueWithGoogle ??
                                  'Continue with Google',
                              onTap: () =>
                                  _handleOAuth(AuthService().signInWithGoogle),
                            ),
                            if (AppConfig.enableFacebookAuth) ...[
                              const SizedBox(height: 16),
                              _SocialButton(
                                icon: Icons.facebook,
                                label:
                                    l10n?.authContinueWithFacebook ??
                                    'Continue with Facebook',
                                onTap: () => _handleOAuth(
                                  AuthService().signInWithFacebook,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _handleGuestLogin,
                              child: Text(
                                l10n?.authContinueAsGuest ??
                                    'Continue as guest',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
