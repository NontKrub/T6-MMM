import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/garment_segmentation_service.dart';
import 'package:mix_match_mood/core/services/garment_texture_composer.dart';
import 'package:mix_match_mood/core/services/wearable_asset_cache.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/garment_visual_fingerprint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'segmentation sends image bytes inside the platform argument map',
    () async {
      const channel = MethodChannel('mmm/test_clothing_analysis');
      MethodCall? call;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            call = methodCall;
            return {
              'width': 2,
              'height': 1,
              'mask': Uint8List.fromList([255, 0]),
              'confidence': .75,
              'boundingBox': [0.0, 0.0, 0.5, 1.0],
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await GarmentSegmentationService(
        channel: channel,
      ).segment(bytes);

      expect(call?.method, 'segmentForeground');
      expect(call?.arguments, isA<Map>());
      expect((call?.arguments as Map)['bytes'], bytes);
      expect(result?.width, 2);
      expect(result?.height, 1);
      expect(result?.alpha, [255, 0]);
      expect(result?.confidence, .75);
      expect(result?.boundingBox, [0.0, 0.0, 0.5, 1.0]);
    },
  );

  test(
    'segmentation returns null for platform failures and malformed payloads',
    () async {
      const channel = MethodChannel('mmm/test_clothing_analysis_failures');
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw PlatformException(code: 'vision_failed');
          });
      final service = GarmentSegmentationService(channel: channel);
      expect(await service.segment(Uint8List.fromList([1])), isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw MissingPluginException();
          });
      expect(await service.segment(Uint8List.fromList([1])), isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (methodCall) async => {'width': 1},
          );
      expect(await service.segment(Uint8List.fromList([1])), isNull);
    },
  );

  test('classifies the supported garment visual cases', () {
    final composer = GarmentTextureComposer();

    expect(
      composer.fingerprint(_item(color: '#FFFFFF')).kind,
      GarmentTextureKind.solid,
    ); // white shirt on blue background
    expect(
      composer.fingerprint(_item(color: '#111111')).kind,
      GarmentTextureKind.solid,
    ); // black solid tee
    expect(
      composer
          .fingerprint(
            _item(color: '#FFFFFF', pattern: ClothingPattern.graphic),
          )
          .kind,
      GarmentTextureKind.frontGraphic,
    ); // red graphic on white tee
    expect(
      composer
          .fingerprint(
            _item(color: '#2E5AA7', pattern: ClothingPattern.striped),
          )
          .kind,
      GarmentTextureKind.repeatingPattern,
    ); // stripe
    expect(
      composer
          .fingerprint(
            _item(color: '#2E5AA7', pattern: ClothingPattern.checked),
          )
          .kind,
      GarmentTextureKind.repeatingPattern,
    ); // plaid
  });

  test(
    'failed segmentation still produces a photo approximation fallback',
    () async {
      final directory = await Directory.systemTemp.createTemp('mmm-textures-');
      addTearDown(() => directory.delete(recursive: true));
      final composer = GarmentTextureComposer(
        appDirectory: () async => directory,
      );

      final result = await composer.compose(
        _item(color: '#FFFFFF', pattern: ClothingPattern.graphic),
        sourceBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      expect(result.texturePath, isNull);
      expect(result.fingerprint.kind, GarmentTextureKind.photoApproximation);
      expect(
        result.fingerprint.fallbackReason,
        contains('texture_compose_failed'),
      );
    },
  );

  test(
    'valid image bytes are written under local application support storage',
    () async {
      final directory = await Directory.systemTemp.createTemp('mmm-textures-');
      addTearDown(() => directory.delete(recursive: true));
      final composer = GarmentTextureComposer(
        appDirectory: () async => directory,
      );

      final result = await composer.compose(
        _item(color: '#FFFFFF', pattern: ClothingPattern.striped),
        sourceBytes: await File(
          'assets/images/vision_test_white_shirt.jpg',
        ).readAsBytes(),
        segmentation: GarmentSegmentationResult(
          width: 1,
          height: 1,
          alpha: Uint8List.fromList([255]),
          confidence: 1,
          boundingBox: [0, 0, 1, 1],
        ),
      );

      expect(
        result.texturePath,
        isNotNull,
        reason: result.fingerprint.fallbackReason,
      );
      expect(await File(result.texturePath!).exists(), isTrue);
      expect(result.textureDigest, isNotEmpty);
      expect(result.fingerprint.usedSegmentation, isTrue);
    },
  );

  test('V2 cache stores texture metadata separately from V1', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = WearableAssetCache();
    final item = _item(color: '#111111');

    final asset = await cache.rebuildV2(item);
    final restored = await cache.getV2(item);

    expect(asset.assetVersion, 2);
    expect(restored?.assetVersion, 2);
    expect(await cache.get(item), isNull);
    expect(restored?.textureDataUri, isNull);
  });
}

ClothingItem _item({
  required String color,
  ClothingPattern pattern = ClothingPattern.solid,
}) => ClothingItem(
  id: 'item-${color.replaceAll('#', '')}-${pattern.name}',
  name: 'Test garment',
  category: ClothingCategory.top,
  imageUrl: '',
  colorHexes: [color],
  pattern: pattern,
);
