import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/settings/settings_screen.dart';

void main() {
  test('application version uses the bundle version and build number', () {
    expect(formatApplicationVersion('2.4.1', '37'), '2.4.1 (build 37)');
    expect(formatApplicationVersion('', '37'), '—');
    expect(formatApplicationVersion('2.4.1', ''), '—');
  });

  testWidgets('settings exposes both configured legal documents', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('Privacy Policy'), findsNWidgets(2));
    expect(find.text('Terms of Service'), findsNWidgets(2));
  });
}
