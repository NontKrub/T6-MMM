import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/app_settings_provider.dart';
import 'package:mix_match_mood/core/providers/repetition_insight_provider.dart';
import 'package:mix_match_mood/core/services/recommendation_repository.dart';
import 'package:mix_match_mood/features/home/widgets/repetition_insight_card.dart';

class TestSettingsNotifier extends AppSettingsNotifier {
  TestSettingsNotifier(AppSettings settings) {
    state = settings;
  }
}

void main() {
  Widget buildApp(List overrides) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(home: Scaffold(body: RepetitionInsightCard())),
    );
  }

  testWidgets('hides when repetition alerts setting is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp([
        appSettingsProvider.overrideWith(
          (ref) =>
              TestSettingsNotifier(const AppSettings(repetitionAlerts: false)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RepetitionInsightCard), findsOneWidget);
    expect(find.text('Style reminder'), findsNothing);
  });

  testWidgets('hides when backend alert is false', (tester) async {
    await tester.pumpWidget(
      buildApp([
        appSettingsProvider.overrideWith(
          (ref) =>
              TestSettingsNotifier(const AppSettings(repetitionAlerts: true)),
        ),
        repetitionInsightProvider.overrideWith((ref) async {
          return const RepetitionInsight(
            alert: false,
            dominantColor: 'black',
            dominantColorCount: 3,
            dominantStyle: 'casual',
            dominantStyleCount: 2,
          );
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Style reminder'), findsNothing);
  });

  testWidgets('renders backend dominant color when alert is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp([
        appSettingsProvider.overrideWith(
          (ref) =>
              TestSettingsNotifier(const AppSettings(repetitionAlerts: true)),
        ),
        repetitionInsightProvider.overrideWith((ref) async {
          return const RepetitionInsight(
            alert: true,
            dominantColor: 'black',
            dominantColorCount: 4,
            dominantStyle: 'casual',
            dominantStyleCount: 2,
          );
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Style reminder'), findsOneWidget);
    expect(find.textContaining('black'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 800));
  });
}
