import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/outfit_generator/in_a_rush_modal.dart';
import 'package:mix_match_mood/l10n/app_localizations.dart';

void main() {
  testWidgets('Rush error keeps Reshuffle and Got It actionable', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => InARushModal(
                  ref: ref,
                  rushOutfitLoader: (_) async {
                    requests++;
                    throw StateError('offline');
                  },
                ),
              ),
              child: const Text('Open Rush'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Rush'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not pick a rush outfit right now. Check your wardrobe and try again.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Reshuffle'), findsOneWidget);
    expect(find.bySemanticsLabel('Got It'), findsOneWidget);

    await tester.tap(find.text('Reshuffle'));
    await tester.pumpAndSettle();
    expect(requests, 2);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();
    expect(find.text('In a Rush'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
