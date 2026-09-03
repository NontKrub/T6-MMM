import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class AppSettings {
  final String luckyColorMethod;
  final String weatherLocationMode;
  final bool dailyOutfitReminder;
  final int dailyOutfitReminderMinutes;
  final bool repetitionAlerts;
  final bool learnPreferences;

  const AppSettings({
    this.luckyColorMethod = 'birth_profile',
    this.weatherLocationMode = 'auto_detect',
    this.dailyOutfitReminder = false,
    this.dailyOutfitReminderMinutes = 8 * 60,
    this.repetitionAlerts = true,
    this.learnPreferences = true,
  });

  AppSettings copyWith({
    String? luckyColorMethod,
    String? weatherLocationMode,
    bool? dailyOutfitReminder,
    int? dailyOutfitReminderMinutes,
    bool? repetitionAlerts,
    bool? learnPreferences,
  }) {
    return AppSettings(
      luckyColorMethod: luckyColorMethod ?? this.luckyColorMethod,
      weatherLocationMode: weatherLocationMode ?? this.weatherLocationMode,
      dailyOutfitReminder: dailyOutfitReminder ?? this.dailyOutfitReminder,
      dailyOutfitReminderMinutes:
          dailyOutfitReminderMinutes ?? this.dailyOutfitReminderMinutes,
      repetitionAlerts: repetitionAlerts ?? this.repetitionAlerts,
      learnPreferences: learnPreferences ?? this.learnPreferences,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    load();
  }

  static const _luckyColorMethodKey = 'mmm_lucky_color_method';
  static const _weatherLocationModeKey = 'mmm_weather_location_mode';
  static const _dailyOutfitReminderKey =
      NotificationService.dailyReminderEnabledKey;
  static const _dailyOutfitReminderMinutesKey =
      NotificationService.dailyReminderMinutesKey;
  static const _repetitionAlertsKey = 'mmm_repetition_alerts';
  static const _learnPreferencesKey = 'mmm_learn_preferences';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      luckyColorMethod:
          prefs.getString(_luckyColorMethodKey) ?? 'birth_profile',
      weatherLocationMode:
          prefs.getString(_weatherLocationModeKey) ?? 'auto_detect',
      dailyOutfitReminder: prefs.getBool(_dailyOutfitReminderKey) ?? false,
      dailyOutfitReminderMinutes: normalizeReminderMinutes(
        prefs.getInt(_dailyOutfitReminderMinutesKey) ?? 8 * 60,
      ),
      repetitionAlerts: prefs.getBool(_repetitionAlertsKey) ?? true,
      learnPreferences: prefs.getBool(_learnPreferencesKey) ?? true,
    );
  }

  Future<void> setLuckyColorMethod(String value) async {
    state = state.copyWith(luckyColorMethod: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_luckyColorMethodKey, value);
  }

  Future<void> setWeatherLocationMode(String value) async {
    state = state.copyWith(weatherLocationMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherLocationModeKey, value);
  }

  Future<void> setDailyOutfitReminder(bool value) async {
    state = state.copyWith(dailyOutfitReminder: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyOutfitReminderKey, value);
  }

  Future<void> setDailyOutfitReminderMinutes(int value) async {
    final minutes = normalizeReminderMinutes(value);
    state = state.copyWith(dailyOutfitReminderMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyOutfitReminderMinutesKey, minutes);
  }

  Future<void> setRepetitionAlerts(bool value) async {
    state = state.copyWith(repetitionAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_repetitionAlertsKey, value);
  }

  Future<void> setLearnPreferences(bool value) async {
    state = state.copyWith(learnPreferences: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_learnPreferencesKey, value);
  }
}
