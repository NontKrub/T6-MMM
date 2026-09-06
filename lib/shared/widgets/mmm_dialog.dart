import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Thin dialog primitive that keeps Material semantics and shared geometry.
class MmmDialog extends StatelessWidget {
  const MmmDialog({super.key, this.title, this.content, this.actions});

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) =>
          MmmDialog(title: title, content: content, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadii.sheet),
      ),
      backgroundColor: theme.colorScheme.surface,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
    );
  }
}
