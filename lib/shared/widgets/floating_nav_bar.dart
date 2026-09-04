import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  static double heightFor(BuildContext context) {
    if (AppBreakpoints.veryLargeText(context)) return 104;
    if (AppBreakpoints.largeText(context)) return 88;
    return 72;
  }

  static double contentInset(BuildContext context) {
    return heightFor(context) +
        AppSpacing.md +
        MediaQuery.paddingOf(context).bottom;
  }

  static const _tabPaths = ['/home', '/wardrobe', '/missing', '/chat'];
  static const _tabIcons = [
    Icons.home_rounded,
    Icons.checkroom_rounded,
    Icons.auto_awesome_rounded,
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
    final location = GoRouterState.of(context).uri.path;
    final brand = MmmBrandTheme.of(context);
    var selectedIndex = _tabPaths.indexWhere(location.startsWith);
    if (selectedIndex < 0) selectedIndex = 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.sheetBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: brand.raisedSurface.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.sheetBorder,
                side: BorderSide(color: brand.subtleBorder),
              ),
              child: SizedBox(
                height: heightFor(context),
                child: Row(
                  children: List.generate(
                    _tabPaths.length,
                    (index) => Expanded(
                      child: _NavItem(
                        navKey: ValueKey('nav-${_tabPaths[index]}'),
                        icon: _tabIcons[index],
                        label: labels[index],
                        selected: index == selectedIndex,
                        onTap: () => context.go(_tabPaths[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.navKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key navKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    final color = selected
        ? brand.primaryGradient.colors.first
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      key: navKey,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Material(
          color: selected ? brand.subtleAccentSurface : Colors.transparent,
          borderRadius: AppRadii.compactBorder,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.compactBorder,
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.duration(context, AppMotion.selection),
              curve: AppMotion.curve,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: AppBreakpoints.veryLargeText(context) ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
