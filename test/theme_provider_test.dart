import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh install follows system appearance', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);

    await notifier.load();

    expect(notifier.state, ThemeMode.system);
  });

  for (final entry in {
    'system': ThemeMode.system,
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
  }.entries) {
    test('loads persisted ${entry.key} appearance', () async {
      SharedPreferences.setMockInitialValues({'mmm_theme_mode': entry.key});
      final notifier = ThemeModeNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state, entry.value);
    });
  }

  test('migrates legacy dark preference', () async {
    SharedPreferences.setMockInitialValues({'isDarkMode': true});
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);

    await notifier.load();

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.state, ThemeMode.dark);
    expect(prefs.getString('mmm_theme_mode'), 'dark');
    expect(prefs.getBool('isDarkMode'), isNull);
  });

  test('migrates legacy light preference', () async {
    SharedPreferences.setMockInitialValues({'isDarkMode': false});
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);

    await notifier.load();

    expect(notifier.state, ThemeMode.light);
  });

  test(
    'new appearance preference takes priority over legacy preference',
    () async {
      SharedPreferences.setMockInitialValues({
        'mmm_theme_mode': 'light',
        'isDarkMode': true,
      });
      final notifier = ThemeModeNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state, ThemeMode.light);
    },
  );

  test('invalid appearance preference falls back to system', () async {
    SharedPreferences.setMockInitialValues({'mmm_theme_mode': 'sepia'});
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);

    await notifier.load();

    expect(notifier.state, ThemeMode.system);
  });

  test('setMode persists new appearance value', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);

    await notifier.setMode(ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.state, ThemeMode.dark);
    expect(prefs.getString('mmm_theme_mode'), 'dark');

    await notifier.setMode(ThemeMode.system);
    expect(
      (await SharedPreferences.getInstance()).getString('mmm_theme_mode'),
      'system',
    );
  });

  test('stale initial load cannot overwrite a newer selection', () async {
    SharedPreferences.setMockInitialValues({'mmm_theme_mode': 'light'});
    final preferences = await SharedPreferences.getInstance();
    final loadGate = Completer<SharedPreferences>();
    final notifier = ThemeModeNotifier(
      preferencesLoader: () => loadGate.future,
    );
    addTearDown(notifier.dispose);

    final selection = notifier.setMode(ThemeMode.dark);
    loadGate.complete(preferences);
    await selection;

    expect(notifier.state, ThemeMode.dark);
    expect(preferences.getString('mmm_theme_mode'), 'dark');
  });
}
