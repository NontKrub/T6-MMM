import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/repetition_insight_provider.dart';
import '../../../core/providers/wardrobe_provider.dart';
import '../../../core/theme/app_brand_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/mmm_surface_card.dart';

class RepetitionInsightCard extends ConsumerWidget {
  const RepetitionInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appSettingsProvider).repetitionAlerts) {
      return const SizedBox.shrink();
    }

    final backendInsight = ref.watch(repetitionInsightProvider);
    final signedInInsight = backendInsight.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final signedIn =
        backendInsight.isLoading ||
        signedInInsight != null ||
        backendInsight.hasError;

    var showAlert = false;
    String? tone;
    if (signedInInsight != null) {
      showAlert = signedInInsight.alert;
      tone = signedInInsight.dominantColor ?? signedInInsight.dominantStyle;
    } else if (!signedIn || backendInsight.hasError) {
      tone = ref.watch(wardrobeProvider.notifier).dominantRecentColor();
      showAlert = tone != null;
    }
    if (!showAlert) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final messageTone = tone ?? 'similar';
    final brand = MmmBrandTheme.of(context);
    return MmmSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: brand.subtleAccentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: brand.primaryGradient.colors.first,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.repetitionStyleReminder ?? 'Style reminder',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n?.repetitionMessage(messageTone) ??
                      'You’ve been wearing $messageTone tones frequently. Try mixing in something different today!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
