import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({Future<SharedPreferences> Function()? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
      super(ThemeMode.system) {
    load();
  }

  static const _themeModeKey = 'mmm_theme_mode';
  static const _legacyDarkModeKey = 'isDarkMode';

  final Future<SharedPreferences> Function() _preferencesLoader;
  Future<void> _writeQueue = Future.value();
  ThemeMode _persistedMode = ThemeMode.system;
  int _revision = 0;

  Future<void> load() async {
    final requestRevision = _revision;
    try {
      final prefs = await _preferencesLoader();
      final storedMode = _modeFromStored(prefs.getString(_themeModeKey));
      final legacyDarkMode = prefs.getBool(_legacyDarkModeKey);
      final mode =
          storedMode ??
          (legacyDarkMode == null
              ? ThemeMode.system
              : legacyDarkMode
              ? ThemeMode.dark
              : ThemeMode.light);

      if (!mounted || requestRevision != _revision) return;
      state = mode;
      _persistedMode = mode;

      if (storedMode == null && legacyDarkMode != null) {
        try {
          final persisted = await prefs.setString(
            _themeModeKey,
            _storedValue(mode),
          );
          if (persisted) await prefs.remove(_legacyDarkModeKey);
        } catch (_) {
          // Keep the new state even when migration cleanup is unavailable.
        }
      }
    } catch (_) {
      // System mode is the safe default when local preferences are unavailable.
    }
  }

  Future<void> setMode(ThemeMode mode) {
    final selectionRevision = ++_revision;
    state = mode;
    final result = _writeQueue.then((_) async {
      final prefs = await _preferencesLoader();
      final persisted = await prefs.setString(
        _themeModeKey,
        _storedValue(mode),
      );
      if (!persisted) {
        throw StateError('Theme mode could not be persisted.');
      }
      if (!mounted) return;
      _persistedMode = mode;
      if (selectionRevision == _revision) state = mode;
    });
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (mounted && selectionRevision == _revision) state = _persistedMode;
      },
    );
    return result;
  }

  Future<void> toggle() {
    return setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  ThemeMode? _modeFromStored(String? value) {
    switch (value) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  String _storedValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
