import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

Widget _settingsApp(double scale) => ProviderScope(
  key: ValueKey(scale),
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
