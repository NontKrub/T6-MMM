import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';

/// Scroll-safe layout for entry screens with top controls and a footer action.
class MmmEntryLayout extends StatelessWidget {
  const MmmEntryLayout({
    super.key,
    required this.content,
    this.top,
    this.footer,
    this.padding = AppSpacing.entryScreen,
  });

  final Widget content;
  final Widget? top;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final scale = AppBreakpoints.textScale(context);
          final verticalGap = constraints.maxHeight < 650
              ? AppSpacing.md
              : constraints.maxHeight < 800 || scale >= 1.35
              ? AppSpacing.xxl
              : AppSpacing.xxxl;
          final bottomInset = math.max(
            AppSpacing.lg,
            media.viewInsets.bottom + AppSpacing.md,
          );
          final horizontal = media.size.width >= AppBreakpoints.medium
              ? AppSpacing.xl
              : padding.resolve(Directionality.of(context)).horizontal / 2;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.sm,
              horizontal,
              bottomInset,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(
                  0,
                  constraints.maxHeight - AppSpacing.sm - bottomInset,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?top,
                      SizedBox(height: verticalGap),
                      content,
                      if (footer != null) ...[
                        SizedBox(height: verticalGap),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
