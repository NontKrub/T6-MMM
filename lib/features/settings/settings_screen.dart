import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
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
import '../../core/services/auth_service.dart';
import '../../core/services/legal_links_service.dart';
import '../../core/services/local_account_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
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
    final locale = ref.watch(localeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final pendingMigration = ref.watch(guestMigrationPendingProvider);
    final aiConsent = ref.watch(aiConsentProvider);
    final session = ref
        .watch(sessionProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final signedIn =
        session?.isSupabaseAuthenticated ?? SupabaseService.isSignedIn;
    final brand = MmmBrandTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _accountSection(context, ref, l10n, brand, signedIn: signedIn),
          // Appearance
          _SectionHeader(title: l10n?.settingsAppearance ?? 'Appearance'),
          _SettingsTile(
            icon: _themeModeIcon(themeMode),
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            title: l10n?.settingsTheme ?? 'Theme',
            subtitle: _themeModeLabel(themeMode, l10n),
            onTap: () => _showThemeModeSheet(context, ref, l10n),
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
            onTap: () =>
                _openLegalDocument(context, l10n, LegalDocument.privacy),
          ),
          _SettingsTile(
            icon: Icons.article_outlined,
            iconColor: Colors.grey,
            title: l10n?.settingsTerms ?? 'Terms of Service',
            subtitle: l10n?.settingsTerms ?? 'Terms of Service',
            onTap: () => _openLegalDocument(context, l10n, LegalDocument.terms),
          ),
        ],
      ),
    );
  }

  Widget _accountSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    MmmBrandTheme brand, {
    required bool signedIn,
  }) {
    final user = AuthService().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n?.settingsAccount ?? 'Account'),
        if (!signedIn)
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsGuestAccount ?? 'Local guest account',
            subtitle:
                l10n?.settingsGuestAccountSubtitle ??
                'Your wardrobe is stored locally on this device',
          )
        else ...[
          _SettingsTile(
            icon: Icons.email_outlined,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsAccountEmail ?? 'Email',
            subtitle: user?.email ?? '—',
          ),
          _SettingsTile(
            icon: Icons.verified_user_outlined,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsAccountProvider ?? 'Signed in with',
            subtitle: _providerLabel(user),
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: brand.primaryGradient.colors.first,
            title: l10n?.settingsSignOut ?? 'Sign out',
            onTap: () => _signOut(context, ref, l10n),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            iconColor: brand.destructive,
            title: l10n?.settingsDeleteAccount ?? 'Delete account',
            onTap: () => _deleteAccount(context, ref, l10n),
          ),
        ],
      ],
    );
  }

  String _providerLabel(User? user) {
    if (user == null) return '—';
    final provider = user.appMetadata['provider'] as String?;
    if (provider == null || provider.isEmpty) return '—';
    return provider[0].toUpperCase() + provider.substring(1);
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) async {
    try {
      if (AppConfig.isSupabaseConfigured) await AuthService().signOut();
      ref.invalidate(userProfileProvider);
      ref.invalidate(aiConsentProvider);
      ref.invalidate(sessionProvider);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(outfitsProvider);
      if (context.mounted) context.go('/welcome');
    } catch (error) {
      debugPrint('Sign out failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.settingsSignOutFailed ?? 'Sign out failed'),
        ),
      );
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) async {
    final confirmed = await MmmDialog.show<bool>(
      context: context,
      title: Text(l10n?.settingsDeleteAccountTitle ?? 'Delete your account?'),
      content: Text(
        l10n?.settingsDeleteAccountMessage ??
            'This permanently removes your profile, wardrobe images, outfits, and activity from MMM.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.commonCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: MmmBrandTheme.of(context).destructive,
          ),
          child: Text(l10n?.settingsDeleteAccountConfirm ?? 'Delete account'),
        ),
      ],
    );
    if (confirmed != true) return;
    try {
      await AuthService().deleteAccount();
      await LocalAccountRepository().clearGuestAccount();
      ref.invalidate(userProfileProvider);
      ref.invalidate(aiConsentProvider);
      ref.invalidate(sessionProvider);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(outfitsProvider);
      if (context.mounted) context.go('/welcome');
    } catch (error) {
      debugPrint('Account deletion failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.settingsDeleteAccountFailed ?? 'Account deletion failed',
          ),
        ),
      );
    }
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

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    final mode = ref.read(themeModeProvider);
    _showChoiceSheet(
      context: context,
      title: l10n?.settingsTheme ?? 'Theme',
      currentValue: _themeModeValue(mode),
      options: [
        _SettingsChoice(
          value: 'system',
          label: l10n?.settingsThemeSystem ?? 'System',
          subtitle:
              l10n?.settingsThemeSystemSubtitle ??
              'Follows your device appearance',
          icon: Icons.brightness_auto_rounded,
        ),
        _SettingsChoice(
          value: 'light',
          label: l10n?.settingsThemeLight ?? 'Light',
          subtitle:
              l10n?.settingsThemeLightSubtitle ?? 'Always use light appearance',
          icon: Icons.light_mode_rounded,
        ),
        _SettingsChoice(
          value: 'dark',
          label: l10n?.settingsThemeDark ?? 'Dark',
          subtitle:
              l10n?.settingsThemeDarkSubtitle ?? 'Always use dark appearance',
          icon: Icons.dark_mode_rounded,
        ),
      ],
      failureMessage:
          l10n?.settingsThemeSaveFailed ??
          "Couldn't save the theme. Try again.",
      onSelected: (value) => ref
          .read(themeModeProvider.notifier)
          .setMode(_themeModeFromValue(value)),
    );
  }

  String _themeModeValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _themeModeFromValue(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations? l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n?.settingsThemeSystem ?? 'System';
      case ThemeMode.light:
        return l10n?.settingsThemeLight ?? 'Light';
      case ThemeMode.dark:
        return l10n?.settingsThemeDark ?? 'Dark';
    }
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
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
    required FutureOr<void> Function(String) onSelected,
    String? failureMessage,
  }) {
    MmmBottomSheet.show<void>(
      context: context,
      builder: (context) {
        var saving = false;
        String? savingValue;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            Widget choiceTile(
              _SettingsChoice option, {
              required VoidCallback? onTap,
              bool isSaving = false,
            }) {
              final selected = option.value == currentValue;
              final brand = MmmBrandTheme.of(context);
              final colorScheme = Theme.of(context).colorScheme;
              return ListTile(
                enabled: onTap != null,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.compactBorder,
                ),
                onTap: onTap,
                leading: option.icon == null
                    ? null
                    : Icon(
                        option.icon,
                        color: selected
                            ? brand.primaryGradient.colors.first
                            : colorScheme.onSurfaceVariant,
                      ),
                title: Text(option.label),
                subtitle: Text(option.subtitle),
                trailing: SizedBox(
                  width: 24,
                  height: 24,
                  child: isSaving
                      ? const Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? brand.primaryGradient.colors.first
                              : colorScheme.outline,
                        ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (errorText != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...options.map((option) {
                  final isSaving = savingValue == option.value;
                  return choiceTile(
                    option,
                    isSaving: saving && isSaving,
                    onTap: saving
                        ? null
                        : () async {
                            if (failureMessage != null) {
                              setState(() {
                                saving = true;
                                savingValue = option.value;
                                errorText = null;
                              });
                            }
                            try {
                              await onSelected(option.value);
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {
                              if (failureMessage == null) rethrow;
                              if (!context.mounted) return;
                              setState(() {
                                saving = false;
                                savingValue = null;
                                errorText = failureMessage;
                              });
                            }
                          },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openLegalDocument(
    BuildContext context,
    AppLocalizations? l10n,
    LegalDocument document,
  ) async {
    final title = document == LegalDocument.privacy
        ? (l10n?.settingsPrivacy ?? 'Privacy Policy')
        : (l10n?.settingsTerms ?? 'Terms of Service');
    if (LegalLinksService.uri(document) == null) {
      if (!context.mounted) return;
      await MmmDialog.show<void>(
        context: context,
        title: Text(title),
        content: Text(
          l10n?.legalLinkNotConfigured ??
              'A public HTTPS legal-document URL has not been configured yet.',
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

    if (await LegalLinksService.open(document)) return;
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
  final IconData? icon;

  const _SettingsChoice({
    required this.value,
    required this.label,
    required this.subtitle,
    this.icon,
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
