import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/recommendation_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';

final missingPiecesProvider =
    FutureProvider.autoDispose<List<MissingPieceRecommendation>>((ref) {
      return RecommendationRepository().generateMissingPieces();
    });

class MissingPiecesScreen extends ConsumerStatefulWidget {
  const MissingPiecesScreen({super.key});

  @override
  ConsumerState<MissingPiecesScreen> createState() =>
      _MissingPiecesScreenState();
}

class _MissingPiecesScreenState extends ConsumerState<MissingPiecesScreen> {
  String? _topId;
  String? _pantsId;
  AsyncValue<List<MissingPieceRecommendation>>? _selectedResult;

  Future<void> _analyze(ClothingItem top, ClothingItem pants) async {
    setState(() => _selectedResult = const AsyncLoading());
    try {
      final result = await RecommendationRepository().generateMissingPieces(
        top: top,
        pants: pants,
      );
      if (!mounted) return;
      setState(() => _selectedResult = AsyncData(result));
    } catch (error, stack) {
      if (!mounted) return;
      setState(() => _selectedResult = AsyncError(error, stack));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wardrobe = ref.watch(wardrobeProvider);
    final tops = wardrobe
        .where((item) => item.category == ClothingCategory.top)
        .toList();
    final pants = wardrobe
        .where((item) => item.category == ClothingCategory.pants)
        .toList();
    final selectedTop = tops.where((item) => item.id == _topId).firstOrNull;
    final selectedPants = pants
        .where((item) => item.id == _pantsId)
        .firstOrNull;
    final AsyncValue<List<MissingPieceRecommendation>> recommendations =
        _selectedResult ?? ref.watch(missingPiecesProvider);

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
                    l10n?.missingSubtitleUnlocked ??
                        'Curated to fill the gaps in your collection',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('missing-piece-top'),
                    initialValue: _topId,
                    decoration: const InputDecoration(
                      labelText: 'Selected top',
                    ),
                    items: tops
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _topId = value;
                      _selectedResult = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: const Key('missing-piece-pants'),
                    initialValue: _pantsId,
                    decoration: const InputDecoration(
                      labelText: 'Selected pants / bottom',
                    ),
                    items: pants
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _pantsId = value;
                      _selectedResult = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('missing-piece-analyze'),
                      onPressed: selectedTop == null || selectedPants == null
                          ? null
                          : () => _analyze(selectedTop, selectedPants),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Analyze Missing Piece'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: recommendations.when(
                data: (items) => items.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _RecommendationCard(rec: items[i])
                                .animate(delay: (i * 100).ms)
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                      ),
                error: (error, _) => _ErrorState(error: error),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.seedColor),
                ),
              ),
            ),
          ],
        ),
      ),
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
      message:
          l10n?.missingEmptyMessage ??
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
              Icon(icon, color: AppColors.seedColor, size: 36),
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
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
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
                  color: category.color.withValues(alpha: 0.15),
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
                        color: AppColors.seedColor,
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
                      color: AppColors.seedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.seedColor,
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
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
