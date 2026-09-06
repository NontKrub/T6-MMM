import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interaction bridge exposes bounded, reduced-motion-safe controls', () {
    final source = File(
      'lib/features/home/widgets/avatar_render_bridge.dart',
    ).readAsStringSync();

    expect(source, contains('window.mmmAvatar.applyLook = applyLook'));
    expect(
      source,
      contains('window.mmmAvatar.playInteraction = playInteraction'),
    );
    expect(source, contains("['wave', 'look'].includes(name)"));
    expect(source, contains("playInteraction('wave')"));
    expect(source, contains("playInteraction('look')"));
    expect(source, contains('setTimeout(returnToIdle'));
    expect(source, contains('look.texturesEnabled'));
    expect(source, contains('MMMAvatarTextureError'));
  });

  test(
    'scene payload is versioned without enabling V2 textures by default',
    () {
      final source = File(
        'lib/shared/models/avatar_scene.dart',
      ).readAsStringSync();

      expect(source, contains("'schemaVersion': schemaVersion"));
      expect(source, contains("'textureDigest': textureDigest"));
      expect(source, contains("'textureDataUri': textureDataUri"));
      expect(source, contains('this.texturesEnabled = false'));
    },
  );
}
