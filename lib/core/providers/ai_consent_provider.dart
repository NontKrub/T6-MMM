import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_consent_repository.dart';

final aiConsentProvider = FutureProvider<bool>((ref) {
  return AiConsentRepository().hasCurrentConsent();
});
