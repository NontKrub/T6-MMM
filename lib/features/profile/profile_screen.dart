import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final wardrobe = ref.watch(wardrobeProvider);
    final outfits = ref.watch(outfitsProvider);
    final uniqueOutfitIds = outfits.map((outfit) => outfit.id).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.profileTitle ?? 'Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & name header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.colorSeason.label} · ${profile.avatarType.name}',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            // Stats
            Row(
              children: [
                _StatCard(
                  value: '${wardrobe.length}',
                  label: l10n?.profileItems ?? 'Items',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  value: '${uniqueOutfitIds.length}',
                  label: l10n?.profileOutfits ?? 'Outfits',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  value: wardrobe.isNotEmpty
                      ? wardrobe
                            .reduce((a, b) => a.wearCount > b.wearCount ? a : b)
                            .name
                            .split(' ')
                            .first
                      : '—',
                  label: l10n?.profileFavItem ?? 'Fav item',
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            Text(
              l10n?.profileColorSeason ?? 'Color Season',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            ...ColorSeason.values.map((season) {
              final sel = profile.colorSeason == season;
              return GestureDetector(
                onTap: () => ref
                    .read(userProfileProvider.notifier)
                    .updateColorSeason(season),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.grey.withValues(alpha: 0.2),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              season.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              season.description,
                              style: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sel)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.seedColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            // Style preferences
            if (profile.stylePreferences.isNotEmpty) ...[
              Text(
                l10n?.profileStylePreferences ?? 'Style Preferences',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.stylePreferences
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.seedColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: AppColors.seedColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n?.profileSignOut ?? 'Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.withValues(alpha: 0.8),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (SupabaseService.isSignedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteAccount(context, ref, l10n),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: Text(l10n?.profileDeleteAccount ?? 'Delete Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
    context.go('/auth');
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n?.profileDeleteAccountFailed ?? 'Account deletion failed'}: $error',
        ),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  if (AppConfig.isSupabaseConfigured) {
    await AuthService().signOut();
  }
  ref.invalidate(userProfileProvider);
  ref.invalidate(aiConsentProvider);
  ref.invalidate(sessionProvider);
  ref.invalidate(wardrobeProvider);
  if (!context.mounted) return;
  context.go('/auth');
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
