import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/image_storage_service.dart';

void main() {
  test(
    'stores images in managed wardrobe directory with unique names',
    () async {
      final root = await Directory.systemTemp.createTemp('mmm-storage-test');
      addTearDown(() => root.delete(recursive: true));
      final service = ImageStorageService(appDirectory: () async => root);

      final first = await service.persist(
        Uint8List.fromList([1, 2, 3]),
        'shirt.jpg',
      );
      final second = await service.persist(
        Uint8List.fromList([1, 2, 3]),
        'shirt.jpg',
      );

      expect(first.path, startsWith('${root.path}/wardrobe/'));
      expect(await first.exists(), isTrue);
      expect(second.path, isNot(first.path));
      expect(await service.owns(first.path), isTrue);
      expect(await service.owns('${root.parent.path}/external.jpg'), isFalse);
    },
  );
}
