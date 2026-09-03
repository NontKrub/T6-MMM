import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/guest_account_migration_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final pendingMigration = ref.watch(guestMigrationPendingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Appearance
          _SectionHeader(title: l10n?.settingsAppearance ?? 'Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? const Color(0xFF818CF8) : AppColors.accentGold,
            title: l10n?.settingsDarkMode ?? 'Dark Mode',
            subtitle: isDark
                ? (l10n?.settingsDarkModeOn ?? 'On')
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeThumbColor: AppColors.seedColor,
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Language
          _SectionHeader(title: l10n?.settingsLanguage ?? 'Language'),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: AppColors.seedColor,
            title: l10n?.settingsLanguage ?? 'Language',
            subtitle: locale.languageCode == 'th'
                ? (l10n?.settingsLanguageValue ?? 'ภาษาไทย')
                : 'English',
            onTap: () =>
                context.push('/language', extra: {'fromSettings': true}),
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

          // Personalization
          _SectionHeader(
            title: l10n?.settingsPersonalization ?? 'Personalization',
          ),
          _SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: AppColors.gradientEnd,
            title: l10n?.settingsLuckyColor ?? 'Lucky Color Method',
            subtitle: _luckyColorLabel(appSettings.luckyColorMethod, l10n),
            onTap: () => _showLuckyColorMethodSheet(context, ref, l10n),
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.accentGold,
            title: l10n?.settingsWeather ?? 'Weather Location',
            subtitle: _weatherLocationLabel(
              appSettings.weatherLocationMode,
              l10n,
            ),
            onTap: () => _showWeatherLocationSheet(context, ref, l10n),
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

          if (SupabaseService.isSignedIn)
            pendingMigration.when(
              data: (pending) => pending
                  ? _SettingsTile(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: AppColors.seedColor,
                      title:
                          l10n?.settingsImportLocal ?? 'Import local wardrobe',
                      subtitle:
                          l10n?.settingsImportLocalSubtitle ??
                          'Resume importing your guest wardrobe',
                      onTap: () => _importLocalWardrobe(context, ref, l10n),
                    ).animate(delay: 175.ms).fadeIn(duration: 300.ms)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Notifications
          _SectionHeader(title: l10n?.settingsNotifications ?? 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFF34D399),
            title: l10n?.settingsDailyReminder ?? 'Daily outfit reminder',
            subtitle: appSettings.dailyOutfitReminder
                ? (l10n?.settingsDarkModeOn ?? 'On')
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: appSettings.dailyOutfitReminder,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setDailyOutfitReminder(value),
              activeThumbColor: AppColors.seedColor,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.repeat_rounded,
            iconColor: AppColors.colorHats,
            title: l10n?.settingsRepetitionAlerts ?? 'Repetition alerts',
            subtitle: appSettings.repetitionAlerts
                ? (l10n?.settingsDarkModeOn ?? 'On')
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: appSettings.repetitionAlerts,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setRepetitionAlerts(value),
              activeThumbColor: AppColors.seedColor,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

          // AI
          _SectionHeader(title: l10n?.settingsAI ?? 'AI Features'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.seedColor,
            title: l10n?.settingsLearnPreferences ?? 'Learn my preferences',
            subtitle:
                l10n?.settingsLearnPreferencesSubtitle ??
                'AI tracks your choices to improve suggestions',
            trailing: Switch(
              value: appSettings.learnPreferences,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setLearnPreferences(value),
              activeThumbColor: AppColors.seedColor,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

          // About
          _SectionHeader(title: l10n?.settingsAbout ?? 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey,
            title: l10n?.settingsVersion ?? 'Version',
            subtitle: l10n?.settingsVersionValue ?? '1.0.0 (build 1)',
          ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: l10n?.settingsPrivacy ?? 'Privacy Policy',
            subtitle: l10n?.settingsPrivacy ?? 'Privacy Policy',
            onTap: () => _showPrivacyDialog(context, l10n),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  String _luckyColorLabel(String value, AppLocalizations? l10n) {
    switch (value) {
      case 'random_daily':
        return l10n?.settingsLuckyColorRandomDaily ?? 'Random daily';
      case 'birth_profile':
      default:
        return l10n?.settingsLuckyColorBirthProfile ?? 'Birth profile';
    }
  }

  String _weatherLocationLabel(String value, AppLocalizations? l10n) {
    switch (value) {
      case 'off':
        return l10n?.settingsWeatherOff ?? 'Off';
      case 'auto_detect':
      default:
        return l10n?.settingsWeatherAutoDetect ?? 'Auto-detect';
    }
  }

  void _showLuckyColorMethodSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    _showChoiceSheet(
      context: context,
      title: l10n?.settingsLuckyColor ?? 'Lucky Color Method',
      currentValue: ref.read(appSettingsProvider).luckyColorMethod,
      options: [
        _SettingsChoice(
          value: 'birth_profile',
          label: l10n?.settingsLuckyColorBirthProfile ?? 'Birth profile',
          subtitle:
              l10n?.settingsLuckyColorBirthProfileSubtitle ??
              'Uses your saved birth date and weekday.',
        ),
        _SettingsChoice(
          value: 'random_daily',
          label: l10n?.settingsLuckyColorRandomDaily ?? 'Random daily',
          subtitle:
              l10n?.settingsLuckyColorRandomDailySubtitle ??
              'Uses a stable daily color set without profile data.',
        ),
      ],
      onSelected: (value) =>
          ref.read(appSettingsProvider.notifier).setLuckyColorMethod(value),
    );
  }

  void _showWeatherLocationSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    _showChoiceSheet(
      context: context,
      title: l10n?.settingsWeather ?? 'Weather Location',
      currentValue: ref.read(appSettingsProvider).weatherLocationMode,
      options: [
        _SettingsChoice(
          value: 'auto_detect',
          label: l10n?.settingsWeatherAutoDetect ?? 'Auto-detect',
          subtitle:
              l10n?.settingsWeatherAutoDetectSubtitle ??
              'Uses device location when weather matching is enabled.',
        ),
        _SettingsChoice(
          value: 'off',
          label: l10n?.settingsWeatherOff ?? 'Off',
          subtitle:
              l10n?.settingsWeatherOffSubtitle ??
              'Outfit generation will skip weather matching.',
        ),
      ],
      onSelected: (value) =>
          ref.read(appSettingsProvider.notifier).setWeatherLocationMode(value),
    );
  }

  void _showChoiceSheet({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<_SettingsChoice> options,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...options.map((option) {
                  final selected = option.value == currentValue;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      onSelected(option.value);
                      Navigator.pop(context);
                    },
                    title: Text(option.label),
                    subtitle: Text(option.subtitle),
                    trailing: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.seedColor : Colors.grey,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final innerL10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(innerL10n?.settingsPrivacy ?? 'Privacy Policy'),
          content: Text(
            innerL10n?.settingsPrivacyContent ??
                'Guest profile and wardrobe data stay on this device. Signed-in accounts store wardrobe, outfit, and preference data in Supabase so backend AI features can generate recommendations. API keys and secrets are not stored in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(innerL10n?.dialogClose ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importLocalWardrobe(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) async {
    final result = await GuestAccountMigrationService().migrate();
    ref.invalidate(guestMigrationPendingProvider);
    if (result.completed) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(outfitsProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.completed
              ? (l10n?.settingsImportLocalComplete ??
                    'Local wardrobe imported.')
              : '${l10n?.settingsImportLocalFailed ?? 'Import failed'}: ${result.error}',
        ),
      ),
    );
  }
}

class _SettingsChoice {
  final String value;
  final String label;
  final String subtitle;

  const _SettingsChoice({
    required this.value,
    required this.label,
    required this.subtitle,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing:
              trailing ??
              (onTap != null
                  ? Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.withValues(alpha: 0.4),
                    )
                  : null),
        ),
      ),
    );
  }
}
