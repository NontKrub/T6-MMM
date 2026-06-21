import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/outfit_card.dart';

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
  String? _error;

  static const _styles = ['casual', 'work', 'formal', 'sport', 'date'];

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wardrobe = ref.watch(wardrobeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final weatherDisabled = appSettings.weatherLocationMode == 'off';
    final locked = ref
        .watch(sessionProvider)
        .maybeWhen(
          data: (session) => session.requiresLoginForAi,
          orElse: () => true,
        );

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1628) : const Color(0xFFF8F7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.outfitGeneratorTitle ?? 'Generate Outfit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(height: 20),
                    _LockedState(l10n: l10n),
                  ] else ...[
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
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStyle = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.accentGold
                                  : AppColors.accentGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _localizedStyle(l10n, s),
                              style: TextStyle(
                                color: sel ? Colors.white : AppColors.accentGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                      label: l10n?.outfitGeneratorUsePersonalColor ??
                          'Use my personal color season',
                      value: _usePersonalColor,
                      onChanged: (v) => setState(() => _usePersonalColor = v),
                    ),
                    _FilterToggle(
                      label: l10n?.outfitGeneratorLuckyColor ??
                          "Today's lucky color",
                      subtitle: appSettings.luckyColorMethod == 'random_daily'
                          ? (l10n?.settingsLuckyColorRandomDaily ??
                              'Random daily')
                          : (l10n?.settingsLuckyColorBirthProfile ??
                              'Birth profile'),
                      value: _useLuckyColor,
                      onChanged: (v) => setState(() => _useLuckyColor = v),
                    ),
                    _FilterToggle(
                      label: l10n?.outfitGeneratorMatchWeather ??
                          'Match weather',
                      subtitle: weatherDisabled
                          ? (l10n?.outfitGeneratorWeatherOff ??
                              'Turn on Weather Location in Settings')
                          : (l10n?.outfitGeneratorWeatherAuto ??
                              'Auto-detect location'),
                      value: !weatherDisabled && _matchWeather,
                      onChanged: weatherDisabled
                          ? null
                          : (v) => setState(() => _matchWeather = v),
                    ),
                    const SizedBox(height: 24),
                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _generate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _loading
                              ? (l10n?.outfitGeneratorGenerating ??
                                  'Generating...')
                              : (l10n?.outfitGeneratorGenerate ?? 'Generate'),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
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
                            onWear: () {
                              ref
                                  .read(outfitsProvider.notifier)
                                  .selectOutfit(outfit, ref);
                              Navigator.pop(context);
                            },
                          )
                          .animate(delay: (e.key * 100).ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0);
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
      child: GlassContainer(
        borderRadius: 14,
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
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  final AppLocalizations? l10n;
  const _LockedState({this.l10n});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.accentGold,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.outfitGeneratorLockedTitle ??
                'AI outfit generation needs a login',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.outfitGeneratorLockedMessage ??
                'Guest wardrobes stay local. Sign in with Supabase to generate real outfits, weather matches, and lucky color looks.',
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
