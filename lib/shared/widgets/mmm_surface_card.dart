import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class MmmSurfaceCard extends StatelessWidget {
  const MmmSurfaceCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Material(
      color: brand.raisedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.cardBorder,
        side: BorderSide(color: brand.subtleBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardBorder,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
