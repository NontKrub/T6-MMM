import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/theme_provider.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/settings/settings_screen.dart';
import 'package:mix_match_mood/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('application version uses the bundle version and build number', () {
    expect(formatApplicationVersion('2.4.1', '37'), '2.4.1 (build 37)');
    expect(formatApplicationVersion('', '37'), '—');
    expect(formatApplicationVersion('2.4.1', ''), '—');
  });

  testWidgets('appearance sheet offers system, light, and dark modes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    for (final scale in [1.0, 1.35, 2.0]) {
      await preferences.clear();
      await tester.pumpWidget(_settingsApp(scale));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Follows your device appearance'), findsOneWidget);
      expect(find.text('Always use light appearance'), findsOneWidget);
      expect(find.text('Always use dark appearance'), findsOneWidget);

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(preferences.getString('mmm_theme_mode'), 'dark');
      expect(tester.takeException(), isNull, reason: 'text scale $scale');
    }
  });

  testWidgets('theme save failure keeps the sheet open and can retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var unavailable = true;
    final notifier = ThemeModeNotifier(
      preferencesLoader: () async {
        if (unavailable) throw StateError('storage unavailable');
        return preferences;
      },
    );
    await tester.pumpWidget(_settingsApp(1, notifier: notifier));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save the theme. Try again."), findsOneWidget);
    expect(notifier.state, ThemeMode.system);
    expect(tester.takeException(), isNull);

    unavailable = false;
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save the theme. Try again."), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(notifier.state, ThemeMode.dark);
    expect(preferences.getString('mmm_theme_mode'), 'dark');
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme save disables other options while pending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final saveGate = Completer<SharedPreferences>();
    var loaderCalls = 0;
    final notifier = ThemeModeNotifier(
      preferencesLoader: () {
        loaderCalls++;
        return loaderCalls == 1 ? Future.value(preferences) : saveGate.future;
      },
    );
    await tester.pumpWidget(_settingsApp(1, notifier: notifier));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(notifier.state, ThemeMode.dark);
    await tester.tap(find.text('Light').last);
    await tester.pump();
    expect(notifier.state, ThemeMode.dark);

    saveGate.complete(preferences);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(preferences.getString('mmm_theme_mode'), 'dark');
    expect(tester.takeException(), isNull);
  });
}

Widget _settingsApp(double scale, {ThemeModeNotifier? notifier}) =>
    ProviderScope(
      key: ValueKey(scale),
      overrides: [
        if (notifier != null) themeModeProvider.overrideWith((_) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    );
