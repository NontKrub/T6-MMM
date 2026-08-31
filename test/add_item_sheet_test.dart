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
  bool uploadFails = false;
  int uploads = 0;

  @override
  Future<void> load() async {}

  @override
  Future<void> addItem(ClothingItem item) async {
    state = [...state, item];
  }

  @override
  Future<void> addUploadedItem({
    required Uint8List bytes,
    required String fileName,
    required String name,
    String? brand,
    required ClothingCategory fallbackCategory,
    List<String> tags = const [],
    List<String> colorHexes = const [],
    String? color,
    ClothingPattern pattern = ClothingPattern.unknown,
    ClothingSilhouette silhouette = ClothingSilhouette.unknown,
    double? analysisConfidence,
    String? classificationSource,
    String? colorSource,
    ClothingAnalysisResult? localAnalysis,
  }) async {
    if (uploadFails) throw StateError('upload failed');
    uploads++;
  }
}

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required ImagePickService imagePickService,
    required _TestWardrobeNotifier wardrobeNotifier,
    ClothingAnalysisResult analysis = const ClothingAnalysisResult(
      category: ClothingCategory.top,
      colorHexes: ['#FF0000'],
      colorNames: ['red'],
    ),
    Future<ClothingAnalysisResult> Function(Uint8List)? analyzeImage,
    Future<File> Function(Uint8List, String)? persistImage,
    Future<void> Function(String)? deleteImage,
    bool signedIn = false,
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
              persistImage:
                  persistImage ?? (_, name) async => File('/managed/$name'),
              analyzeImage: analyzeImage ?? (_) async => analysis,
              deleteImage: deleteImage,
              signedIn: signedIn,
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
    await tester.tap(find.byKey(const Key('add-item-add-hex')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-item-color-#3366FF')));
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

    expect(notifier.state.single.colorHexes, ['#FF0000', '#3366FF']);
    expect(notifier.state.single.color, 'blue');
    expect(notifier.state.single.pattern, ClothingPattern.solid);
    expect(notifier.state.single.silhouette, ClothingSilhouette.slim);
    expect(notifier.state.single.classificationSource, 'manual');
    expect(notifier.state.single.colorSource, 'manual');
  });

  testWidgets('uncertain category requires explicit selection', (tester) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/uncertain.jpg');
    final notifier = _TestWardrobeNotifier();
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      analysis: const ClothingAnalysisResult(
        colorHexes: ['#FFFFFF'],
        colorNames: ['white'],
      ),
    );

    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-item-category-required')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pump();
    expect(find.text('Select a category before saving.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-item-category-accessory')));
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(notifier.state.single.category, ClothingCategory.accessory);
  });

  testWidgets('retains palette removals and selected primary color', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/palette.jpg');
    final notifier = _TestWardrobeNotifier();
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      analysis: const ClothingAnalysisResult(
        category: ClothingCategory.top,
        colorHexes: ['#FF0000', '#00FF00', '#0000FF'],
        colorNames: ['red', 'green', 'blue'],
      ),
    );

    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(3));
    await tester.tap(find.byTooltip('Delete').at(1));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-item-color-#0000FF')));
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();

    expect(notifier.state.single.colorHexes, ['#FF0000', '#0000FF']);
    expect(notifier.state.single.color, 'blue');
    expect(notifier.state.single.colorSource, 'manual');
  });

  testWidgets('replacement and cancellation clean managed images', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/first.jpg');
    final notifier = _TestWardrobeNotifier();
    final deleted = <String>[];
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      deleteImage: (path) async => deleted.add(path),
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    pickerClient.pickResult = XFile('/tmp/second.jpg');
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    expect(deleted, ['/managed/first.jpg']);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(deleted, ['/managed/first.jpg', '/managed/second.jpg']);
  });

  testWidgets('guest save retains managed image', (tester) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/guest.jpg');
    final notifier = _TestWardrobeNotifier();
    final deleted = <String>[];
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      deleteImage: (path) async => deleted.add(path),
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
  });

  testWidgets('signed upload cleans staging only after success', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/signed.jpg');
    final notifier = _TestWardrobeNotifier();
    final deleted = <String>[];
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      deleteImage: (path) async => deleted.add(path),
      signedIn: true,
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();
    expect(notifier.uploads, 1);
    expect(deleted, ['/managed/signed.jpg']);
  });

  testWidgets('signed upload retries failed staging cleanup on dispose', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/retry-cleanup.jpg');
    final notifier = _TestWardrobeNotifier();
    var attempts = 0;
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      deleteImage: (_) async {
        attempts++;
        if (attempts == 1) throw const FileSystemException('busy');
      },
      signedIn: true,
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(attempts, 2);
  });

  testWidgets('failed signed upload keeps staging image for retry', (
    tester,
  ) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/retry.jpg');
    final notifier = _TestWardrobeNotifier()..uploadFails = true;
    final deleted = <String>[];
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      deleteImage: (path) async => deleted.add(path),
      signedIn: true,
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Could not save item'), findsOneWidget);
    expect(deleted, isEmpty);
  });

  testWidgets('analysis failure still permits manual save', (tester) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/manual-fallback.jpg');
    final notifier = _TestWardrobeNotifier();
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
      analyzeImage: (_) async => throw StateError('vision failed'),
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item-category-pants')));
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pumpAndSettle();
    expect(notifier.state.single.category, ClothingCategory.pants);
  });

  testWidgets('invalid HEX blocks save', (tester) async {
    final pickerClient = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/invalid-hex.jpg');
    final notifier = _TestWardrobeNotifier();
    await pumpSheet(
      tester,
      imagePickService: ImagePickService(client: pickerClient),
      wardrobeNotifier: notifier,
    );
    await tester.tap(find.byKey(const Key('add-item-image-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-item-hex')), '#GGGGGG');
    await tester.tap(find.byKey(const Key('add-item-save')));
    await tester.pump();
    expect(notifier.state, isEmpty);
    expect(find.textContaining('valid HEX'), findsOneWidget);
  });
}
