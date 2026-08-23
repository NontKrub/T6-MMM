import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/repetition_insight_provider.dart';
import '../../../core/providers/wardrobe_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../l10n/app_localizations.dart';

class RepetitionInsightCard extends ConsumerWidget {
  const RepetitionInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    if (!settings.repetitionAlerts) return const SizedBox.shrink();

    final backendInsight = ref.watch(repetitionInsightProvider);
    final signedInInsight = backendInsight.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final signedInError = backendInsight.hasError;
    final isSignedIn =
        backendInsight.isLoading || signedInInsight != null || signedInError;

    String? dominantColor;
    String? dominantStyle;
    var showAlert = false;

    if (signedInInsight != null) {
      showAlert = signedInInsight.alert;
      dominantColor = signedInInsight.dominantColor;
      dominantStyle = signedInInsight.dominantStyle;
    } else if (!isSignedIn || signedInError) {
      dominantColor = ref
          .watch(wardrobeProvider.notifier)
          .dominantRecentColor();
      showAlert = dominantColor != null;
    }
    if (!showAlert) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final tone = dominantColor ?? dominantStyle ?? 'similar';
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.repetitionStyleReminder ?? 'Style reminder',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n?.repetitionMessage(tone) ??
                      'You\'ve been wearing $tone tones frequently. Try mixing in something different today!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.3, end: 0);
  }
}
