import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GLB renderer owns the poster and keeps one model viewer', () {
    final source = File(
      'lib/features/home/widgets/glb_avatar_renderer.dart',
    ).readAsStringSync();

    expect(RegExp(r'ModelViewer\(').allMatches(source), hasLength(1));
    expect(source, contains('poster: widget.posterPath'));
    expect(source, isNot(contains('Image.asset(')));
    expect(source, contains('key: ValueKey(widget.modelPath)'));
  });
}
