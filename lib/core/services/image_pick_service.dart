import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickServiceProvider = Provider<ImagePickService>(
  (_) => ImagePickService(),
);

class ImagePickService {
  ImagePickService({ImagePickerClient? client})
    : _client = client ?? PluginImagePickerClient();

  final ImagePickerClient _client;

  Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 80,
  }) {
    return _client.pickImage(source: source, imageQuality: imageQuality);
  }

  Future<XFile?> retrieveLostImage() async {
    final response = await _client.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null) {
      throw response.exception!;
    }
    if (response.file != null) return response.file;
    final files = response.files;
    if (files != null && files.isNotEmpty) return files.first;
    return null;
  }
}

abstract class ImagePickerClient {
  Future<XFile?> pickImage({required ImageSource source, int? imageQuality});

  Future<LostDataResponse> retrieveLostData();
}

class PluginImagePickerClient implements ImagePickerClient {
  PluginImagePickerClient({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage({required ImageSource source, int? imageQuality}) {
    return _picker.pickImage(source: source, imageQuality: imageQuality);
  }

  @override
  Future<LostDataResponse> retrieveLostData() {
    return _picker.retrieveLostData();
  }
}
