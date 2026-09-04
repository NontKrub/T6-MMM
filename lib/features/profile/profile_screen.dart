import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/ai_consent_provider.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_surface_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final wardrobe = ref.watch(wardrobeProvider);
    final outfits = ref.watch(outfitsProvider);
    final favorite = wardrobe.isEmpty
        ? '—'
        : wardrobe
              .reduce((a, b) => a.wearCount > b.wearCount ? a : b)
              .name
              .split(' ')
              .first;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.profileTitle ?? 'Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _Stat(
                value: '${wardrobe.length}',
                label: l10n?.profileItems ?? 'Items',
              ),
              const SizedBox(width: AppSpacing.sm),
              _Stat(
                value: '${outfits.map((outfit) => outfit.id).toSet().length}',
                label: l10n?.profileOutfits ?? 'Outfits',
              ),
              const SizedBox(width: AppSpacing.sm),
              _Stat(value: favorite, label: l10n?.profileFavItem ?? 'Fav item'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle(l10n?.profileColorSeason ?? 'Color Season'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: ColorSeason.values
                .map(
                  (season) => MmmChoiceChip(
                    label: season.label,
                    selected: profile.colorSeason == season,
                    onSelected: (_) => ref
                        .read(userProfileProvider.notifier)
                        .updateColorSeason(season),
                  ),
                )
                .toList(),
          ),
          if (profile.stylePreferences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(l10n?.profileStylePreferences ?? 'Style Preferences'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: profile.stylePreferences
                  .map((style) => Chip(label: Text(style)))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const _SectionTitle('Account'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l10n?.profileSignOut ?? 'Sign Out'),
            ),
          ),
          if (SupabaseService.isSignedIn) ...[
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle('Danger zone', destructive: true),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _deleteAccount(context, ref, l10n),
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                label: Text(l10n?.profileDeleteAccount ?? 'Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MmmBrandTheme.of(context).destructive,
                  side: BorderSide(
                    color: MmmBrandTheme.of(context).destructive,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: MmmBrandTheme.of(context).primaryGradient,
          ),
          child: Text(
            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'M',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${profile.colorSeason.label} · ${profile.avatarType.name}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: MmmSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.destructive = false});
  final String title;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: destructive ? MmmBrandTheme.of(context).destructive : null,
    ),
  );
}

Future<void> _deleteAccount(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations? l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n?.profileDeleteAccountTitle ?? 'Delete your account?'),
      content: Text(
        l10n?.profileDeleteAccountMessage ??
            'This permanently removes your profile, wardrobe images, outfits, and activity from MMM.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.itemDeleteCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: MmmBrandTheme.of(context).destructive,
          ),
          child: Text(l10n?.profileDeleteAccountConfirm ?? 'Delete Account'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await AuthService().deleteAccount();
    await LocalAccountRepository().clearGuestAccount();
    ref.invalidate(userProfileProvider);
    ref.invalidate(aiConsentProvider);
    ref.invalidate(sessionProvider);
    ref.invalidate(wardrobeProvider);
    if (!context.mounted) return;
    context.go('/welcome');
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.profileDeleteAccountFailed ?? 'Account deletion failed',
        ),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  if (AppConfig.isSupabaseConfigured) await AuthService().signOut();
  ref.invalidate(userProfileProvider);
  ref.invalidate(aiConsentProvider);
  ref.invalidate(sessionProvider);
  ref.invalidate(wardrobeProvider);
  if (!context.mounted) return;
  context.go('/welcome');
}
