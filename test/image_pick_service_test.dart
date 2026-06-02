import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_match_mood/core/services/image_pick_service.dart';

class _FakeImagePickerClient implements ImagePickerClient {
  XFile? pickResult;
  Object? pickError;
  LostDataResponse lostDataResponse = LostDataResponse.empty();
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
  Future<LostDataResponse> retrieveLostData() async => lostDataResponse;
}

void main() {
  test('pickImage forwards source and quality to picker client', () async {
    final client = _FakeImagePickerClient();
    final service = ImagePickService(client: client);
    final file = XFile('/tmp/test-image.jpg');
    client.pickResult = file;

    final result = await service.pickImage(
      source: ImageSource.camera,
      imageQuality: 77,
    );

    expect(result, file);
    expect(client.lastSource, ImageSource.camera);
    expect(client.lastImageQuality, 77);
  });

  test('retrieveLostImage returns single lost file', () async {
    final client = _FakeImagePickerClient();
    final service = ImagePickService(client: client);
    final file = XFile('/tmp/lost-image.jpg');
    client.lostDataResponse = LostDataResponse(
      file: file,
      type: RetrieveType.image,
    );

    final result = await service.retrieveLostImage();

    expect(result, file);
  });

  test('retrieveLostImage returns first file from files list', () async {
    final client = _FakeImagePickerClient();
    final service = ImagePickService(client: client);
    final first = XFile('/tmp/first.jpg');
    final second = XFile('/tmp/second.jpg');
    client.lostDataResponse = LostDataResponse(
      files: [first, second],
      type: RetrieveType.media,
    );

    final result = await service.retrieveLostImage();

    expect(result, first);
  });

  test('retrieveLostImage throws when plugin returns exception', () async {
    final client = _FakeImagePickerClient();
    final service = ImagePickService(client: client);
    final exception = PlatformException(code: 'camera_access_denied');
    client.lostDataResponse = LostDataResponse(exception: exception);

    expect(service.retrieveLostImage(), throwsA(same(exception)));
  });
}
