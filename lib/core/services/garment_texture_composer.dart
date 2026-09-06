import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/models/clothing_item.dart';
import '../../shared/models/garment_visual_fingerprint.dart';
import 'garment_segmentation_service.dart';

class GarmentTextureResult {
  final GarmentVisualFingerprint fingerprint;
  final String? texturePath;
  final String textureDigest;

  const GarmentTextureResult({
    required this.fingerprint,
    required this.texturePath,
    required this.textureDigest,
  });
}

class GarmentTextureComposer {
  GarmentTextureComposer({Future<Directory> Function()? appDirectory})
    : _appDirectory = appDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _appDirectory;

  GarmentVisualFingerprint fingerprint(
    ClothingItem item, {
    GarmentSegmentationResult? segmentation,
    String? sourceDigest,
  }) {
    final kind = switch (item.pattern) {
      ClothingPattern.graphic => GarmentTextureKind.frontGraphic,
      ClothingPattern.striped ||
      ClothingPattern.checked ||
      ClothingPattern.floral ||
      ClothingPattern.textured => GarmentTextureKind.repeatingPattern,
      ClothingPattern.solid => GarmentTextureKind.solid,
      ClothingPattern.other || ClothingPattern.unknown =>
        item.colorHexes.isNotEmpty
            ? GarmentTextureKind.solid
            : GarmentTextureKind.photoApproximation,
    };
    return GarmentVisualFingerprint(
      kind: kind,
      primaryColorHex: _primaryColor(item),
      confidence: segmentation?.isUsable == true ? .95 : .7,
      sourceDigest: sourceDigest,
      usedSegmentation: segmentation?.isUsable == true,
      fallbackReason: segmentation?.isUsable == true
          ? null
          : 'segmentation_unavailable_center_weighted',
      frontGraphicRect: kind == GarmentTextureKind.frontGraphic
          ? const [0.25, 0.2, 0.75, 0.7]
          : null,
    );
  }

  Future<GarmentTextureResult> compose(
    ClothingItem item, {
    Uint8List? sourceBytes,
    GarmentSegmentationResult? segmentation,
  }) async {
    final sourceDigest = sourceBytes == null || sourceBytes.isEmpty
        ? null
        : sha256.convert(sourceBytes).toString();
    final visual = fingerprint(
      item,
      segmentation: segmentation,
      sourceDigest: sourceDigest,
    );
    if (visual.kind == GarmentTextureKind.solid ||
        sourceBytes == null ||
        sourceBytes.isEmpty) {
      return GarmentTextureResult(
        fingerprint: visual,
        texturePath: null,
        textureDigest:
            sourceDigest ??
            sha256.convert(utf8Bytes(visual.stableKey)).toString(),
      );
    }

    try {
      final textureBytes = await _cropToTexture(sourceBytes, segmentation);
      if (textureBytes == null) {
        throw const FormatException('image_decode_failed');
      }
      final root = await _appDirectory();
      final directory = Directory('${root.path}/avatar_textures');
      await directory.create(recursive: true);
      final digest = sha256.convert(textureBytes).toString();
      final file = File('${directory.path}/$digest.png');
      if (!await file.exists()) {
        await file.writeAsBytes(textureBytes, flush: true);
      }
      return GarmentTextureResult(
        fingerprint: visual,
        texturePath: file.path,
        textureDigest: digest,
      );
    } on Object catch (error) {
      return GarmentTextureResult(
        fingerprint: GarmentVisualFingerprint(
          kind: GarmentTextureKind.photoApproximation,
          primaryColorHex: visual.primaryColorHex,
          confidence: .35,
          sourceDigest: sourceDigest,
          usedSegmentation: visual.usedSegmentation,
          fallbackReason: 'texture_compose_failed:${error.runtimeType}',
        ),
        texturePath: null,
        textureDigest:
            sourceDigest ??
            sha256.convert(utf8Bytes(visual.stableKey)).toString(),
      );
    }
  }

  Future<Uint8List?> _cropToTexture(
    Uint8List sourceBytes,
    GarmentSegmentationResult? segmentation,
  ) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = _sourceBounds(image, segmentation);
    canvas.drawImageRect(
      image,
      bounds,
      const ui.Rect.fromLTWH(0, 0, 256, 256),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final output = await recorder.endRecording().toImage(256, 256);
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    output.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  }

  ui.Rect _sourceBounds(
    ui.Image image,
    GarmentSegmentationResult? segmentation,
  ) {
    final box = segmentation?.boundingBox;
    final left = (box != null && box.length == 4 ? box[0] : .12)
        .clamp(0, .9)
        .toDouble();
    final top = (box != null && box.length == 4 ? box[1] : .12)
        .clamp(0, .9)
        .toDouble();
    final right = (box != null && box.length == 4 ? box[2] : .88)
        .clamp(left + .01, 1)
        .toDouble();
    final bottom = (box != null && box.length == 4 ? box[3] : .88)
        .clamp(top + .01, 1)
        .toDouble();
    return ui.Rect.fromLTRB(
      image.width * left,
      image.height * top,
      image.width * right,
      image.height * bottom,
    );
  }

  String? _primaryColor(ClothingItem item) {
    for (final value in item.colorHexes) {
      if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
        return value.toUpperCase();
      }
    }
    return null;
  }

  List<int> utf8Bytes(String value) => value.codeUnits;
}
