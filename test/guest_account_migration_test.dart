import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/guest_account_migration_service.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migration state persists the item mapping used for retries', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    await local.startGuestAccount();

    const state = GuestMigrationState(
      status: GuestMigrationStatus.running,
      targetUserId: 'cloud-user',
      phase: GuestMigrationPhase.wardrobe,
      itemIdMap: {'legacy-item': '4f3c2a1b-7e6d-4c5b-9a8f-0123456789ab'},
    );
    await local.saveGuestMigrationState(state.toJson());

    final restored = GuestMigrationState.fromJson(
      (await local.fetchGuestMigrationState())!,
    );
    expect(restored.status, GuestMigrationStatus.running);
    expect(restored.phase, GuestMigrationPhase.wardrobe);
    expect(restored.itemIdMap, state.itemIdMap);
  });

  test('completed state is no longer pending', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    await local.startGuestAccount();
    await local.saveGuestMigrationState(
      const GuestMigrationState(
        status: GuestMigrationStatus.completed,
        targetUserId: 'cloud-user',
      ).toJson(),
    );

    expect(await GuestAccountMigrationService().hasPendingMigration(), isFalse);
  });

  test('migration failure never clears the local guest wardrobe', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalAccountRepository();
    await local.startGuestAccount();
    await local.insertItem(
      const ClothingItem(
        id: 'local-item',
        category: ClothingCategory.top,
        imageUrl: '/missing/local-image.jpg',
      ),
    );

    final result = await GuestAccountMigrationService().migrate();

    expect(result.completed, isFalse);
    expect(await local.hasGuestAccount(), isTrue);
    expect(await local.fetchItems(), hasLength(1));
  });

  test('event item mapping fails instead of dropping unknown references', () {
    const state = GuestMigrationState(
      status: GuestMigrationStatus.running,
      targetUserId: 'cloud-user',
      itemIdMap: {'local-item': 'cloud-item'},
    );

    expect(
      () => mapGuestItemIds(['local-item', 'missing-item'], state),
      throwsStateError,
    );
    expect(mapGuestItemIds(['local-item'], state), ['cloud-item']);
    expect(tryMapGuestItemIds(['local-item', 'missing-item'], state), isNull);
  });

  test(
    'deleted guest items leave a tombstone for migration warnings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final local = LocalAccountRepository();
      await local.startGuestAccount();
      await local.insertItem(
        const ClothingItem(
          id: 'deleted-item',
          name: 'Old hat',
          category: ClothingCategory.hat,
          imageUrl: '',
        ),
      );

      await local.archiveItem('deleted-item');

      final tombstones = await local.fetchItemTombstones();
      expect(tombstones, hasLength(1));
      expect(tombstones.single.id, 'deleted-item');
      expect(tombstones.single.category, ClothingCategory.hat);
      expect(await local.fetchItems(), isEmpty);

      await local.clearGuestAccount();
      expect(await local.fetchItemTombstones(), isEmpty);
    },
  );
}
