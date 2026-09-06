import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/outfit.dart';

class DailyOutfitVariation {
  DailyOutfitVariation({SharedPreferences? preferences})
    : _preferences = preferences;

  static const dateKey = 'mmm.daily_outfit.date';
  static const fingerprintKey = 'mmm.daily_outfit.fingerprint';

  final SharedPreferences? _preferences;
  late final Future<SharedPreferences> _preferencesFuture = _preferences == null
      ? SharedPreferences.getInstance()
      : Future.value(_preferences);

  Future<Outfit?> choose({
    required DateTime date,
    required Iterable<Outfit> candidates,
    Outfit? explicitSelection,
    int maxAttempts = 3,
  }) async {
    if (explicitSelection != null) return explicitSelection;
    final valid = candidates.where(_isValid).toList(growable: false);
    if (valid.isEmpty) return null;

    final preferences = await _preferencesFuture;
    final day = _dayKey(date);
    final previousDay = preferences.getString(dateKey);
    final previousFingerprint = preferences.getString(fingerprintKey);
    if (previousDay == day && previousFingerprint != null) {
      for (final candidate in valid) {
        if (fingerprint(candidate) == previousFingerprint) return candidate;
      }
    }

    var selected = valid.first;
    if (previousDay != null &&
        previousDay != day &&
        previousFingerprint != null) {
      final attempts = maxAttempts.clamp(1, valid.length);
      for (var index = 0; index < attempts; index++) {
        final candidate = valid[index];
        if (fingerprint(candidate) != previousFingerprint) {
          selected = candidate;
          break;
        }
      }
    }

    await preferences.setString(dateKey, day);
    await preferences.setString(fingerprintKey, fingerprint(selected));
    return selected;
  }

  static String fingerprint(Outfit outfit) {
    final ids = outfit.itemIds.toSet().toList()..sort();
    return ids.join('|');
  }

  static String _dayKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  bool _isValid(Outfit outfit) => outfit.itemIds.isNotEmpty;
}
