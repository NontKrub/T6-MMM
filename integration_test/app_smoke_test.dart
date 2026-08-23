import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_match_mood/core/navigation/router.dart';
import 'package:mix_match_mood/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    appRouter.go('/splash');
    await tester.pumpWidget(const ProviderScope(child: app.MixMatchMoodApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'splash routes to auth when language is chosen and no profile exists',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_locale_chosen': true,
        'app_locale': 'en',
      });

      await pumpApp(tester);

      expect(find.text('Continue as guest'), findsOneWidget);
    },
  );

  testWidgets(
    'guest onboarding-complete profile reaches home and bottom nav works',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_locale_chosen': true,
        'app_locale': 'en',
        'mmm_guest_enabled': true,
        'mmm_guest_profile': jsonEncode({
          'id': 'local_guest',
          'display_name': 'Guest',
          'color_season': 'spring',
          'avatar_type': 'human',
          'onboarding_complete': true,
          'style_preferences': <String>[],
          'occasions': <String>[],
        }),
      });

      await pumpApp(tester);

      expect(find.text('Generate Outfit'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-/wardrobe')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(appRouter.routeInformationProvider.value.uri.path, '/wardrobe');
      expect(find.text('Wardrobe'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-/missing')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Your wardrobe needs'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-/chat')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Fashion AI'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-/home')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Generate Outfit'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Settings'), findsOneWidget);
      Navigator.of(tester.element(find.text('Settings'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Guest').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Profile'), findsOneWidget);
    },
  );
}
