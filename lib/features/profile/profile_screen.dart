import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/profile_analytics_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/profile_analytics.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/mmm_bottom_sheet.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_empty_state.dart';
import '../../shared/widgets/mmm_error_state.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/wardrobe_image.dart';
import 'profile_avatar.dart';
import 'profile_labels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _styleOptions = [
    'Casual',
    'Minimalist',
    'Streetwear',
    'Formal',
    'Vintage',
    'Y2K',
    'Cottagecore',
    'Preppy',
    'Bohemian',
    'Athleisure',
    'Dark Academia',
    'Clean Girl',
  ];
  static const _occasionOptions = [
    'Work',
    'Weekend',
    'Dates',
    'Sports',
    'Events',
    'Travel',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final analytics = ref.watch(
      profileAnalyticsProvider(ProfileAnalyticsRange.monthToDate),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? 'Profile'),
        actions: [
          IconButton(
            tooltip: l10n?.commonSettings ?? 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _ProfileHeader(
                profile: profile,
                semanticLabel: l10n?.profilePhotoFor(profile.name),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n?.profileEdit ?? 'Edit profile'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              analytics.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: MmmLoadingIndicator()),
                ),
                error: (_, __) => MmmErrorState(
                  title:
                      l10n?.profileInsightsLoadFailed ??
                      'Insights could not load.',
                  message:
                      l10n?.profileInsightsLoadFailed ??
                      'Insights could not load.',
                  actionLabel: l10n?.commonRetry ?? 'Retry',
                  onAction: () => ref.invalidate(
                    profileAnalyticsProvider(ProfileAnalyticsRange.monthToDate),
                  ),
                ),
                data: (snapshot) => _analyticsContent(context, ref, snapshot),
              ),
              const SizedBox(height: AppSpacing.xl),
              _preferences(context, ref, profile),
              const SizedBox(height: AppSpacing.xl),
              MmmSurfaceCard(
                padding: EdgeInsets.zero,
                onTap: () => context.push('/settings'),
                child: ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(
                    l10n?.profileAccountSettings ?? 'Account & settings',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analyticsContent(
    BuildContext context,
    WidgetRef ref,
    ProfileAnalyticsSnapshot snapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    if (!snapshot.hasWardrobe) {
      return MmmEmptyState(
        title:
            l10n?.profileEmptyWardrobe ??
            'Your wardrobe is ready for its first piece.',
        message:
            l10n?.profileEmptyWardrobeMessage ??
            'Add a few pieces and MMM will show how you wear them.',
        actionLabel: l10n?.commonAddItem ?? 'Add item',
        onAction: () => context.push('/wardrobe'),
        icon: Icons.checkroom_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n?.profileThisMonth ?? 'This month'),
        const SizedBox(height: AppSpacing.sm),
        MmmSurfaceCard(
          child: Column(
            children: [
              Row(
                children: [
                  _Stat(
                    value: '${snapshot.wardrobeItemCount}',
                    label: l10n?.profileItems ?? 'Items',
                  ),
                  _Stat(
                    value: '${snapshot.looksWorn}',
                    label: l10n?.profileLooksWorn ?? 'Looks worn',
                  ),
                  _Stat(
                    value: '${snapshot.uniqueItemsWorn}',
                    label: l10n?.profilePiecesWorn ?? 'Pieces worn',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label:
                    l10n?.profileUtilizationAccessibility(
                      snapshot.utilization.round(),
                      snapshot.uniqueItemsWorn,
                      snapshot.wardrobeItemCount,
                    ) ??
                    '${snapshot.utilization.round()}% utilized; ${snapshot.uniqueItemsWorn} of ${snapshot.wardrobeItemCount} active pieces worn',
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (snapshot.utilization / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${snapshot.utilization.round()}%'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n?.profileUtilizationSummary(
                        snapshot.uniqueItemsWorn,
                        snapshot.wardrobeItemCount,
                      ) ??
                      '${snapshot.uniqueItemsWorn} of ${snapshot.wardrobeItemCount} active pieces worn',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${snapshot.utilizationDeltaPoints > 0 ? '+' : ''}${snapshot.utilizationDeltaPoints.round()}pp ${l10n?.profilePreviousPeriod ?? 'vs previous period'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: snapshot.utilizationDeltaPoints == 0
                        ? Theme.of(context).colorScheme.outline
                        : snapshot.utilizationDeltaPoints > 0
                        ? MmmBrandTheme.of(context).success
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push('/profile/insights'),
            icon: const Icon(Icons.insights_outlined),
            label: Text(l10n?.profileViewInsights ?? 'View insights'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(context, l10n?.profileStyleDNA ?? 'Style DNA'),
        const SizedBox(height: AppSpacing.sm),
        _styleDna(context, snapshot),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(
          context,
          l10n?.profileWardrobeInsights ?? 'Wardrobe insights',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (snapshot.mostWornItems.isEmpty)
          MmmSurfaceCard(
            child: Text(
              l10n?.profileNoWearHistory ??
                  'Wear something to unlock your style patterns.',
            ),
          )
        else
          MmmSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: snapshot.mostWornItems
                  .take(3)
                  .map(
                    (stat) => ListTile(
                      onTap: () => context.push('/item/${stat.item.id}'),
                      leading: SizedBox.square(
                        dimension: 44,
                        child: WardrobeImage(item: stat.item),
                      ),
                      title: Text(
                        stat.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text('${stat.wearCount}×'),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (snapshot.repeatedLook != null) ...[
          const SizedBox(height: AppSpacing.md),
          MmmSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.repeat_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n?.profileRepeatedCount(
                              snapshot.repeatedLook!.repeatCount,
                            ) ??
                            'Repeated ${snapshot.repeatedLook!.repeatCount} times',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _lookPreview(context, snapshot.repeatedLook!),
              ],
            ),
          ),
        ],
        if (snapshot.unwornItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          MmmSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: snapshot.unwornItems
                  .take(3)
                  .map(
                    (item) => ListTile(
                      onTap: () => context.push('/item/${item.id}'),
                      leading: SizedBox.square(
                        dimension: 44,
                        child: WardrobeImage(item: item),
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        l10n?.profileNotWornRecently ?? 'Not worn recently',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        if (snapshot.recentLooks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          MmmSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.profileRecentLooks ?? 'Recent looks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.recentLooks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _lookPreview(context, snapshot.recentLooks[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _styleDna(BuildContext context, ProfileAnalyticsSnapshot snapshot) {
    final l10n = AppLocalizations.of(context);
    final styles = snapshot.styleDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (styles.isEmpty && snapshot.colorDistribution.isEmpty) {
      return MmmSurfaceCard(
        child: Text(
          l10n?.profileNoStyleDNA ??
              'Add and analyze a few wardrobe pieces to see your style DNA.',
        ),
      );
    }
    return MmmSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (styles.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: styles
                  .take(3)
                  .map(
                    (entry) =>
                        Chip(label: Text(profileStyleLabel(l10n, entry.key))),
                  )
                  .toList(growable: false),
            ),
          if (snapshot.colorDistribution.isNotEmpty) ...[
            if (styles.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: snapshot.colorDistribution
                  .take(4)
                  .map((stat) => _colorDot(context, stat))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lookPreview(BuildContext context, ProfileAnalyticsLook look) => Row(
    mainAxisSize: MainAxisSize.min,
    children: look.items
        .take(4)
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              label: item.name,
              child: InkWell(
                onTap: () => context.push('/item/${item.id}'),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox.square(
                    dimension: 52,
                    child: WardrobeImage(item: item),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );

  Widget _colorDot(BuildContext context, ProfileColorStat stat) {
    final value = int.tryParse(stat.hex.replaceFirst('#', ''), radix: 16);
    final color = value == null
        ? Theme.of(context).colorScheme.outline
        : Color(0xFF000000 | value);
    return Semantics(
      label:
          AppLocalizations.of(
            context,
          )?.profileColorSwatch(stat.hex, stat.itemCount) ??
          '${stat.hex}, ${stat.itemCount} items',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const SizedBox.square(dimension: 30),
      ),
    );
  }

  Widget _preferences(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n?.profilePreferences ?? 'Preferences'),
        const SizedBox(height: AppSpacing.sm),
        MmmSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ColorSeasonPreference(),
              ...[
                const SizedBox(height: AppSpacing.md),
                _editablePreferenceHeader(
                  context,
                  title: l10n?.profileStylePreferences ?? 'Style Preferences',
                  editLabel: l10n?.profileEdit ?? 'Edit profile',
                  onEdit: () => _editStyles(context, ref, profile),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (profile.stylePreferences.isEmpty)
                  Text(
                    l10n?.profileNoStylePreferences ??
                        'No style preferences yet.',
                  )
                else
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: profile.stylePreferences
                        .map(
                          (style) => Chip(
                            label: Text(profilePreferenceLabel(l10n, style)),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
              ...[
                const SizedBox(height: AppSpacing.md),
                _editablePreferenceHeader(
                  context,
                  title: l10n?.profileOccasions ?? 'Occasions',
                  editLabel: l10n?.profileEdit ?? 'Edit profile',
                  onEdit: () => _editOccasions(context, ref, profile),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (profile.occasions.isEmpty)
                  Text(l10n?.profileNoOccasions ?? 'No occasions selected yet.')
                else
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: profile.occasions
                        .map(
                          (occasion) => Chip(
                            label: Text(profileOccasionLabel(l10n, occasion)),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _editablePreferenceHeader(
    BuildContext context, {
    required String title,
    required String editLabel,
    required VoidCallback onEdit,
  }) {
    final titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleSmall,
    );
    final editButton = TextButton(onPressed: onEdit, child: Text(editLabel));
    if (AppBreakpoints.largeText(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          Align(alignment: Alignment.centerRight, child: editButton),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: titleWidget),
        editButton,
      ],
    );
  }

  void _editStyles(BuildContext context, WidgetRef ref, UserProfile profile) {
    final selected = {...profile.stylePreferences};
    var saving = false;
    String? errorMessage;
    MmmBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)?.profileStylePreferences ??
                    'Style Preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _styleOptions
                  .map(
                    (style) => MmmChoiceChip(
                      label: profilePreferenceLabel(
                        AppLocalizations.of(context),
                        style,
                      ),
                      selected: selected.contains(style),
                      onSelected: saving
                          ? null
                          : (_) => setModalState(() {
                              if (!selected.add(style)) selected.remove(style);
                            }),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setModalState(() {
                          saving = true;
                          errorMessage = null;
                        });
                        try {
                          await ref
                              .read(userProfileProvider.notifier)
                              .saveStylePreferences(
                                _styleOptions.where(selected.contains).toList(),
                              );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        } catch (error) {
                          debugPrint('Style preference save failed: $error');
                          if (!sheetContext.mounted) return;
                          setModalState(() {
                            saving = false;
                            errorMessage =
                                AppLocalizations.of(
                                  context,
                                )?.profilePreferencesSaveFailed ??
                                "Couldn't save your preferences. Check your connection and try again.";
                          });
                        }
                      },
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context)?.profileSave ?? 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editOccasions(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final selected = {...profile.occasions};
    var saving = false;
    String? errorMessage;
    MmmBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)?.profileOccasions ?? 'Occasions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _occasionOptions
                  .map(
                    (occasion) => MmmChoiceChip(
                      label: profileOccasionLabel(
                        AppLocalizations.of(context),
                        occasion,
                      ),
                      selected: selected.contains(occasion),
                      onSelected: saving
                          ? null
                          : (_) => setModalState(() {
                              if (!selected.add(occasion)) {
                                selected.remove(occasion);
                              }
                            }),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setModalState(() {
                          saving = true;
                          errorMessage = null;
                        });
                        try {
                          await ref
                              .read(userProfileProvider.notifier)
                              .saveOccasions(
                                _occasionOptions
                                    .where(selected.contains)
                                    .toList(),
                              );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        } catch (error) {
                          debugPrint('Occasion preference save failed: $error');
                          if (!sheetContext.mounted) return;
                          setModalState(() {
                            saving = false;
                            errorMessage =
                                AppLocalizations.of(
                                  context,
                                )?.profilePreferencesSaveFailed ??
                                "Couldn't save your preferences. Check your connection and try again.";
                          });
                        }
                      },
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context)?.profileSave ?? 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _ColorSeasonPreference extends ConsumerStatefulWidget {
  const _ColorSeasonPreference();

  @override
  ConsumerState<_ColorSeasonPreference> createState() =>
      _ColorSeasonPreferenceState();
}

class _ColorSeasonPreferenceState
    extends ConsumerState<_ColorSeasonPreference> {
  bool _saving = false;
  String? _errorMessage;

  Future<void> _save(ColorSeason season) async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(userProfileProvider.notifier).saveColorSeason(season);
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (error) {
      debugPrint('Color season save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage =
            AppLocalizations.of(context)?.profilePreferencesSaveFailed ??
            "Couldn't save your preferences. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n?.profileColorSeason ?? 'Color Season',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (_saving)
              Semantics(
                liveRegion: true,
                label: 'Saving',
                child: const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: ColorSeason.values
              .map(
                (season) => MmmChoiceChip(
                  label: profileSeasonLabel(l10n, season),
                  selected: profile.colorSeason == season,
                  onSelected: _saving ? null : (_) => _save(season),
                ),
              )
              .toList(growable: false),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, this.semanticLabel});

  final UserProfile profile;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ProfileAvatar(profile: profile, size: 82, semanticLabel: semanticLabel),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              profile.stylePreferences.isEmpty
                  ? AppLocalizations.of(context)?.profilePaletteSubtitle(
                          profileSeasonLabel(
                            AppLocalizations.of(context),
                            profile.colorSeason,
                          ),
                        ) ??
                        '${profileSeasonLabel(AppLocalizations.of(context), profile.colorSeason)} palette'
                  : AppLocalizations.of(context)?.profileIdentitySubtitle(
                          profilePreferenceLabel(
                            AppLocalizations.of(context),
                            profile.stylePreferences.first,
                          ),
                          profileSeasonLabel(
                            AppLocalizations.of(context),
                            profile.colorSeason,
                          ),
                        ) ??
                        '${profilePreferenceLabel(AppLocalizations.of(context), profile.stylePreferences.first)} · ${profileSeasonLabel(AppLocalizations.of(context), profile.colorSeason)} palette',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
