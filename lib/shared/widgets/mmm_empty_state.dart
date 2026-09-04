import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_spacing.dart';
import 'mmm_gradient_button.dart';

class MmmEmptyState extends StatelessWidget {
  const MmmEmptyState({
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final minHeight =
            constraints.maxHeight.isFinite &&
                constraints.maxHeight > AppSpacing.xl * 2
            ? constraints.maxHeight - AppSpacing.xl * 2
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360, minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: MmmBrandTheme.of(
                      context,
                    ).primaryGradient.colors.first,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: MmmGradientButton(
                        label: actionLabel!,
                        onPressed: onAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
