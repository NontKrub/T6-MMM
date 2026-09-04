import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/app_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads default settings when nothing is persisted', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = AppSettingsNotifier();
    await notifier.load();

    expect(notifier.state.luckyColorMethod, 'birth_profile');
    expect(notifier.state.weatherLocationMode, 'auto_detect');
    expect(notifier.state.dailyOutfitReminder, isFalse);
    expect(notifier.state.dailyOutfitReminderMinutes, 8 * 60);
    expect(notifier.state.repetitionAlerts, isTrue);
    expect(notifier.state.learnPreferences, isTrue);
  });

  test('persists settings toggles', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = AppSettingsNotifier();
    await notifier.setLuckyColorMethod('random_daily');
    await notifier.setWeatherLocationMode('off');
    await notifier.setDailyOutfitReminder(true);
    await notifier.setDailyOutfitReminderMinutes(9 * 60 + 15);
    await notifier.setRepetitionAlerts(false);
    await notifier.setLearnPreferences(false);

    final reloaded = AppSettingsNotifier();
    await reloaded.load();

    expect(reloaded.state.luckyColorMethod, 'random_daily');
    expect(reloaded.state.weatherLocationMode, 'off');
    expect(reloaded.state.dailyOutfitReminder, isTrue);
    expect(reloaded.state.dailyOutfitReminderMinutes, 9 * 60 + 15);
    expect(reloaded.state.repetitionAlerts, isFalse);
    expect(reloaded.state.learnPreferences, isFalse);
  });
}
