import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ImageStorageService {
  ImageStorageService({Future<Directory> Function()? appDirectory})
    : _appDirectory = appDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _appDirectory;
  Directory? _wardrobeDirectory;

  Future<File> persist(Uint8List bytes, String originalName) async {
    final root = await _appDirectory();
    final directory = Directory('${root.path}/wardrobe');
    await directory.create(recursive: true);
    _wardrobeDirectory = directory;
    final extension = _safeExtension(originalName);
    final file = File('${directory.path}/${_uuid.v4()}.$extension');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<bool> owns(String path) async {
    final directory =
        _wardrobeDirectory ??
        Directory('${(await _appDirectory()).path}/wardrobe');
    return path.startsWith('${directory.path}/');
  }

  Future<void> deleteOwned(String path) async {
    if (!await owns(path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String _safeExtension(String name) {
    final extension = name.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)
        ? extension
        : 'jpg';
  }
}
