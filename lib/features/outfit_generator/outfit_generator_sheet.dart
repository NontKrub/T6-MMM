import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/clothing_analysis_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/outfit_card.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_surface_card.dart';

class OutfitGeneratorSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const OutfitGeneratorSheet({super.key, required this.ref});

  @override
  ConsumerState<OutfitGeneratorSheet> createState() =>
      _OutfitGeneratorSheetState();
}

class _OutfitGeneratorSheetState extends ConsumerState<OutfitGeneratorSheet> {
  String _selectedStyle = 'casual';
  bool _usePersonalColor = false;
  bool _useLuckyColor = false;
  bool _matchWeather = false;
  List<Outfit> _generatedOutfits = [];
  bool _loading = false;
  bool _wearing = false;
  String? _error;
  final _targetHexController = TextEditingController();

  static const _styles = ['casual', 'work', 'formal', 'sport', 'date'];

  @override
  void dispose() {
    _targetHexController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    final targetHex = _targetHexController.text.trim().isEmpty
        ? null
        : normalizeHexColor(_targetHexController.text);
    if (_targetHexController.text.trim().isNotEmpty && targetHex == null) {
      setState(
        () => _error =
            l10n?.outfitTargetColorInvalid ??
            'Enter a valid HEX color such as #3366FF.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final outfits = await ref
          .read(outfitsProvider.notifier)
          .generateBackendOutfits(
            _selectedStyle,
            ref,
            usePersonalColor: _usePersonalColor,
            useLuckyColor: _useLuckyColor,
            matchWeather: _matchWeather,
            targetHex: targetHex,
          );
      if (!mounted) return;
      setState(() {
        _generatedOutfits = outfits;
        _loading = false;
        _error = outfits.isEmpty
            ? (l10n?.outfitGeneratorNoOutfits ?? 'No outfits were generated.')
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _generatedOutfits = const [];
        _loading = false;
        _error = _friendlyGenerationError(error, l10n);
      });
    }
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
          await _generate();
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

  String _friendlyGenerationError(Object error, AppLocalizations? l) {
    final text = error.toString();
    if (text.contains('NOT_FOUND') || text.contains('status: 404')) {
      return l?.outfitGeneratorErrorNotDeployed ??
          'Outfit generation is not deployed yet. Please try again after the backend is updated.';
    }
    if (text.contains('Add at least one top')) {
      return l?.outfitGeneratorErrorNeedWardrobe ??
          'Add at least one top, one bottom, and one pair of shoes first.';
    }
    if (text.contains('Location permission')) {
      return l?.outfitGeneratorErrorLocationPermission ??
          'Location permission is needed to match the weather.';
    }
    if (text.contains('Turn on location services')) {
      return l?.outfitGeneratorErrorLocationOff ??
          'Turn on location services to match the weather.';
    }
    return l?.outfitGeneratorErrorGeneric ??
        'Could not generate outfits. Please try again.';
  }

  String _localizedStyle(AppLocalizations? l, String style) {
    switch (style) {
      case 'casual':
        return l?.outfitStyleCasual ?? 'Casual';
      case 'work':
        return l?.outfitStyleWork ?? 'Work';
      case 'formal':
        return l?.outfitStyleFormal ?? 'Formal';
      case 'sport':
        return l?.outfitStyleSport ?? 'Sport';
      case 'date':
        return l?.outfitStyleDate ?? 'Date';
      default:
        return style[0].toUpperCase() + style.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = MmmBrandTheme.of(context);
    final wardrobe = ref.watch(wardrobeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final media = MediaQuery.of(context);
    final weatherDisabled = appSettings.weatherLocationMode == 'off';
    final backendAvailable = SupabaseService.isSignedIn;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: BoxDecoration(
        color: brand.raisedSurface,
        borderRadius: AppRadii.sheetBorder,
        border: Border(top: BorderSide(color: brand.subtleBorder)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: brand.subtleBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                math.max(
                  AppSpacing.xxl,
                  media.viewInsets.bottom +
                      media.padding.bottom +
                      AppSpacing.lg,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.outfitGeneratorTitle ?? 'Generate Outfit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Style chips
                  Text(
                    l10n?.outfitGeneratorStyleLabel ?? 'Style',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _styles.map((s) {
                      final sel = _selectedStyle == s;
                      return MmmChoiceChip(
                        label: _localizedStyle(l10n, s),
                        selected: sel,
                        onSelected: (_) => setState(() => _selectedStyle = s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Filters
                  Text(
                    l10n?.outfitGeneratorFiltersLabel ?? 'Filters',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  _FilterToggle(
                    label:
                        l10n?.outfitGeneratorUsePersonalColor ??
                        'Use my personal color season',
                    subtitle: backendAvailable
                        ? null
                        : (l10n?.outfitSignInColor ??
                              'Sign in to use profile color season'),
                    value: _usePersonalColor,
                    onChanged: backendAvailable
                        ? (v) => setState(() => _usePersonalColor = v)
                        : null,
                  ),
                  _FilterToggle(
                    label:
                        l10n?.outfitGeneratorLuckyColor ??
                        "Today's lucky color",
                    subtitle: appSettings.luckyColorMethod == 'random_daily'
                        ? (l10n?.settingsLuckyColorRandomDaily ??
                              'Random daily')
                        : (l10n?.settingsLuckyColorBirthProfile ??
                              'Birth profile'),
                    value: _useLuckyColor,
                    onChanged: backendAvailable
                        ? (v) => setState(() => _useLuckyColor = v)
                        : null,
                  ),
                  _FilterToggle(
                    label: l10n?.outfitGeneratorMatchWeather ?? 'Match weather',
                    subtitle: weatherDisabled
                        ? (l10n?.outfitGeneratorWeatherOff ??
                              'Turn on Weather Location in Settings')
                        : (l10n?.outfitGeneratorWeatherAuto ??
                              'Auto-detect location'),
                    value: !weatherDisabled && _matchWeather,
                    onChanged: weatherDisabled || !backendAvailable
                        ? null
                        : (v) => setState(() => _matchWeather = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('outfit-target-hex'),
                    controller: _targetHexController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.outfitTargetColorLabel ??
                          'Optional outfit color (HEX)',
                      hintText: '#3366FF',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: MmmGradientButton(
                      label: _loading
                          ? (l10n?.outfitGeneratorGenerating ??
                                'Mixing your wardrobe…')
                          : (l10n?.outfitGeneratorGenerate ??
                                'Generate outfit'),
                      icon: Icons.auto_awesome_rounded,
                      isLoading: _loading,
                      onPressed: _loading ? null : _generate,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    MmmSurfaceCard(
                      child: Text(
                        _error!,
                        style: TextStyle(color: brand.destructive),
                      ),
                    ),
                  ],
                  // Generated results
                  if (_generatedOutfits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n?.outfitGeneratorResults ?? 'Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._generatedOutfits.asMap().entries.map((e) {
                      final outfit = e.value;
                      final items = outfit.itemIds
                          .map(
                            (id) =>
                                wardrobe.where((i) => i.id == id).firstOrNull,
                          )
                          .whereType<ClothingItem>()
                          .toList();
                      return OutfitCard(
                        outfit: outfit,
                        items: items,
                        onWear: () => _wear(outfit),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _FilterToggle({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MmmSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: MmmBrandTheme.of(
                context,
              ).primaryGradient.colors.first,
            ),
          ],
        ),
      ),
    );
  }
}
