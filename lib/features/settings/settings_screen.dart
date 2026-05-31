import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Appearance
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? const Color(0xFF818CF8) : AppColors.accentGold,
            title: 'Dark Mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppColors.seedColor,
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Personalization
          _SectionHeader(title: 'Personalization'),
          _SettingsTile(
            icon: Icons.palette_rounded,
            iconColor: AppColors.gradientEnd,
            title: 'Lucky Color Method',
            subtitle: 'Random daily',
            onTap: () {},
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.accentGold,
            title: 'Weather Location',
            subtitle: 'Auto-detect',
            onTap: () {},
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          // Notifications
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFF34D399),
            title: 'Daily outfit reminder',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.repeat_rounded,
            iconColor: AppColors.colorHats,
            title: 'Repetition alerts',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

          // AI
          _SectionHeader(title: 'AI Features'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.seedColor,
            title: 'Learn my preferences',
            subtitle: 'AI tracks your choices to improve suggestions',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.seedColor,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

          // About
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey,
            title: 'Version',
            subtitle: '1.0.0 (build 1)',
            onTap: () {},
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: 'Privacy Policy',
            onTap: () {},
          ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
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
