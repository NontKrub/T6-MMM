import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/wardrobe_image.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';
import '../../shared/widgets/mmm_secondary_button.dart';
import '../../shared/widgets/mmm_surface_card.dart';

class InARushModal extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const InARushModal({super.key, required this.ref});

  @override
  ConsumerState<InARushModal> createState() => _InARushModalState();
}

class _InARushModalState extends ConsumerState<InARushModal> {
  Outfit? _outfit;
  bool _loading = true;
  bool _wearing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutfit();
  }

  Future<void> _loadOutfit() async {
    setState(() => _loading = true);
    try {
      final outfit = await ref
          .read(outfitsProvider.notifier)
          .rushBackendOutfit(widget.ref);
      if (!mounted) return;
      setState(() {
        _outfit = outfit;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _outfit = null;
        _error = _friendlyRushError(error, l10n);
        _loading = false;
      });
    }
  }

  String _friendlyRushError(Object error, AppLocalizations? l) {
    final text = error.toString();
    if (text.contains('No compatible rush outfit')) {
      return l?.rushErrorUnavailable ??
          'No compatible rush outfit is available. Add shoes and a top + bottom or a dress.';
    }
    if (text.contains('Add at least one top')) {
      return l?.rushErrorNeedWardrobe ??
          'Rush outfits need a complete wardrobe first. Add at least one top, one bottom, and one pair of shoes.';
    }
    if (text.contains('Sign in') || text.contains('signed-in')) {
      return l?.rushErrorSignIn ??
          'Rush outfit uses your saved backend wardrobe. Sign in to use it.';
    }
    if (text.contains('NOT_FOUND') || text.contains('status: 404')) {
      return l?.rushErrorNotDeployed ??
          'Rush outfit is not deployed yet. Please try again after the backend is updated.';
    }
    return l?.rushErrorGeneric ??
        'Could not pick a rush outfit right now. Check your wardrobe and try again.';
  }

  void _reshuffle() {
    if (_loading) return;
    _loadOutfit();
  }

  Future<void> _wear(Outfit outfit) async {
    if (_wearing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _wearing = true);
    try {
      final count = await ref
          .read(outfitsProvider.notifier)
          .repeatCountFor(outfit);
      if (!mounted) return;
      if (count > 0) {
        final action = await MmmDialog.show<String>(
          context: context,
          title: Text(l10n?.outfitRepeatTitle ?? 'Repeat outfit'),
          content: Text(
            l10n?.outfitRepeatMessage(count) ??
                "You've worn this combination $count times.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'another'),
              child: Text(l10n?.outfitGenerateAnother ?? 'Generate another'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'wear'),
              child: Text(l10n?.outfitWearAnyway ?? 'Wear anyway'),
            ),
          ],
        );
        if (!mounted) return;
        if (action == 'another') {
          await _loadOutfit();
          return;
        }
        if (action != 'wear') return;
      }
      await ref
          .read(outfitsProvider.notifier)
          .selectOutfit(outfit, ref, previousRepeatCount: count);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _wearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wardrobe = ref.watch(wardrobeProvider);
    final outfit = _outfit;
    final hasError = _error != null;
    final items = outfit == null
        ? <ClothingItem>[]
        : outfit.itemIds
              .map((id) => wardrobe.where((i) => i.id == id).firstOrNull)
              .whereType<ClothingItem>()
              .toList();

    final brand = MmmBrandTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: MmmSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: brand.primaryGradient,
                        borderRadius: AppRadii.compactBorder,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.rushTitle ?? 'In a Rush',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            hasError
                                ? (l10n?.rushStatusNeedsSetup ??
                                      'Needs a little setup')
                                : (l10n?.rushStatusReady ??
                                      'Your outfit is ready'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Outfit items row
                if (_loading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: MmmLoadingIndicator(
                      label:
                          l10n?.outfitGeneratorGenerating ??
                          'Mixing your wardrobe…',
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: brand.destructive),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: items.asMap().entries.map((e) {
                            final item = e.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadii.controlBorder,
                                      border: Border.all(
                                        color: brand.subtleBorder,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: AppRadii.controlBorder,
                                      child: WardrobeImage(item: item),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      item.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (outfit != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          outfit.reason ??
                              (l10n?.rushDefaultReason ??
                                  'Fast practical pick from your wardrobe.'),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (outfit.score != null ||
                            outfit.selectionFactors.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (outfit.score != null)
                                _RushChip('${outfit.score!.round()} score'),
                              ...outfit.selectionFactors
                                  .take(3)
                                  .map(
                                    (factor) =>
                                        _RushChip(factor.replaceAll('_', ' ')),
                                  ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                const SizedBox(height: 28),
                // Buttons
                _RushActions(
                  loading: _loading,
                  wearing: _wearing,
                  hasOutfit: _outfit != null,
                  onReshuffle: _reshuffle,
                  onWear: _outfit == null ? null : () => _wear(_outfit!),
                  reshuffleLabel: l10n?.rushReshuffle ?? 'Reshuffle',
                  wearLabel: _outfit == null
                      ? (l10n?.rushGotIt ?? 'Got It')
                      : (l10n?.rushWearThis ?? 'Wear This'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RushActions extends StatelessWidget {
  const _RushActions({
    required this.loading,
    required this.wearing,
    required this.hasOutfit,
    required this.onReshuffle,
    required this.onWear,
    required this.reshuffleLabel,
    required this.wearLabel,
  });

  final bool loading;
  final bool wearing;
  final bool hasOutfit;
  final VoidCallback onReshuffle;
  final VoidCallback? onWear;
  final String reshuffleLabel;
  final String wearLabel;

  @override
  Widget build(BuildContext context) {
    final secondary = MmmSecondaryButton(
      onPressed: loading ? null : onReshuffle,
      icon: Icons.shuffle_rounded,
      label: reshuffleLabel,
    );
    final primary = MmmGradientButton(
      onPressed: !hasOutfit || wearing ? null : onWear,
      icon: Icons.check_rounded,
      label: wearLabel,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 360 || AppBreakpoints.largeText(context);
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              secondary,
              const SizedBox(height: AppSpacing.sm),
              primary,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: primary),
          ],
        );
      },
    );
  }
}

class _RushChip extends StatelessWidget {
  final String label;
  const _RushChip(this.label);

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: brand.subtleAccentSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brand.subtleBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: brand.primaryGradient.colors.first,
          fontSize: 11,
        ),
      ),
    );
  }
}
