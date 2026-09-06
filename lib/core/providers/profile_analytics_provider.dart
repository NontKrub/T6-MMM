import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/profile_analytics.dart';
import '../services/profile_analytics_repository.dart';
import 'session_provider.dart';
import 'wardrobe_provider.dart';

final profileAnalyticsRepositoryProvider = Provider<ProfileAnalyticsRepository>(
  (_) => ProfileAnalyticsRepository(),
);

final profileAnalyticsProvider =
    FutureProvider.family<ProfileAnalyticsSnapshot, ProfileAnalyticsRange>((
      ref,
      range,
    ) async {
      // Wardrobe state changes after mark-worn and item edits. Watching it keeps
      // analytics current without adding a second cache invalidation protocol.
      ref.watch(wardrobeProvider);
      ref.watch(sessionProvider);
      return ref.read(profileAnalyticsRepositoryProvider).fetch(range: range);
    });
