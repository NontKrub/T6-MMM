import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_match_mood/core/services/image_pick_service.dart';

class _FakeImagePickerClient implements ImagePickerClient {
  XFile? pickResult;
  Object? pickError;
  LostDataResponse lostDataResponse = LostDataResponse.empty();
  int retrieveLostDataCalls = 0;
  ImageSource? lastSource;
  int? lastImageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
  }) async {
    lastSource = source;
    lastImageQuality = imageQuality;
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async {
    retrieveLostDataCalls++;
    return lostDataResponse;
  }
}

class _FakeImagePickPurposeStore implements ImagePickPurposeStore {
  ImagePickPurpose? pending;

  @override
  Future<ImagePickPurpose?> read() async => pending;

  @override
  Future<void> write(ImagePickPurpose purpose) async => pending = purpose;

  @override
  Future<void> clear() async => pending = null;
}

void main() {
  test('pickImage forwards source and quality to picker client', () async {
    final client = _FakeImagePickerClient();
    final store = _FakeImagePickPurposeStore();
    final service = ImagePickService(client: client, purposeStore: store);
    final file = XFile('/tmp/test-image.jpg');
    client.pickResult = file;

    final result = await service.pickImage(
      source: ImageSource.camera,
      imageQuality: 77,
      purpose: ImagePickPurpose.profileAvatar,
    );

    expect(result, file);
    expect(client.lastSource, ImageSource.camera);
    expect(client.lastImageQuality, 77);
    expect(store.pending, isNull);
  });

  test('retrieveLostImage returns single lost file', () async {
    final client = _FakeImagePickerClient();
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.profileAvatar;
    final service = ImagePickService(client: client, purposeStore: store);
    final file = XFile('/tmp/lost-image.jpg');
    client.lostDataResponse = LostDataResponse(
      file: file,
      type: RetrieveType.image,
    );

    final result = await service.retrieveLostImage(
      purpose: ImagePickPurpose.profileAvatar,
    );

    expect(result, file);
    expect(store.pending, isNull);
  });

  test('retrieveLostImage returns first file from files list', () async {
    final client = _FakeImagePickerClient();
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.wardrobeItem;
    final service = ImagePickService(client: client, purposeStore: store);
    final first = XFile('/tmp/first.jpg');
    final second = XFile('/tmp/second.jpg');
    client.lostDataResponse = LostDataResponse(
      files: [first, second],
      type: RetrieveType.media,
    );

    final result = await service.retrieveLostImage(
      purpose: ImagePickPurpose.wardrobeItem,
    );

    expect(result, first);
  });

  test('retrieveLostImage throws when plugin returns exception', () async {
    final client = _FakeImagePickerClient();
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.profileAvatar;
    final service = ImagePickService(client: client, purposeStore: store);
    final exception = PlatformException(code: 'camera_access_denied');
    client.lostDataResponse = LostDataResponse(exception: exception);

    expect(
      service.retrieveLostImage(purpose: ImagePickPurpose.profileAvatar),
      throwsA(same(exception)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(store.pending, isNull);
  });

  test('normal wardrobe pick stores and clears its purpose', () async {
    final client = _FakeImagePickerClient()
      ..pickResult = XFile('/tmp/item.jpg');
    final store = _FakeImagePickPurposeStore();
    final service = ImagePickService(client: client, purposeStore: store);

    expect(
      await service.pickImage(
        source: ImageSource.gallery,
        purpose: ImagePickPurpose.wardrobeItem,
      ),
      isNotNull,
    );
    expect(store.pending, isNull);
  });

  test('cancelled pick clears its purpose', () async {
    final client = _FakeImagePickerClient();
    final store = _FakeImagePickPurposeStore();
    final service = ImagePickService(client: client, purposeStore: store);

    expect(
      await service.pickImage(
        source: ImageSource.gallery,
        purpose: ImagePickPurpose.profileAvatar,
      ),
      isNull,
    );
    expect(store.pending, isNull);
  });

  test('pick exception clears its purpose and propagates', () async {
    final client = _FakeImagePickerClient()
      ..pickError = StateError('picker failed');
    final store = _FakeImagePickPurposeStore();
    final service = ImagePickService(client: client, purposeStore: store);

    await expectLater(
      service.pickImage(
        source: ImageSource.camera,
        purpose: ImagePickPurpose.profileAvatar,
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.pending, isNull);
  });

  test('profile does not consume wardrobe recovery', () async {
    final client = _FakeImagePickerClient()
      ..lostDataResponse = LostDataResponse(
        file: XFile('/tmp/item.jpg'),
        type: RetrieveType.image,
      );
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.wardrobeItem;
    final service = ImagePickService(client: client, purposeStore: store);

    expect(
      await service.retrieveLostImage(purpose: ImagePickPurpose.profileAvatar),
      isNull,
    );
    expect(client.retrieveLostDataCalls, 0);
    expect(store.pending, ImagePickPurpose.wardrobeItem);
  });

  test('wardrobe consumes its matching recovery', () async {
    final client = _FakeImagePickerClient()
      ..lostDataResponse = LostDataResponse(
        file: XFile('/tmp/item.jpg'),
        type: RetrieveType.image,
      );
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.wardrobeItem;
    final service = ImagePickService(client: client, purposeStore: store);

    expect(
      await service.retrieveLostImage(purpose: ImagePickPurpose.wardrobeItem),
      isNotNull,
    );
    expect(client.retrieveLostDataCalls, 1);
    expect(store.pending, isNull);
  });

  test('wardrobe does not consume profile recovery', () async {
    final client = _FakeImagePickerClient()
      ..lostDataResponse = LostDataResponse(
        file: XFile('/tmp/profile.jpg'),
        type: RetrieveType.image,
      );
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.profileAvatar;
    final service = ImagePickService(client: client, purposeStore: store);

    expect(
      await service.retrieveLostImage(purpose: ImagePickPurpose.wardrobeItem),
      isNull,
    );
    expect(client.retrieveLostDataCalls, 0);
    expect(store.pending, ImagePickPurpose.profileAvatar);
  });

  test('recovery exception clears matching purpose', () async {
    final client = _FakeImagePickerClient();
    final exception = PlatformException(code: 'recovery_failed');
    client.lostDataResponse = LostDataResponse(exception: exception);
    final store = _FakeImagePickPurposeStore()
      ..pending = ImagePickPurpose.profileAvatar;
    final service = ImagePickService(client: client, purposeStore: store);

    await expectLater(
      service.retrieveLostImage(purpose: ImagePickPurpose.profileAvatar),
      throwsA(same(exception)),
    );
    expect(store.pending, isNull);
  });
}
