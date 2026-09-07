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

  test(
    'failed theme persistence restores the previous mode and can retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var unavailable = true;
      final notifier = ThemeModeNotifier(
        preferencesLoader: () async {
          if (unavailable) throw StateError('storage unavailable');
          return preferences;
        },
      );
      addTearDown(notifier.dispose);

      await expectLater(
        notifier.setMode(ThemeMode.dark),
        throwsA(isA<StateError>()),
      );
      expect(notifier.state, ThemeMode.system);

      unavailable = false;
      await notifier.setMode(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
      expect(preferences.getString('mmm_theme_mode'), 'light');
    },
  );

  test('rapid theme selections persist in request order', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var loaderCalls = 0;
    final writeGates = <Completer<SharedPreferences>>[];
    final notifier = ThemeModeNotifier(
      preferencesLoader: () {
        loaderCalls++;
        if (loaderCalls == 1) return Future.value(preferences);
        final gate = Completer<SharedPreferences>();
        writeGates.add(gate);
        return gate.future;
      },
    );
    addTearDown(notifier.dispose);

    final first = notifier.setMode(ThemeMode.dark);
    final second = notifier.setMode(ThemeMode.light);
    final third = notifier.setMode(ThemeMode.system);
    await Future<void>.delayed(Duration.zero);
    expect(writeGates, hasLength(1));

    writeGates[0].complete(preferences);
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(writeGates, hasLength(2));

    writeGates[1].complete(preferences);
    await second;
    await Future<void>.delayed(Duration.zero);
    expect(writeGates, hasLength(3));

    writeGates[2].complete(preferences);
    await third;

    expect(notifier.state, ThemeMode.system);
    expect(preferences.getString('mmm_theme_mode'), 'system');
  });
}
