import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ProfileImageStorageService {
  ProfileImageStorageService({Future<Directory> Function()? appDirectory})
    : _appDirectory = appDirectory ?? getApplicationSupportDirectory;

  static const maxDimension = 1024;

  final Future<Directory> Function() _appDirectory;
  Directory? _profileDirectory;

  Future<File> persist(Uint8List bytes, String originalName) async {
    final normalized = await normalize(bytes);
    final directory = await _directory();
    final file = File('${directory.path}/avatar-${_uuid.v4()}.png');
    await file.writeAsBytes(normalized, flush: true);
    return file;
  }

  Future<Uint8List> normalize(Uint8List bytes) async {
    if (bytes.isEmpty) throw const FormatException('empty_profile_image');
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      if (image.width <= 0 || image.height <= 0) {
        throw const FormatException('invalid_profile_image_dimensions');
      }
      final scale = image.width > image.height
          ? maxDimension / image.width
          : maxDimension / image.height;
      final width = scale < 1 ? (image.width * scale).round() : image.width;
      final height = scale < 1 ? (image.height * scale).round() : image.height;
      final output = await _render(image, width, height);
      try {
        final data = await output.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw const FormatException('image_encode_failed');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        output.dispose();
      }
    } finally {
      image.dispose();
      codec.dispose();
    }
  }

  Future<Uint8List> readOwned(String path) async {
    if (!await owns(path)) {
      throw const FileSystemException('profile_path_not_owned');
    }
    return File(path).readAsBytes();
  }

  Future<bool> owns(String path) async {
    final directory = await _directory();
    return path.startsWith('${directory.path}/');
  }

  Future<void> deleteOwned(String path) async {
    if (!await owns(path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<Directory> _directory() async {
    return _profileDirectory ??= Directory(
      '${(await _appDirectory()).path}/profile',
    )..createSync(recursive: true);
  }

  Future<ui.Image> _render(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    return recorder.endRecording().toImage(width, height);
  }
}
