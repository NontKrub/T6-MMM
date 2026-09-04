import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/legal_links_service.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/layout/mmm_entry_layout.dart';
import '../../shared/widgets/mmm_brand_mark.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_secondary_button.dart';
import '../auth/auth_entry.dart';

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

    final terms = LegalLinksService.uri(LegalDocument.terms);
    final privacy = LegalLinksService.uri(LegalDocument.privacy);
    return Scaffold(
      body: MmmEntryLayout(
        top: Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: l10n?.welcomeLanguageTooltip ?? 'Choose language',
            child: TextButton.icon(
              onPressed: () => context.go('/language'),
              icon: const Icon(Icons.language_rounded, size: 20),
              label: Text(locale.languageCode == 'th' ? 'ภาษาไทย' : 'English'),
            ),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: MmmBrandWordmark(width: _wordmarkWidth(context))),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n?.welcomeSubtitle ?? 'Your wardrobe, mixed around your mood.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n?.welcomeValueProp ??
                  'Build outfits from the clothes you already own.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n?.welcomeLocalNote ??
                  'Your local wardrobe stays on this device until you choose to sign in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MmmGradientButton(
              label: l10n?.welcomeCreate ?? 'Create my wardrobe',
              onPressed: _startingGuest ? null : _createWardrobe,
              isLoading: _startingGuest,
            ),
            const SizedBox(height: AppSpacing.sm),
            MmmSecondaryButton(
              label: l10n?.welcomeSignIn ?? 'Sign in',
              onPressed: _startingGuest
                  ? null
                  : () => context.go('/auth', extra: const AuthEntry.signIn()),
            ),
            if (terms != null || privacy != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _LegalLinks(terms: terms, privacy: privacy),
            ],
          ],
        ),
      ),
    );
  }

  double _wordmarkWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    if (height < 650 || width < 360) return 190;
    return 220;
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.terms, required this.privacy});

  final Uri? terms;
  final Uri? privacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (terms != null)
          TextButton(
            onPressed: () => _open(context, LegalDocument.terms),
            child: Text(l10n?.welcomeTerms ?? 'Terms'),
          ),
        if (terms != null && privacy != null)
          Text('·', style: TextStyle(color: theme.colorScheme.outline)),
        if (privacy != null)
          TextButton(
            onPressed: () => _open(context, LegalDocument.privacy),
            child: Text(l10n?.welcomePrivacy ?? 'Privacy'),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, LegalDocument document) async {
    if (await LegalLinksService.open(document) || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.legalLinkOpenFailed ??
              'This link could not be opened. Check your connection and try again.',
        ),
      ),
    );
  }
}
