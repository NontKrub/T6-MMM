import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/profile_analytics_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/profile_analytics.dart';
import '../../shared/widgets/mmm_empty_state.dart';
import '../../shared/widgets/mmm_error_state.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/wardrobe_image.dart';
import 'profile_labels.dart';

class ProfileInsightsScreen extends ConsumerStatefulWidget {
  const ProfileInsightsScreen({super.key});

  @override
  ConsumerState<ProfileInsightsScreen> createState() =>
      _ProfileInsightsScreenState();
}

class _ProfileInsightsScreenState extends ConsumerState<ProfileInsightsScreen> {
  ProfileAnalyticsRange _range = ProfileAnalyticsRange.thirtyDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final analytics = ref.watch(profileAnalyticsProvider(_range));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileInsightsTitle ?? 'Style insights'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: analytics.when(
            loading: () => const Center(child: MmmLoadingIndicator()),
            error: (_, __) => MmmErrorState(
              title:
                  l10n?.profileInsightsLoadFailed ?? 'Insights could not load.',
              message:
                  l10n?.profileInsightsLoadFailed ?? 'Insights could not load.',
              actionLabel: l10n?.commonRetry ?? 'Retry',
              onAction: () => ref.invalidate(profileAnalyticsProvider(_range)),
            ),
            data: (snapshot) => _content(context, snapshot),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ProfileAnalyticsSnapshot snapshot) {
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
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(profileAnalyticsProvider(_range)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _rangeSelector(context),
          const SizedBox(height: AppSpacing.md),
          _overviewCard(context, snapshot),
          const SizedBox(height: AppSpacing.md),
          _activityCard(context, snapshot),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, l10n?.profileMostWorn ?? 'Most worn'),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.mostWornItems.isEmpty)
            _inlineEmpty(
              l10n?.profileNoWearHistory ??
                  'Wear something to unlock your style patterns.',
            )
          else
            ...snapshot.mostWornItems.map((stat) => _itemRow(context, stat)),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, l10n?.profileCategoryMix ?? 'Category mix'),
          const SizedBox(height: AppSpacing.sm),
          _categoryCard(context, snapshot),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(
            context,
            l10n?.profileNotWornRecently ?? 'Not worn recently',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.unwornItems.isEmpty)
            _inlineEmpty(
              l10n?.profileNoUnwornItems ??
                  'Nothing has been unworn for 30+ days.',
            )
          else
            ...snapshot.unwornItems
                .take(5)
                .map((item) => _unwornRow(context, item)),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(
            context,
            l10n?.profileMostRepeatedLook ?? 'Most repeated look',
          ),
          const SizedBox(height: AppSpacing.sm),
          _repeatedLook(context, snapshot),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, l10n?.profileRecentLooks ?? 'Recent looks'),
          const SizedBox(height: AppSpacing.sm),
          _recentLooks(context, snapshot),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, l10n?.profileStyleDNA ?? 'Style DNA'),
          const SizedBox(height: AppSpacing.sm),
          _styleDna(context, snapshot),
        ],
      ),
    );
  }

  Widget _rangeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      ProfileAnalyticsRange.monthToDate: l10n?.profileRangeMonthToDate ?? 'MTD',
      ProfileAnalyticsRange.sevenDays: l10n?.profileRange7Days ?? '7D',
      ProfileAnalyticsRange.thirtyDays: l10n?.profileRange30Days ?? '30D',
      ProfileAnalyticsRange.ninetyDays: l10n?.profileRange90Days ?? '90D',
      ProfileAnalyticsRange.oneYear: l10n?.profileRange1Year ?? '1Y',
    };
    return SegmentedButton<ProfileAnalyticsRange>(
      segments: labels.entries
          .map(
            (entry) =>
                ButtonSegment(value: entry.key, label: Text(entry.value)),
          )
          .toList(growable: false),
      selected: {_range},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) setState(() => _range = selection.first);
      },
    );
  }

  Widget _overviewCard(
    BuildContext context,
    ProfileAnalyticsSnapshot snapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    final delta = snapshot.utilizationDeltaPoints;
    final deltaText = delta == 0
        ? ''
        : ' ${delta > 0 ? '+' : ''}${delta.round()}pp ${l10n?.profilePreviousPeriod ?? 'vs previous period'}';
    return MmmSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.profileWardrobeUtilized ?? 'Wardrobe utilized',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                l10n?.profileUtilizationAccessibility(
                  snapshot.utilization.round(),
                  snapshot.uniqueItemsWorn,
                  snapshot.wardrobeItemCount,
                ) ??
                '${snapshot.utilization.round()}% utilized; ${snapshot.uniqueItemsWorn} of ${snapshot.wardrobeItemCount} active pieces worn',
            child: Text(
              '${snapshot.utilization.round()}%',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          Text(
            '${l10n?.profileUtilizationSummary(snapshot.uniqueItemsWorn, snapshot.wardrobeItemCount) ?? '${snapshot.uniqueItemsWorn} of ${snapshot.wardrobeItemCount} active pieces worn'}$deltaText',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _activityCard(
    BuildContext context,
    ProfileAnalyticsSnapshot snapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    final peak = snapshot.activityBuckets.fold<ProfileActivityBucket?>(
      null,
      (best, bucket) =>
          best == null || bucket.looks > best.looks ? bucket : best,
    );
    final summary = peak == null || peak.looks == 0
        ? (l10n?.profileNoWearHistory ??
              'Wear something to unlock your style patterns.')
        : (l10n?.profileActivitySummary(
                MaterialLocalizations.of(context).formatShortDate(peak.start),
                peak.looks,
              ) ??
              'Most active on ${MaterialLocalizations.of(context).formatShortDate(peak.start)}: ${peak.looks} looks');
    return MmmSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.profileRecentLooks ?? 'Activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 132,
            child: Semantics(
              label: summary,
              child: CustomPaint(
                painter: _ActivityPainter(
                  buckets: snapshot.activityBuckets,
                  color: Theme.of(context).colorScheme.primary,
                  gridColor: MmmBrandTheme.of(context).subtleBorder,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context,
    ProfileAnalyticsSnapshot snapshot,
  ) {
    final total = snapshot.categoryDistribution.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    if (total == 0) {
      return _inlineEmpty(
        AppLocalizations.of(context)?.profileNoStyleDNA ?? 'No style data yet.',
      );
    }
    final entries = snapshot.categoryDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MmmSurfaceCard(
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _barRow(
                  context,
                  profileCategoryLabel(AppLocalizations.of(context), entry.key),
                  entry.value / total,
                  '${entry.value}',
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _styleDna(BuildContext context, ProfileAnalyticsSnapshot snapshot) {
    final l10n = AppLocalizations.of(context);
    final styles = snapshot.styleDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MmmSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (styles.isEmpty && snapshot.colorDistribution.isEmpty)
            Text(
              l10n?.profileNoStyleDNA ??
                  'Add and analyze a few wardrobe pieces to see your style DNA.',
            )
          else ...[
            if (styles.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: styles
                    .take(3)
                    .map(
                      (entry) => Chip(
                        label: Text(
                          profileStyleLabel(
                            AppLocalizations.of(context),
                            entry.key,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (snapshot.colorDistribution.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n?.profileColorPalette ?? 'Color palette',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: snapshot.colorDistribution
                    .take(4)
                    .map((color) => _colorDot(context, color))
                    .toList(growable: false),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, ProfileAnalyticsItemStat stat) =>
      MmmSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => context.push('/item/${stat.item.id}'),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 52,
              child: WardrobeImage(item: stat.item),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                stat.item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${stat.wearCount}×',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );

  Widget _unwornRow(BuildContext context, ClothingItem item) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox.square(dimension: 44, child: WardrobeImage(item: item)),
    title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      profileCategoryLabel(AppLocalizations.of(context), item.category),
    ),
    onTap: () => context.push('/item/${item.id}'),
  );

  Widget _repeatedLook(
    BuildContext context,
    ProfileAnalyticsSnapshot snapshot,
  ) {
    final look = snapshot.repeatedLook;
    if (look == null) {
      return _inlineEmpty(
        AppLocalizations.of(context)?.profileNoRepeatedLooks ??
            'No repeated looks in this period.',
      );
    }
    return MmmSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
                  context,
                )?.profileRepeatedCount(look.repeatCount) ??
                'Repeated ${look.repeatCount} times',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _lookImages(context, look),
        ],
      ),
    );
  }

  Widget _recentLooks(BuildContext context, ProfileAnalyticsSnapshot snapshot) {
    if (snapshot.recentLooks.isEmpty) {
      return _inlineEmpty(
        AppLocalizations.of(context)?.profileNoRecentLooks ??
            'No looks recorded in this period.',
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: snapshot.recentLooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => SizedBox(
          width: 210,
          child: MmmSurfaceCard(
            padding: const EdgeInsets.all(10),
            child: _lookImages(context, snapshot.recentLooks[index]),
          ),
        ),
      ),
    );
  }

  Widget _lookImages(BuildContext context, ProfileAnalyticsLook look) => Row(
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

  Widget _barRow(
    BuildContext context,
    String label,
    double value,
    String trailing,
  ) => Row(
    children: [
      SizedBox(
        width: 88,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: MmmBrandTheme.of(context).neutralSurface,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(trailing),
    ],
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
      child: Tooltip(
        message: stat.hex,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: MmmBrandTheme.of(context).subtleBorder),
          ),
          child: const SizedBox.square(dimension: 30),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);

  Widget _inlineEmpty(String message) => MmmSurfaceCard(child: Text(message));
}

class _ActivityPainter extends CustomPainter {
  const _ActivityPainter({
    required this.buckets,
    required this.color,
    required this.gridColor,
  });

  final List<ProfileActivityBucket> buckets;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = gridColor.withValues(alpha: .65);
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = buckets.fold<int>(
      1,
      (max, bucket) => bucket.looks > max ? bucket.looks : max,
    );
    final barWidth = size.width / (buckets.length * 1.65);
    final gap = barWidth * .65;
    final paint = Paint()..color = color;
    for (var index = 0; index < buckets.length; index++) {
      final height = size.height * buckets[index].looks / maxValue;
      final left = index * (barWidth + gap) + gap / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_ActivityPainter oldDelegate) =>
      oldDelegate.buckets != buckets || oldDelegate.color != color;
}
