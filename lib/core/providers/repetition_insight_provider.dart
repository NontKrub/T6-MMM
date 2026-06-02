import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/recommendation_repository.dart';
import '../services/supabase_service.dart';

final repetitionInsightProvider = FutureProvider<RepetitionInsight?>((
  ref,
) async {
  if (!SupabaseService.isSignedIn) return null;
  return RecommendationRepository().repetitionInsights();
});
