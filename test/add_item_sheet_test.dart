import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_match_mood/core/providers/wardrobe_provider.dart';
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
    expect(notifier.state.first.imageUrl, pickedFile.path);
    expect(notifier.state.first.name, 'Wardrobe item');
  });
}
