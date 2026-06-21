import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tint;
  final bool hasBorder;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 15,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tint,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassTint =
        tint ?? (isDark ? AppColors.backgroundSurface : AppColors.backgroundSurface);
    final borderColor = isDark
        ? AppColors.borderSubtle
        : AppColors.borderSubtle;

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassTint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder ? Border.all(color: borderColor, width: 1) : null,
          ),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: glass)
          : glass,
    );
  }
}
