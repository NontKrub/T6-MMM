import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_brand_mark.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_secondary_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  var _startingGuest = false;

  Future<void> _createWardrobe() async {
    setState(() => _startingGuest = true);
    await LocalAccountRepository().startGuestAccount();
    ref.invalidate(sessionProvider);
    await ref.read(userProfileProvider.notifier).load();
    if (!mounted) return;
    context.go('/onboarding', extra: {'isGuest': true});
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.entryScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: l10n?.welcomeLanguageTooltip ?? 'Choose language',
                  child: TextButton.icon(
                    onPressed: () => context.go('/language'),
                    icon: const Icon(Icons.language_rounded, size: 20),
                    label: Text(
                      locale.languageCode == 'th' ? 'ภาษาไทย' : 'English',
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Center(child: MmmBrandWordmark(width: 220)),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n?.welcomeSubtitle ??
                    'Your wardrobe, mixed around your mood.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              Text(
                l10n?.welcomeValueProp ??
                    'Build outfits from the clothes you already own.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              MmmGradientButton(
                label: l10n?.welcomeCreate ?? 'Create my wardrobe',
                onPressed: _startingGuest ? null : _createWardrobe,
                isLoading: _startingGuest,
              ),
              const SizedBox(height: AppSpacing.sm),
              MmmSecondaryButton(
                label: l10n?.welcomeSignIn ?? 'Sign in',
                onPressed: _startingGuest ? null : () => context.go('/auth'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n?.welcomeLocalNote ??
                    'Your local wardrobe stays on this device until you choose to sign in.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _showLegalDialog(
                      context,
                      l10n?.welcomeTerms ?? 'Terms',
                    ),
                    child: Text(l10n?.welcomeTerms ?? 'Terms'),
                  ),
                  Text(
                    '·',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () => _showLegalDialog(
                      context,
                      l10n?.welcomePrivacy ?? 'Privacy',
                    ),
                    child: Text(l10n?.welcomePrivacy ?? 'Privacy'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          l10n?.welcomeLegalNotConfigured ??
              'Legal links will be available before release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.commonClose ?? 'Close'),
          ),
        ],
      ),
    );
  }
}
