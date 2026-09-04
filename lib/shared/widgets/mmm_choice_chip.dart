import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';

class MmmChoiceChip extends StatelessWidget {
  const MmmChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onSelected == null ? null : () => onSelected!(!selected),
      child: ExcludeSemantics(
        child: Material(
          color: selected ? brand.subtleAccentSurface : brand.raisedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.compactBorder,
            side: BorderSide(
              color: selected
                  ? brand.primaryGradient.colors.first
                  : brand.subtleBorder,
            ),
          ),
          child: InkWell(
            onTap: onSelected == null ? null : () => onSelected!(!selected),
            borderRadius: AppRadii.compactBorder,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(label)),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: brand.primaryGradient.colors.first,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
