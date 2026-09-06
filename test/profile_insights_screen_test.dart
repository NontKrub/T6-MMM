import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/profile_analytics_provider.dart';
import 'package:mix_match_mood/core/services/profile_analytics_repository.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/profile/profile_insights_screen.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/profile_analytics.dart';

class _FakeAnalyticsRepository extends ProfileAnalyticsRepository {
  int fetchCalls = 0;
  final ranges = <ProfileAnalyticsRange>[];
  Completer<ProfileAnalyticsSnapshot>? nextFetch;

  @override
  Future<ProfileAnalyticsSnapshot> fetch({
    required ProfileAnalyticsRange range,
    DateTime? now,
  }) {
    fetchCalls++;
    ranges.add(range);
    final pending = nextFetch;
    nextFetch = null;
    return pending?.future ?? Future.value(_snapshot(range, utilization: 25));
  }
}

ProfileAnalyticsSnapshot _snapshot(
  ProfileAnalyticsRange range, {
  required double utilization,
}) => ProfileAnalyticsSnapshot(
  range: range,
  window: ProfileAnalyticsWindow(
    start: DateTime(2026, 9, 1),
    endExclusive: DateTime(2026, 10, 1),
    previousStart: DateTime(2026, 8, 1),
    previousEndExclusive: DateTime(2026, 9, 1),
  ),
  wardrobeItemCount: 1,
  looksWorn: 0,
  uniqueItemsWorn: 0,
  utilization: utilization,
  previousUtilization: 0,
  mostWornItems: const [],
  unwornItems: const [],
  recentLooks: const [],
  activityBuckets: const [],
  categoryDistribution: const {ClothingCategory.top: 1},
  styleDistribution: const {},
  colorDistribution: const [],
);

void main() {
  Future<_FakeAnalyticsRepository> pumpInsights(WidgetTester tester) async {
    final repository = _FakeAnalyticsRepository();
    final overrides = [
      for (final range in ProfileAnalyticsRange.values)
        profileAnalyticsProvider(
          range,
        ).overrideWith((_) => repository.fetch(range: range)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileInsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('refresh stays active until analytics fetch completes', (
    tester,
  ) async {
    final repository = await pumpInsights(tester);
    final pending = Completer<ProfileAnalyticsSnapshot>();
    repository.nextFetch = pending;
    final refreshState = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );

    var completed = false;
    final refresh = refreshState.show();
    refresh.whenComplete(() => completed = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.ranges.last, ProfileAnalyticsRange.thirtyDays);
    expect(completed, isFalse);

    pending.complete(
      _snapshot(ProfileAnalyticsRange.thirtyDays, utilization: 75),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await refresh;

    expect(completed, isTrue);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('short analytics content remains refreshable', (tester) async {
    await pumpInsights(tester);

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('refresh keeps the selected analytics range', (tester) async {
    final repository = await pumpInsights(tester);

    await tester.tap(find.text('90D'));
    await tester.pumpAndSettle();

    expect(repository.ranges.last, ProfileAnalyticsRange.ninetyDays);
  });
}
