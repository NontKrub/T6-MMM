import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_match_mood/core/navigation/router.dart';
import 'package:mix_match_mood/main.dart' as app;
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/core/services/image_pick_service.dart';
import 'package:mix_match_mood/features/wardrobe/add_item_sheet.dart';
import 'package:mix_match_mood/features/wardrobe/wardrobe_screen.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
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

  testWidgets('guest item persists across wardrobe provider reload', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mmm_guest_enabled': true,
      'mmm_guest_profile': jsonEncode({
        'id': 'local_guest',
        'display_name': 'Guest',
        'onboarding_complete': true,
      }),
    });
    final bytes = await _solidPng(const ui.Color(0xFF3366FF));
    final stored = File(
      '${Directory.systemTemp.path}/mmm-integration-shirt.png',
    );
    final picker = ImagePickService(client: _IntegrationPicker());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          initialRoute: '/add',
          routes: {
            '/': (_) => const SizedBox(),
            '/add': (_) => Scaffold(
              body: AddItemSheet(
                imagePickService: picker,
                quickPickSource: ImageSource.gallery,
                fileExists: (_) async => true,
                readImage: (_) async => bytes,
                persistImage: (data, _) => stored.writeAsBytes(data),
                analyzeImage: (_) async => const ClothingAnalysisResult(
                  category: ClothingCategory.top,
                  colorHexes: ['#3366FF', '#FFFFFF'],
                  colorNames: ['blue', 'white'],
                  styles: ['casual'],
                  confidence: .91,
                  rawLabels: ['shirt'],
                ),
              ),
            ),
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-item-name')),
      'Integration Shirt',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('add-item-save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WardrobeScreen())),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Integration Shirt'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WardrobeScreen())),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Integration Shirt'), findsOneWidget);
    expect(await stored.exists(), isTrue);
    await stored.delete();
  });

  testWidgets('real native classifier bridge returns genuine predictions', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    final data = await rootBundle.load(
      'assets/images/vision_test_white_shirt.jpg',
    );
    final result = await const ClothingAnalysisService().analyze(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );

    expect(result.rawPredictions, isNotEmpty);
    expect(
      result.rawPredictions.every(
        (prediction) =>
            prediction.confidence >= 0 && prediction.confidence <= 1,
      ),
      isTrue,
    );
    expect(result.colorHexes, isNotEmpty);
    expect(result.classificationSource, 'ios_vision');
    expect(result.colorSource, 'pixel_palette');
  });

  testWidgets('native classifier bridge reports invalid and unknown calls', (
    tester,
  ) async {
    if (!Platform.isIOS) return;
    const channel = MethodChannel('mmm/clothing_analysis');

    await expectLater(
      channel.invokeListMethod<Object?>('classifyImage', Uint8List(0)),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      channel.invokeMethod<Object?>('unsupportedMethod'),
      throwsA(isA<MissingPluginException>()),
    );
  });
}

class _IntegrationPicker implements ImagePickerClient {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
  }) async => XFile('/tmp/integration-shirt.png');

  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

Future<Uint8List> _solidPng(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 8, 8), ui.Paint()..color = color);
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
