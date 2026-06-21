import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_provider.dart';
import '../../core/services/recommendation_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';

final missingPiecesProvider =
    FutureProvider.autoDispose<List<MissingPieceRecommendation>>((ref) {
      return RecommendationRepository().generateMissingPieces();
    });

class MissingPiecesScreen extends ConsumerWidget {
  const MissingPiecesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locked = ref
        .watch(sessionProvider)
        .maybeWhen(
          data: (session) => session.requiresLoginForAi,
          orElse: () => true,
        );
    final recommendations = locked
        ? const AsyncValue<List<MissingPieceRecommendation>>.data([])
        : ref.watch(missingPiecesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.missingTitle ?? 'Your wardrobe needs...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    locked
                        ? (l10n?.missingSubtitleLocked ??
                              'Sign in to generate wardrobe gap recommendations')
                        : (l10n?.missingSubtitleUnlocked ??
                              'Curated to fill the gaps in your collection'),
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            Expanded(
              child: locked
                  ? const _LockedState()
                  : recommendations.when(
                      data: (items) => items.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) =>
                                  _RecommendationCard(rec: items[i])
                                      .animate(delay: (i * 100).ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: 0.1, end: 0),
                            ),
                      error: (error, _) => _ErrorState(error: error),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredMessage(
      icon: Icons.lock_outline_rounded,
      title: l10n?.missingLockedTitle ?? 'Recommendations need a login',
      message: l10n?.missingLockedMessage ??
          'Missing pieces use backend AI and your Supabase wardrobe. Guest accounts keep wardrobe data local only.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredMessage(
      icon: Icons.inventory_2_outlined,
      title: l10n?.missingEmptyTitle ?? 'No recommendations yet',
      message: l10n?.missingEmptyMessage ??
          'The backend did not return any missing pieces.',
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredMessage(
      icon: Icons.error_outline_rounded,
      title: l10n?.missingErrorTitle ?? 'Could not generate recommendations',
      message: error.toString(),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.accentGold, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final MissingPieceRecommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.rec;
    final category = clothingCategoryFromString(rec.category);

    return GlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.priority,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    _expanded
                        ? (AppLocalizations.of(context)?.missingWhyCollapse ??
                              'Hide reason')
                        : (AppLocalizations.of(context)?.missingWhyExpand ??
                              'Why?'),
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Text(rec.reason, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              rec.suggestion,
              style: TextStyle(color: Colors.grey.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
