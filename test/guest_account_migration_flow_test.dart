import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/guest_account_migration_service.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/core/services/wardrobe_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/recommendation_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('migration reports unknown history, preserves it through retry, and '
      'clears local data only after verification', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    await local.startGuestAccount();
    final imageDirectory = await Directory.systemTemp.createTemp(
      'mmm-migration-test-',
    );
    addTearDown(() => imageDirectory.delete(recursive: true));
    final image = File('${imageDirectory.path}/shirt.jpg');
    await image.writeAsBytes([1, 2, 3]);

    const itemId = '4f3c2a1b-7e6d-4c5b-9a8f-0123456789ab';
    await local.insertItem(
      ClothingItem(
        id: itemId,
        name: 'Test shirt',
        category: ClothingCategory.top,
        imageUrl: image.path,
        imagePath: image.path,
      ),
    );
    await local.recordRecommendationEvent(
      RecommendationEvent(
        id: 'legacy-recommendation',
        eventType: RecommendationEventType.unknown,
        itemIds: const [itemId],
        createdAt: DateTime.utc(2026, 9, 4),
      ),
    );
    // Keep the fixture honest: this is the legacy record being migrated.
    expect(await local.fetchRecommendationEvents(), hasLength(1));

    final api = _MigrationApi(failNextDownload: true);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serverSubscription = server.listen(api.handle);
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });
    final client = SupabaseClient(
      'http://${server.address.host}:${server.port}',
      'test-publishable-key',
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'migration@example.com',
      password: 'test-password',
    );

    GuestAccountMigrationService createService() {
      return GuestAccountMigrationService(
        local: local,
        profiles: ProfileRepository(client: client),
        wardrobe: WardrobeRepository(local: local, client: client),
        client: client,
      );
    }

    final first = await createService().migrate();
    expect(first.completed, isFalse);
    expect(first.skippedRecommendationEvents, 1);
    expect(
      first.warnings,
      contains(
        'Skipped recommendation history because its event type is no longer recognized.',
      ),
    );
    expect(await local.hasGuestAccount(), isTrue);
    expect(
      (await local.fetchGuestMigrationState())!['warnings'],
      contains(
        'Skipped recommendation history because its event type is no longer recognized.',
      ),
    );

    api.failNextDownload = false;
    final second = await createService().migrate();

    expect(second.completed, isTrue);
    expect(second.itemsMigrated, 1);
    expect(second.recommendationEventsMigrated, 0);
    expect(second.skippedRecommendationEvents, 1);
    expect(await local.hasGuestAccount(), isFalse);
    expect(api.uploadedItemIds, contains(itemId));
  });
}

class _MigrationApi {
  _MigrationApi({required this.failNextDownload});

  final String userId = 'cloud-user';
  bool failNextDownload;
  bool profileExists = false;
  Map<String, dynamic>? clothingItem;
  final uploadedItemIds = <String>[];

  Future<void> handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final path = request.uri.path;
    if (path.endsWith('/auth/v1/token')) {
      return _jsonResponse(request, 200, {
        'access_token': _jwt(),
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'test-refresh-token',
        'user': _userJson(),
      });
    }
    if (path.startsWith('/rest/v1/')) {
      return _restResponse(request, body);
    }
    if (path.startsWith('/storage/v1/object/')) {
      if (request.method == 'GET') {
        if (failNextDownload) {
          failNextDownload = false;
          return _jsonResponse(request, 500, {'message': 'download failed'});
        }
        return _bytesResponse(request, 200, [1, 2, 3]);
      }
      return _jsonResponse(request, 200, {'Key': path});
    }
    return _jsonResponse(request, 404, {'message': 'unexpected request'});
  }

  Future<void> _restResponse(HttpRequest request, String body) async {
    final table = request.uri.pathSegments.last;
    if (request.method == 'GET') {
      switch (table) {
        case 'profiles':
          return _jsonResponse(
            request,
            200,
            profileExists ? [_profileJson()] : [],
          );
        case 'clothing_items':
          return _jsonResponse(
            request,
            200,
            clothingItem == null ? [] : [clothingItem],
          );
        default:
          return _jsonResponse(request, 200, []);
      }
    }

    if (request.method == 'POST') {
      final payload = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
      switch (table) {
        case 'profiles':
          profileExists = true;
          return _jsonResponse(request, 201, []);
        case 'style_preferences':
          return _jsonResponse(request, 201, []);
        case 'clothing_items':
          final row = Map<String, dynamic>.from(payload as Map)
            ..['image_url'] = '';
          clothingItem = row;
          uploadedItemIds.add(row['id'] as String);
          return _jsonResponse(request, 201, row);
        default:
          return _jsonResponse(request, 201, []);
      }
    }

    return _jsonResponse(request, 200, []);
  }

  Future<void> _jsonResponse(
    HttpRequest request,
    int status,
    Object body,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..add(utf8.encode(jsonEncode(body)));
    await request.response.close();
  }

  Future<void> _bytesResponse(
    HttpRequest request,
    int status,
    List<int> body,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.binary
      ..add(body);
    await request.response.close();
  }

  Map<String, dynamic> _profileJson() => {
    'id': userId,
    'display_name': 'MMM User',
    'avatar_url': null,
    'color_season': 'spring',
    'avatar_type': 'human',
    'onboarding_complete': false,
    'brand_tier': 0.3,
    'body_shape': 'female',
    'skin_tone_index': 1,
    'hair_color_index': 1,
    'hair_style_index': 3,
  };

  Map<String, dynamic> _userJson() => {
    'id': userId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'migration@example.com',
    'app_metadata': {
      'provider': 'email',
      'providers': ['email'],
    },
    'user_metadata': {},
    'created_at': '2026-09-04T00:00:00.000Z',
    'updated_at': '2026-09-04T00:00:00.000Z',
  };

  String _jwt() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String encoded(Map<String, dynamic> value) => base64Url
        .encode(utf8.encode(jsonEncode(value)))
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    return '${encoded({'alg': 'HS256', 'typ': 'JWT'})}.${encoded({'sub': userId, 'iat': now, 'exp': now + 3600})}.test-signature';
  }
}
