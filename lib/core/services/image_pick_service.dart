import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final imagePickServiceProvider = Provider<ImagePickService>(
  (_) => ImagePickService(),
);

enum ImagePickPurpose { wardrobeItem, profileAvatar }

abstract class ImagePickPurposeStore {
  Future<ImagePickPurpose?> read();

  Future<void> write(ImagePickPurpose purpose);

  Future<void> clear();
}

class SharedPreferencesImagePickPurposeStore implements ImagePickPurposeStore {
  static const _key = 'mmm_pending_image_pick_purpose';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<ImagePickPurpose?> read() async {
    final preferences = await _preferences;
    final value = preferences.getString(_key);
    for (final purpose in ImagePickPurpose.values) {
      if (purpose.name == value) return purpose;
    }
    if (value != null) await preferences.remove(_key);
    return null;
  }

  @override
  Future<void> write(ImagePickPurpose purpose) async {
    await (await _preferences).setString(_key, purpose.name);
  }

  @override
  Future<void> clear() async {
    await (await _preferences).remove(_key);
  }
}

class ImagePickService {
  ImagePickService({
    ImagePickerClient? client,
    ImagePickPurposeStore? purposeStore,
  }) : _client = client ?? PluginImagePickerClient(),
       _purposeStore = purposeStore ?? SharedPreferencesImagePickPurposeStore();

  final ImagePickerClient _client;
  final ImagePickPurposeStore _purposeStore;

  Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 80,
    required ImagePickPurpose purpose,
  }) async {
    await _purposeStore.write(purpose);
    try {
      return await _client.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
    } finally {
      await _clearPurpose();
    }
  }

  Future<XFile?> retrieveLostImage({required ImagePickPurpose purpose}) async {
    if (await _purposeStore.read() != purpose) return null;
    try {
      final response = await _client.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.exception != null) {
        throw response.exception!;
      }
      if (response.file != null) return response.file;
      final files = response.files;
      if (files != null && files.isNotEmpty) return files.first;
      return null;
    } finally {
      await _clearPurpose();
    }
  }

  Future<void> _clearPurpose() async {
    try {
      await _purposeStore.clear();
    } catch (error) {
      debugPrint('Unable to clear image picker purpose: $error');
    }
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
