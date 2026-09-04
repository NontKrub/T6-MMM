import 'package:flutter/material.dart';

/// The approved MMM ribbon mark from the supplied brand sheet.
class MmmBrandMark extends StatelessWidget {
  const MmmBrandMark({super.key, this.size = 72, this.label = 'MMM logo mark'});

  /// The visible width of the mark. Height follows the approved aspect ratio.
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: Image.asset(
          isDark
              ? 'assets/branding/mmm_mark_dark.png'
              : 'assets/branding/mmm_mark.png',
          width: size,
          height: isDark ? size * 160 / 410 : size * 250 / 530,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// The approved MMM mark and wordmark lockup without the localized tagline.
class MmmBrandWordmark extends StatelessWidget {
  const MmmBrandWordmark({
    super.key,
    this.width = 220,
    this.label = 'Mix Match Mood logo',
  });

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: Image.asset(
          isDark
              ? 'assets/branding/mmm_wordmark_dark.png'
              : 'assets/branding/mmm_wordmark.png',
          width: width,
          height: isDark ? width * 200 / 470 : width * 320 / 560,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
