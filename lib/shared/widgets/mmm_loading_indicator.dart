import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';

class MmmLoadingIndicator extends StatelessWidget {
  const MmmLoadingIndicator({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label ?? 'Loading',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: MmmBrandTheme.of(context).primaryGradient.colors.first,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          Text(label!, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}
