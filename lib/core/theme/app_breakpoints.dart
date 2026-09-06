import 'package:flutter/widgets.dart';

enum MmmWidthClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;

  static MmmWidthClass widthClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expanded) return MmmWidthClass.expanded;
    if (width >= medium) return MmmWidthClass.medium;
    return MmmWidthClass.compact;
  }

  static double textScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1);
  }

  static bool largeText(BuildContext context) => textScale(context) >= 1.35;

  static bool veryLargeText(BuildContext context) => textScale(context) >= 2;
}
