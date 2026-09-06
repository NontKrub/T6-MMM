import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/profile_analytics_provider.dart';
import 'package:mix_match_mood/core/providers/user_profile_provider.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/profile/profile_screen.dart';
import 'package:mix_match_mood/shared/models/profile_analytics.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;
  Object? nextError;

  @override
  Future<UserProfile?> fetchProfile() async => profile;

  @override
  Future<void> upsertProfile(UserProfile value) async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    profile = value;
  }
}

ProfileAnalyticsSnapshot _emptyAnalytics() => ProfileAnalyticsSnapshot(
  range: ProfileAnalyticsRange.monthToDate,
  window: ProfileAnalyticsWindow(
    start: DateTime(2026, 9, 1),
    endExclusive: DateTime(2026, 10, 1),
    previousStart: DateTime(2026, 8, 1),
    previousEndExclusive: DateTime(2026, 9, 1),
  ),
  wardrobeItemCount: 0,
  looksWorn: 0,
  uniqueItemsWorn: 0,
  utilization: 0,
  previousUtilization: 0,
  mostWornItems: const [],
  unwornItems: const [],
  recentLooks: const [],
  activityBuckets: const [],
  categoryDistribution: const {},
  styleDistribution: const {},
  colorDistribution: const [],
);

void main() {
  testWidgets('failed style save keeps sheet open and retryable', (
    tester,
  ) async {
    const initial = UserProfile(
      id: 'local_guest',
      name: 'Nont',
      stylePreferences: ['Casual'],
    );
    final repository = _FakeProfileRepository(initial)
      ..nextError = StateError('offline');
    final notifier = UserProfileNotifier(null, repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((_) => notifier),
          profileAnalyticsProvider(
            ProfileAnalyticsRange.monthToDate,
          ).overrideWith((_) async => _emptyAnalytics()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final styleEdit = find.widgetWithText(TextButton, 'Edit profile').first;
    await tester.ensureVisible(styleEdit);
    await tester.pumpAndSettle();
    await tester.tap(styleEdit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Streetwear'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Couldn't save your preferences. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Streetwear'), findsOneWidget);
    final failedSave = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(failedSave.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Couldn't save your preferences. Check your connection and try again.",
      ),
      findsNothing,
    );
    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    expect(repository.profile.stylePreferences, ['Casual', 'Streetwear']);
  });
}
