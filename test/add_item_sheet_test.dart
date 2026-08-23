import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_match_mood/core/providers/wardrobe_provider.dart';
import 'package:mix_match_mood/core/services/clothing_analysis_service.dart';
import 'package:mix_match_mood/core/services/image_pick_service.dart';
import 'package:mix_match_mood/features/wardrobe/add_item_sheet.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

class _FakeImagePickerClient implements ImagePickerClient {
  XFile? pickResult;
  Object? pickError;
  LostDataResponse lostDataResponse = LostDataResponse.empty();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
  }) async {
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async => lostDataResponse;
}

class _TestWardrobeNotifier extends WardrobeNotifier {
  @override
  Future<void> load() async {}

  @override
  Future<void> addItem(ClothingItem item) async {
    state = [...state, item];
  }
}

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required ImagePickService imagePickService,
    required _TestWardrobeNotifier wardrobeNotifier,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imagePickServiceProvider.overrideWith((_) => imagePickService),
          wardrobeProvider.overrideWith((_) => wardrobeNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddItemSheet(
              fileExists: (_) async => true,
              quickPickSource: ImageSource.camera,
              readImage: (_) async => Uint8List.fromList([1, 2, 3]),
              persistImage: (_, name) async => File('/managed/$name'),
              analyzeImage: (_) async => const ClothingAnalysisResult(
                colorHexes: ['#FF0000'],
                colorNames: ['red'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('camera returns an image and preview appears', (tester) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/camera-preview.jpg');
    final notifier = _TestWardrobeNotifier();

    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );

    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('add-item-preview-image')), findsOneWidget);
  });

  testWidgets('android lost data returns an image and preview appears', (
    tester,
  ) async {
    final lostFile = XFile('/tmp/lost-preview.jpg');
    final pickerClient = _FakeImagePickerClient()
      ..lostDataResponse = LostDataResponse(
        file: lostFile,
        type: RetrieveType.image,
      );
    final notifier = _TestWardrobeNotifier();

    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('add-item-preview-image')), findsOneWidget);
  });

  testWidgets('permission denied shows error and does not crash', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickError = PlatformException(code: 'camera_access_denied');
    final notifier = _TestWardrobeNotifier();

    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );

    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Camera permission is denied'), findsOneWidget);
    expect(find.byKey(const Key('add-item-preview-image')), findsNothing);
  });

  testWidgets('save after picked image adds item to wardrobe state', (
    tester,
  ) async {
    final pickedFile = XFile('/tmp/save-picked.jpg');
    final pickerClient = _FakeImagePickerClient()..pickResult = pickedFile;
    final notifier = _TestWardrobeNotifier();

    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );

    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(notifier.state.length, 1);
    expect(notifier.state.first.imageUrl, '/managed/save-picked.jpg');
    expect(notifier.state.first.name, 'Wardrobe item');
    expect(notifier.state.first.colorHexes, ['#FF0000']);
    expect(notifier.state.first.color, 'red');
  });

  testWidgets('manual visual metadata overrides analysis before save', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/manual.jpg');
    final notifier = _TestWardrobeNotifier();

    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-item-hex')), '3366ff');
    await tester.tap(find.byKey(const Key('add-item-pattern')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('solid').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-silhouette')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('slim').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();

    expect(notifier.state.single.colorHexes, ['#3366FF']);
    expect(notifier.state.single.pattern, ClothingPattern.solid);
    expect(notifier.state.single.silhouette, ClothingSilhouette.slim);
  });
}
