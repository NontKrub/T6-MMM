import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
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
              activeColor: AppColors.seedColor,
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
            onTap: () => context.push('/language', extra: {'fromSettings': true}),
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

          // Personalization
          _SectionHeader(title: l10n?.settingsPersonalization ?? 'Personalization'),
          _SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: AppColors.gradientEnd,
            title: l10n?.settingsLuckyColor ?? 'Lucky Color Method',
            subtitle: l10n?.settingsLuckyColorValue ?? 'Random daily',
            onTap: () {},
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.accentGold,
            title: l10n?.settingsWeather ?? 'Weather Location',
            subtitle: l10n?.settingsWeatherValue ?? 'Auto-detect',
            onTap: () {},
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

          // Notifications
          _SectionHeader(title: l10n?.settingsNotifications ?? 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFF34D399),
            title: l10n?.settingsDailyReminder ?? 'Daily outfit reminder',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.repeat_rounded,
            iconColor: AppColors.colorHats,
            title: l10n?.settingsRepetitionAlerts ?? 'Repetition alerts',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

          // AI
          _SectionHeader(title: l10n?.settingsAI ?? 'AI Features'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.seedColor,
            title: l10n?.settingsLearnPreferences ?? 'Learn my preferences',
            subtitle: l10n?.settingsLearnPreferencesSubtitle ??
                'AI tracks your choices to improve suggestions',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

          // About
          _SectionHeader(title: l10n?.settingsAbout ?? 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey,
            title: l10n?.settingsVersion ?? 'Version',
            subtitle: l10n?.settingsVersionValue ?? '1.0.0 (build 1)',
            onTap: () {},
          ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: l10n?.settingsPrivacy ?? 'Privacy Policy',
            onTap: () {},
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
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
          color: Colors.grey.withOpacity(0.5),
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
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
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
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 12,
                ),
              )
            : null,
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.withOpacity(0.4),
                  )
                : null),
      ),
    );
  }
}
