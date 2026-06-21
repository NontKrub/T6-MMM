import 'package:flutter/material.dart';
import 'app_colors.dart';

class LuxuryCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;

  const LuxuryCard({
    super.key,
    required this.child,
    this.borderRadius = 0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: card)
          : card,
    );
  }
}
