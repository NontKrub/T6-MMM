import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_motion.dart';

class MmmProgressIndicator extends StatelessWidget {
  const MmmProgressIndicator({required this.value, super.key, this.label});

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    return Semantics(
      label: label ?? 'Progress',
      value: '${(safeValue * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                ColoredBox(color: MmmBrandTheme.of(context).subtleBorder),
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.selection),
                  curve: AppMotion.curve,
                  width: constraints.maxWidth * safeValue,
                  decoration: BoxDecoration(
                    gradient: MmmBrandTheme.of(context).primaryGradient,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
