import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/providers/ai_consent_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/guest_account_migration_service.dart';
import '../../core/services/ai_consent_repository.dart';
import '../../core/services/legal_links_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_bottom_sheet.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/widgets/mmm_surface_card.dart';

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
    final aiConsent = ref.watch(aiConsentProvider);
    final brand = MmmBrandTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Appearance
          _SectionHeader(title: l10n?.settingsAppearance ?? 'Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsDarkMode ?? 'Dark Mode',
            subtitle: isDark
                ? (l10n?.settingsDarkModeOn ?? 'On')
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeThumbColor: brand.primaryGradient.colors.first,
            ),
          ),

          // Language
          _SectionHeader(title: l10n?.settingsLanguage ?? 'Language'),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsLanguage ?? 'Language',
            subtitle: locale.languageCode == 'th'
                ? (l10n?.settingsLanguageValue ?? 'ภาษาไทย')
                : 'English',
            onTap: () =>
                context.push('/language', extra: {'fromSettings': true}),
          ),

          // Personalization
          _SectionHeader(
            title: l10n?.settingsPersonalization ?? 'Personalization',
          ),
          _SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsLuckyColor ?? 'Lucky Color Method',
            subtitle: _luckyColorLabel(appSettings.luckyColorMethod, l10n),
            onTap: () => _showLuckyColorMethodSheet(context, ref, l10n),
          ),
          _SettingsTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsWeather ?? 'Weather Location',
            subtitle: _weatherLocationLabel(
              appSettings.weatherLocationMode,
              l10n,
            ),
            onTap: () => _showWeatherLocationSheet(context, ref, l10n),
          ),

          if (SupabaseService.isSignedIn)
            pendingMigration.when(
              data: (pending) => pending
                  ? _SettingsTile(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: brand.primaryGradient.colors.first,
                      title:
                          l10n?.settingsImportLocal ?? 'Import local wardrobe',
                      subtitle:
                          l10n?.settingsImportLocalSubtitle ??
                          'Resume importing your guest wardrobe',
                      onTap: () => _importLocalWardrobe(context, ref, l10n),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Notifications
          _SectionHeader(title: l10n?.settingsNotifications ?? 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsDailyReminder ?? 'Daily outfit reminder',
            subtitle: appSettings.dailyOutfitReminder
                ? '${l10n?.settingsDarkModeOn ?? 'On'} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: appSettings.dailyOutfitReminderMinutes ~/ 60, minute: appSettings.dailyOutfitReminderMinutes % 60))}'
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: appSettings.dailyOutfitReminder,
              onChanged: (value) => _setDailyOutfitReminder(
                context,
                ref,
                appSettings,
                l10n,
                value,
              ),
              activeThumbColor: brand.primaryGradient.colors.first,
            ),
          ),
          _SettingsTile(
            icon: Icons.repeat_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsRepetitionAlerts ?? 'Repetition alerts',
            subtitle: appSettings.repetitionAlerts
                ? (l10n?.settingsDarkModeOn ?? 'On')
                : (l10n?.settingsDarkModeOff ?? 'Off'),
            trailing: Switch(
              value: appSettings.repetitionAlerts,
              onChanged: (value) =>
                  _setRepetitionAlerts(context, ref, l10n, value),
              activeThumbColor: brand.primaryGradient.colors.first,
            ),
          ),

          // AI
          _SectionHeader(title: l10n?.settingsAI ?? 'AI Features'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsLearnPreferences ?? 'Learn my preferences',
            subtitle:
                l10n?.settingsLearnPreferencesSubtitle ??
                'AI tracks your choices to improve suggestions',
            trailing: Switch(
              value: appSettings.learnPreferences,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setLearnPreferences(value),
              activeThumbColor: brand.primaryGradient.colors.first,
            ),
          ),
          _aiConsentTile(context, ref, l10n, aiConsent),

          // About
          _SectionHeader(title: l10n?.settingsAbout ?? 'About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey,
              title: l10n?.settingsVersion ?? 'Version',
              subtitle: snapshot.data == null
                  ? '—'
                  : formatApplicationVersion(
                      snapshot.data!.version,
                      snapshot.data!.buildNumber,
                    ),
            ),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: l10n?.settingsPrivacy ?? 'Privacy Policy',
            subtitle: l10n?.settingsPrivacy ?? 'Privacy Policy',
            onTap: () => _openPrivacyPolicy(context, l10n),
          ),
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
    MmmBottomSheet.show<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
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
                color: selected
                    ? MmmBrandTheme.of(context).primaryGradient.colors.first
                    : Theme.of(context).colorScheme.outline,
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy(
    BuildContext context,
    AppLocalizations? l10n,
  ) async {
    if (LegalLinksService.uri(LegalDocument.privacy) == null) {
      if (!context.mounted) return;
      await MmmDialog.show<void>(
        context: context,
        title: Text(l10n?.settingsPrivacy ?? 'Privacy Policy'),
        content: Text(
          l10n?.settingsPrivacyNotConfigured ??
              'A public HTTPS privacy-policy URL has not been configured yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.dialogClose ?? 'Close'),
          ),
        ],
      );
      return;
    }

    if (await LegalLinksService.open(LegalDocument.privacy)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.legalLinkOpenFailed ??
              'This link could not be opened. Check your connection and try again.',
        ),
      ),
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
    final message = result.completed
        ? result.warnings.isEmpty
              ? (l10n?.settingsImportLocalComplete ??
                    'Local wardrobe imported.')
              : 'Local wardrobe imported with ${result.warnings.length} warning${result.warnings.length == 1 ? '' : 's'}.'
        : '${l10n?.settingsImportLocalFailed ?? 'Import failed'}: ${result.error}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _aiConsentTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    AsyncValue<bool> consent,
  ) {
    final signedIn = SupabaseService.isSignedIn;
    final granted = consent.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    return _SettingsTile(
      icon: Icons.privacy_tip_outlined,
      iconColor: MmmBrandTheme.of(context).primaryGradient.colors.first,
      title: l10n?.settingsAIConsent ?? 'Third-party AI analysis',
      subtitle: !signedIn
          ? (l10n?.settingsAIConsentSignIn ??
                'Sign in to manage third-party AI consent')
          : granted
          ? (l10n?.settingsAIConsentGranted ?? 'Allowed — revoke anytime')
          : (l10n?.settingsAIConsentOff ??
                'Off — local and deterministic fallbacks stay available'),
      trailing: Switch(
        value: granted,
        onChanged: signedIn
            ? (value) => _setAiConsent(context, ref, l10n, value)
            : null,
        activeThumbColor: MmmBrandTheme.of(
          context,
        ).primaryGradient.colors.first,
      ),
    );
  }

  Future<void> _setAiConsent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    bool value,
  ) async {
    if (value) {
      final accepted = await MmmDialog.show<bool>(
        context: context,
        title: Text(l10n?.settingsAIConsentTitle ?? 'Allow third-party AI?'),
        content: Text(
          l10n?.settingsAIConsentMessage ??
              'MMM may send wardrobe images and metadata, fashion questions, and limited style-profile information such as your color season to the configured AI provider for analysis and recommendations. This is optional and can be revoked in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.itemDeleteCancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.settingsAIConsentAccept ?? 'Allow AI analysis'),
          ),
        ],
      );
      if (accepted != true) return;
    }

    try {
      final repository = AiConsentRepository();
      if (value) {
        await repository.grantCurrentConsent();
      } else {
        await repository.revokeCurrentConsent();
      }
      ref.invalidate(aiConsentProvider);
    } catch (error) {
      if (!context.mounted) return;
      debugPrint('AI consent update failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.settingsAIConsentFailed ??
                'AI permission could not be updated. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _setDailyOutfitReminder(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations? l10n,
    bool value,
  ) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    if (!value) {
      await notificationService.disableDailyReminder();
      await notifier.setDailyOutfitReminder(false);
      return;
    }

    final current = TimeOfDay(
      hour: settings.dailyOutfitReminderMinutes ~/ 60,
      minute: settings.dailyOutfitReminderMinutes % 60,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (selected == null) return;
    await notifier.setDailyOutfitReminderMinutes(
      selected.hour * 60 + selected.minute,
    );
    final scheduled = await notificationService.enableDailyReminder(selected);
    if (!scheduled) {
      await notifier.setDailyOutfitReminder(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.settingsNotificationsPermissionDenied ??
                'Notifications are disabled. MMM will continue without reminders.',
          ),
        ),
      );
      return;
    }
    await notifier.setDailyOutfitReminder(true);
  }

  Future<void> _setRepetitionAlerts(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    bool value,
  ) async {
    if (value) {
      final permission = await notificationService.requestPermission();
      if (!permission) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.settingsNotificationsPermissionDenied ??
                  'Notifications are disabled. MMM will continue without reminders.',
            ),
          ),
        );
        return;
      }
    } else {
      await notificationService.disableRepetitionAlerts();
    }
    await ref.read(appSettingsProvider.notifier).setRepetitionAlerts(value);
  }
}

String formatApplicationVersion(String version, String buildNumber) {
  final normalizedVersion = version.trim();
  final normalizedBuild = buildNumber.trim();
  if (normalizedVersion.isEmpty || normalizedBuild.isEmpty) return '—';
  return '$normalizedVersion (build $normalizedBuild)';
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
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MmmSurfaceCard(
        padding: EdgeInsets.zero,
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
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing:
              trailing ??
              (onTap == null
                  ? null
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
                    )),
        ),
      ),
    );
  }
}
