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
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_brand_mark.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/layout/mmm_entry_layout.dart';
import 'auth_entry.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.entry = const AuthEntry.signIn()});

  final AuthEntry entry;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  StreamSubscription<AuthState>? _authSub;
  String? _authenticatingProvider;
  var _waitingForOAuthCallback = false;
  var _routingAfterAuth = false;

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
    if (authState.event != AuthChangeEvent.signedIn || _routingAfterAuth) {
      return;
    }
    _routingAfterAuth = true;
    if (mounted) {
      setState(() {
        _authenticatingProvider = null;
        _waitingForOAuthCallback = false;
      });
    }
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
    final returnLocation = widget.entry.safeReturnLocation;
    if (profile.onboardingComplete) {
      context.go(returnLocation ?? '/home');
    } else {
      context.go(
        '/onboarding',
        extra: {'isGuest': false, 'returnLocation': returnLocation},
      );
    }
  }

  Future<void> _showMigrationWarnings(GuestMigrationResult result) async {
    await MmmDialog.show<void>(
      context: context,
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
    );
  }

  Future<bool> _askToImportGuestData() async {
    return await MmmDialog.show<bool>(
          context: context,
          title: Text(
            AppLocalizations.of(context)?.authImportGuestTitle ??
                'Import your guest wardrobe?',
          ),
          content: Text(
            AppLocalizations.of(context)?.authImportGuestMessage ??
                'MMM found a local guest wardrobe. Import it into this signed-in account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)?.authContinueWithoutImport ??
                    'Not now',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)?.authImportGuest ??
                    'Import wardrobe',
              ),
            ),
          ],
        ) ??
        false;
  }

  Future<GuestMigrationResult> _runGuestMigration(
    GuestAccountMigrationService migration,
  ) async {
    MmmDialog.show<void>(
      context: context,
      barrierDismissible: false,
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.authImportingGuest ??
                  'Importing local wardrobe…',
            ),
          ),
        ],
      ),
    );
    final result = await migration.migrate();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    return result;
  }

  Future<void> _handleOAuth(
    String provider,
    Future<bool> Function() action, {
    bool waitsForCallback = false,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      _showMessage(
        AppLocalizations.of(context)?.authUnavailable ??
            'Sign in is unavailable until Supabase is configured.',
      );
      return;
    }
    setState(() {
      _authenticatingProvider = provider;
      _waitingForOAuthCallback = false;
    });
    try {
      final launched = await action();
      if (!launched) {
        if (!mounted) return;
        setState(() {
          _authenticatingProvider = null;
          _waitingForOAuthCallback = false;
        });
        _showMessage(
          AppLocalizations.of(context)?.authRetryMessage ??
              'Sign in could not be started. Please try again.',
        );
        return;
      }
      if (mounted && waitsForCallback) {
        setState(() => _waitingForOAuthCallback = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _authenticatingProvider = null;
          _waitingForOAuthCallback = false;
        });
        _showMessage(
          AppLocalizations.of(context)?.authRetryMessage ??
              'Sign in could not be completed. Please try again.',
        );
      }
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
    final unlockAi = widget.entry.intent == AuthIntent.unlockAi;
    final title = unlockAi
        ? (l10n?.authUnlockAiTitle ?? 'Sign in to use Fashion AI')
        : (l10n?.authSignInTitle ?? 'Sign in to MMM');
    final subtitle = unlockAi
        ? (l10n?.authUnlockAiSubtitle ??
              'Connect an account to use MMM Stylist with cloud AI features.')
        : (l10n?.authSignInSubtitle ??
              'Access your wardrobe across supported cloud features.');

    return Scaffold(
      body: MmmEntryLayout(
        top: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: l10n?.authBack ?? 'Back',
            onPressed: isBusy ? null : _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: MmmBrandMark(size: _entryMarkSize(context))),
            const SizedBox(height: AppSpacing.xxl),
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
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
              provider: _AuthProvider.google,
              label: l10n?.authContinueWithGoogle ?? 'Continue with Google',
              loading: _authenticatingProvider == 'google',
              enabled: !isBusy,
              onPressed: () => _handleOAuth(
                'google',
                AuthService().signInWithGoogle,
                waitsForCallback: true,
              ),
            ),
            if (AppConfig.enableFacebookAuth) ...[
              const SizedBox(height: AppSpacing.sm),
              _ProviderButton(
                provider: _AuthProvider.facebook,
                label:
                    l10n?.authContinueWithFacebook ?? 'Continue with Facebook',
                loading: _authenticatingProvider == 'facebook',
                enabled: !isBusy,
                onPressed: () => _handleOAuth(
                  'facebook',
                  AuthService().signInWithFacebook,
                  waitsForCallback: true,
                ),
              ),
            ],
            if (_waitingForOAuthCallback) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n?.authExternalPending ??
                    'Continue in the browser to finish signing in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        footer: TextButton(
          onPressed: isBusy ? null : _goBack,
          child: Text(
            unlockAi
                ? (l10n?.authBackToChat ?? 'Back to Chat')
                : (l10n?.authBackToWelcome ?? 'Back to welcome'),
          ),
        ),
      ),
    );
  }

  double _entryMarkSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    if (AppBreakpoints.veryLargeText(context) || height < 650) return 108;
    if (width < 360 || AppBreakpoints.largeText(context)) return 124;
    return 148;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
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
              height: 48,
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

enum _AuthProvider { google, facebook }

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final _AuthProvider provider;
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = provider == _AuthProvider.google
        ? _GoogleIdentityIcon()
        : const Icon(Icons.facebook, size: 22);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  icon,
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}

class _GoogleIdentityIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: Image.asset(
      'assets/images/google_g_logo.png',
      width: 18,
      height: 18,
      filterQuality: FilterQuality.high,
    ),
  );
}
