import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/recommendation_repository.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/mmm_empty_state.dart';
import '../../shared/widgets/mmm_error_state.dart';
import '../../shared/widgets/mmm_bottom_sheet.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/wardrobe_image.dart';

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
      if (mounted) setState(() => _selectedResult = AsyncData(result));
    } catch (error, stack) {
      if (mounted) setState(() => _selectedResult = AsyncError(error, stack));
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
    final topLabel = l10n?.missingTop ?? 'Top';
    final bottomLabel = l10n?.missingBottom ?? 'Bottom';
    final AsyncValue<List<MissingPieceRecommendation>> recommendations =
        _selectedResult ?? ref.watch(missingPiecesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Text(
                      l10n?.missingTitle ?? 'What’s missing?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Text(
                      l10n?.missingSubtitleUnlocked ??
                          'Pick a base outfit and MMM will find the gap.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        _GarmentSelector(
                          key: const Key('missing-piece-top'),
                          label: topLabel,
                          placeholder:
                              l10n?.missingChoose(topLabel) ?? 'Choose Top',
                          value: selectedTop,
                          items: tops,
                          onChanged: (item) => setState(() {
                            _topId = item?.id;
                            _selectedResult = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GarmentSelector(
                          key: const Key('missing-piece-pants'),
                          label: bottomLabel,
                          placeholder:
                              l10n?.missingChoose(bottomLabel) ??
                              'Choose Bottom',
                          value: selectedPants,
                          items: pants,
                          onChanged: (item) => setState(() {
                            _pantsId = item?.id;
                            _selectedResult = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: MmmGradientButton(
                            key: const Key('missing-piece-analyze'),
                            label: l10n?.missingAnalyze ?? 'Analyze the gap',
                            icon: Icons.auto_awesome_rounded,
                            onPressed:
                                selectedTop == null || selectedPants == null
                                ? null
                                : () => _analyze(selectedTop, selectedPants),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  recommendations.when(
                    data: (items) => items.isEmpty
                        ? _EmptyState(l10n: l10n)
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, index) =>
                                _RecommendationCard(rec: items[index]),
                          ),
                    loading: () => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: MmmLoadingIndicator(
                          label: l10n?.missingLoading ?? 'Finding the gap…',
                        ),
                      ),
                    ),
                    error: (_, _) => _ErrorState(l10n: l10n),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GarmentSelector extends StatelessWidget {
  const _GarmentSelector({
    super.key,
    required this.label,
    this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? placeholder;
  final ClothingItem? value;
  final List<ClothingItem> items;
  final ValueChanged<ClothingItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = value?.name ?? placeholder ?? 'Choose $label';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: MmmSurfaceCard(
        onTap: items.isEmpty ? null : () => _showPicker(context),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            if (value != null)
              ClipRRect(
                borderRadius: AppRadii.compactBorder,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: WardrobeImage(item: value!),
                ),
              )
            else
              const SizedBox(width: 40, height: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                selectedLabel,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final selected = await MmmBottomSheet.show<ClothingItem>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, index) {
                final item = items[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.controlBorder,
                    ),
                    leading: ClipRRect(
                      borderRadius: AppRadii.compactBorder,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: WardrobeImage(item: item),
                      ),
                    ),
                    title: Text(item.name),
                    trailing: value?.id == item.id
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations? l10n;
  @override
  Widget build(BuildContext context) => MmmEmptyState(
    title: l10n?.missingEmptyTitle ?? 'No recommendations yet',
    message:
        l10n?.missingEmptyMessage ??
        'Choose a top and bottom to find the next piece.',
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n});
  final AppLocalizations? l10n;
  @override
  Widget build(BuildContext context) => MmmErrorState(
    title: l10n?.missingErrorTitle ?? 'Could not generate recommendations',
    message: l10n?.missingTryAgain ?? 'Try again in a moment.',
  );
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.rec});
  final MissingPieceRecommendation rec;
  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    final rec = widget.rec;
    final category = clothingCategoryFromString(rec.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MmmSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brand.subtleAccentSurface,
                    borderRadius: AppRadii.controlBorder,
                  ),
                  child: Icon(
                    category.icon,
                    color: brand.primaryGradient.colors.first,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        rec.priority,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: brand.primaryGradient.colors.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(
                _expanded
                    ? (AppLocalizations.of(context)?.missingWhyCollapse ??
                          'Hide reason')
                    : (AppLocalizations.of(context)?.missingWhyExpand ??
                          'Why?'),
              ),
            ),
            if (_expanded) ...[
              Text(rec.reason, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                rec.suggestion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
