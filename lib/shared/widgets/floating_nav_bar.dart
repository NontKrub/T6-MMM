import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  static const _tabPaths = ['/home', '/wardrobe', '/missing', '/chat'];
  static const _tabIcons = [
    Icons.home_rounded,
    Icons.checkroom_rounded,
    Icons.add_shopping_cart_rounded,
    Icons.chat_bubble_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n?.navHome ?? 'Home',
      l10n?.navWardrobe ?? 'Wardrobe',
      l10n?.navMissing ?? 'Missing',
      l10n?.navChat ?? 'Chat',
    ];
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = _tabPaths.indexWhere((p) => location.startsWith(p));
    if (selectedIndex < 0) selectedIndex = 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? const Color(0x1AFFFFFF)
                    : const Color(0x40FFFFFF),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_tabPaths.length, (i) {
                final selected = i == selectedIndex;
                return _NavItem(
                  icon: _tabIcons[i],
                  label: labels[i],
                  selected: selected,
                  onTap: () => context.go(_tabPaths[i]),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.seedColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? AppColors.seedColor : Colors.grey,
        ),
      ),
    );
  }
}
