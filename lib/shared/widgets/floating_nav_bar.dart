import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  static const _tabs = [
    _NavTab(icon: Icons.home_rounded, label: 'Home', path: '/home'),
    _NavTab(
      icon: Icons.checkroom_rounded,
      label: 'Wardrobe',
      path: '/wardrobe',
    ),
    _NavTab(
      icon: Icons.add_shopping_cart_rounded,
      label: 'Missing',
      path: '/missing',
    ),
    _NavTab(icon: Icons.chat_bubble_rounded, label: 'Chat', path: '/chat'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
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
              children: List.generate(_tabs.length, (i) {
                final selected = i == selectedIndex;
                return _NavItem(
                  tab: _tabs[i],
                  selected: selected,
                  onTap: () => context.go(_tabs[i].path),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String path;
  const _NavTab({required this.icon, required this.label, required this.path});
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
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
              ? AppColors.seedColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          tab.icon,
          size: 24,
          color: selected ? AppColors.seedColor : Colors.grey,
        ),
      ),
    );
  }
}
