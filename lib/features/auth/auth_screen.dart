import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/ai_consent_provider.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/guest_account_migration_service.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_brand_mark.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  StreamSubscription<AuthState>? _authSub;
  String? _authenticatingProvider;

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
          if (result.warnings.isNotEmpty && mounted) {
            await _showMigrationWarnings(result);
          }
        } else if (mounted && result.error != null) {
          _showMessage(
            AppLocalizations.of(context)?.authImportFailed ??
                'Local wardrobe import failed. Try again later.',
          );
        }
      }
    }
    final profile = ref.read(userProfileProvider);
    if (!mounted) return;
    context.go(profile.onboardingComplete ? '/home' : '/onboarding');
  }

  Future<void> _showMigrationWarnings(GuestMigrationResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.authImportWarningsTitle ??
              'Wardrobe imported with warnings',
        ),
        content: Text(
          'Some guest history could not be imported:\n\n${result.warnings.map((warning) => '• $warning').join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.dialogClose ?? 'Close'),
          ),
        ],
      ),
    );
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
            SizedBox(width: AppSpacing.lg),
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

  Future<void> _handleOAuth(
    String provider,
    Future<void> Function() action,
  ) async {
    if (!AppConfig.isSupabaseConfigured) {
      _showMessage(
        AppLocalizations.of(context)?.authUnavailable ??
            'Sign in is unavailable until Supabase is configured.',
      );
      return;
    }
    setState(() => _authenticatingProvider = provider);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context)?.authRetryMessage ??
              'Sign in could not be completed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _authenticatingProvider = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showApple = Theme.of(context).platform == TargetPlatform.iOS;
    final isBusy = _authenticatingProvider != null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.entryScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: l10n?.authBack ?? 'Back',
                  onPressed: isBusy ? null : () => context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const Spacer(),
              const MmmBrandMark(size: 150),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n?.welcomeAuthTitle ?? 'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n?.welcomeAuthSubtitle ?? 'Your wardrobe is waiting.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (showApple) ...[
                _AppleButton(
                  isLoading: _authenticatingProvider == 'apple',
                  enabled: !isBusy,
                  label: l10n?.authContinueWithApple ?? 'Continue with Apple',
                  onPressed: () =>
                      _handleOAuth('apple', AuthService().signInWithApple),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _ProviderButton(
                icon: Icons.g_mobiledata_rounded,
                label: l10n?.authContinueWithGoogle ?? 'Continue with Google',
                loading: _authenticatingProvider == 'google',
                enabled: !isBusy,
                onPressed: () =>
                    _handleOAuth('google', AuthService().signInWithGoogle),
              ),
              if (AppConfig.enableFacebookAuth) ...[
                const SizedBox(height: AppSpacing.sm),
                _ProviderButton(
                  icon: Icons.facebook,
                  label:
                      l10n?.authContinueWithFacebook ??
                      'Continue with Facebook',
                  loading: _authenticatingProvider == 'facebook',
                  enabled: !isBusy,
                  onPressed: () => _handleOAuth(
                    'facebook',
                    AuthService().signInWithFacebook,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: isBusy ? null : () => context.go('/welcome'),
                child: Text(
                  l10n?.welcomeNewToMmm ?? 'New to MMM? Create a wardrobe',
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({
    required this.isLoading,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    child: IgnorePointer(
      ignoring: !enabled,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isLoading ? 0 : 1,
            child: SignInWithAppleButton(
              onPressed: onPressed,
              text: label,
              height: 52,
              borderRadius: AppRadii.controlBorder,
              style: Theme.of(context).brightness == Brightness.dark
                  ? SignInWithAppleButtonStyle.white
                  : SignInWithAppleButtonStyle.black,
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    ),
  );
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.controlBorder,
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: AppSpacing.xs),
                Text(label),
              ],
            ),
    ),
  );
}
