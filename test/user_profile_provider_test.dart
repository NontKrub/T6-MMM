import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/user_profile_provider.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;
  final writes = <UserProfile>[];
  Object? nextError;

  @override
  Future<UserProfile?> fetchProfile() async => profile;

  @override
  Future<void> upsertProfile(UserProfile value) async {
    writes.add(value);
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    profile = value;
  }
}

class _DelayedProfileRepository extends ProfileRepository {
  final fetches = <Completer<UserProfile?>>[];
  final writes = <UserProfile>[];

  @override
  Future<UserProfile?> fetchProfile() {
    final fetch = Completer<UserProfile?>();
    fetches.add(fetch);
    return fetch.future;
  }

  @override
  Future<void> upsertProfile(UserProfile value) async {
    writes.add(value);
  }
}

class _ControlledWrite {
  _ControlledWrite(this.profile);

  final UserProfile profile;
  final result = Completer<void>();
}

class _ControlledProfileRepository extends _FakeProfileRepository {
  _ControlledProfileRepository(super.profile);

  final requests = <_ControlledWrite>[];
  bool _blockNextWrite = true;

  @override
  Future<void> upsertProfile(UserProfile value) {
    writes.add(value);
    if (!_blockNextWrite) {
      profile = value;
      return Future.value();
    }
    _blockNextWrite = false;
    final request = _ControlledWrite(value);
    requests.add(request);
    return request.result.future.then((_) => profile = value);
  }
}

class _IdentityRequest {
  _IdentityRequest(this.displayName);

  final String displayName;
  final result = Completer<UserProfile>();
}

class _IdentityProfileRepository extends _FakeProfileRepository {
  _IdentityProfileRepository(super.profile);

  final requests = <_IdentityRequest>[];
  final _startWaiters = <Completer<void>>[];

  Future<void> waitForIdentityStart() {
    final waiter = Completer<void>();
    _startWaiters.add(waiter);
    return waiter.future;
  }

  @override
  Future<UserProfile> updateIdentity({
    required String displayName,
    required ProfileAvatarMode avatarMode,
    String? avatarPath,
    Uint8List? customAvatarBytes,
    String customAvatarName = 'profile.png',
  }) {
    final request = _IdentityRequest(displayName);
    requests.add(request);
    if (_startWaiters.isNotEmpty) {
      _startWaiters.removeAt(0).complete();
    }
    return request.result.future.then((updated) {
      profile = updated;
      return updated;
    });
  }
}

void main() {
  const initial = UserProfile(
    id: 'local_guest',
    name: 'Guest',
    stylePreferences: ['Casual'],
    occasions: ['Work'],
  );

  Future<UserProfileNotifier> createNotifier(
    _FakeProfileRepository repository,
  ) async {
    final notifier = UserProfileNotifier(null, repository);
    await notifier.load();
    return notifier;
  }

  test('failed style save does not change committed state', () async {
    final repository = _FakeProfileRepository(initial)
      ..nextError = StateError('offline');
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    await expectLater(
      notifier.saveStylePreferences(['Streetwear']),
      throwsA(isA<StateError>()),
    );

    expect(notifier.state.stylePreferences, ['Casual']);
  });

  test('preference queue continues after failure and retry succeeds', () async {
    final repository = _FakeProfileRepository(initial)
      ..nextError = StateError('offline');
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    await expectLater(
      notifier.saveStylePreferences(['Streetwear']),
      throwsA(isA<StateError>()),
    );
    await notifier.saveStylePreferences(['Minimalist']);

    expect(notifier.state.stylePreferences, ['Minimalist']);
    expect(repository.writes, hasLength(2));
  });

  test('failed occasion save preserves the old occasions', () async {
    final repository = _FakeProfileRepository(initial)
      ..nextError = StateError('offline');
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    await expectLater(
      notifier.saveOccasions(['Dates']),
      throwsA(isA<StateError>()),
    );

    expect(notifier.state.occasions, ['Work']);
  });

  test('failed color season save preserves the old season', () async {
    final repository = _FakeProfileRepository(initial)
      ..nextError = StateError('offline');
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    await expectLater(
      notifier.saveColorSeason(ColorSeason.winter),
      throwsA(isA<StateError>()),
    );

    expect(notifier.state.colorSeason, ColorSeason.spring);
  });

  test('queued preference mutations preserve each other', () async {
    final repository = _FakeProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    await Future.wait([
      notifier.saveStylePreferences(['Streetwear']),
      notifier.saveOccasions(['Dates']),
    ]);

    expect(notifier.state.stylePreferences, ['Streetwear']);
    expect(notifier.state.occasions, ['Dates']);
    expect(repository.writes.last.stylePreferences, ['Streetwear']);
    expect(repository.writes.last.occasions, ['Dates']);
  });

  test('color season save retains a newer name mutation', () async {
    final repository = _ControlledProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final save = notifier.saveColorSeason(ColorSeason.winter);
    await Future<void>.delayed(Duration.zero);
    notifier.updateName('Nont');
    repository.requests.single.result.complete();

    await save;
    await notifier.flush();

    expect(notifier.state.name, 'Nont');
    expect(notifier.state.colorSeason, ColorSeason.winter);
    expect(repository.profile.name, 'Nont');
    expect(repository.profile.colorSeason, ColorSeason.winter);
  });

  test('style save retains a newer unrelated mutation', () async {
    final repository = _ControlledProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final save = notifier.saveStylePreferences(['Streetwear']);
    await Future<void>.delayed(Duration.zero);
    notifier.updateName('Nont');
    repository.requests.single.result.complete();

    await save;
    await notifier.flush();

    expect(notifier.state.name, 'Nont');
    expect(notifier.state.stylePreferences, ['Streetwear']);
    expect(repository.profile.name, 'Nont');
    expect(repository.profile.stylePreferences, ['Streetwear']);
  });

  test('occasion save retains a newer unrelated mutation', () async {
    final repository = _ControlledProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final save = notifier.saveOccasions(['Dates']);
    await Future<void>.delayed(Duration.zero);
    notifier.updateName('Nont');
    repository.requests.single.result.complete();

    await save;
    await notifier.flush();

    expect(notifier.state.name, 'Nont');
    expect(notifier.state.occasions, ['Dates']);
    expect(repository.profile.name, 'Nont');
    expect(repository.profile.occasions, ['Dates']);
  });

  test(
    'failed save keeps a newer edit and does not poison the queue',
    () async {
      final repository = _ControlledProfileRepository(initial);
      final notifier = await createNotifier(repository);
      addTearDown(notifier.dispose);

      final save = notifier.saveColorSeason(ColorSeason.winter);
      await Future<void>.delayed(Duration.zero);
      notifier.updateName('Nont');
      final failed = expectLater(save, throwsA(isA<StateError>()));
      repository.requests.single.result.completeError(StateError('offline'));
      await failed;
      await notifier.flush();

      await notifier.saveStylePreferences(['Streetwear']);

      expect(notifier.state.name, 'Nont');
      expect(notifier.state.colorSeason, ColorSeason.spring);
      expect(notifier.state.stylePreferences, ['Streetwear']);
      expect(repository.profile.name, 'Nont');
      expect(repository.profile.colorSeason, ColorSeason.spring);
      expect(repository.profile.stylePreferences, ['Streetwear']);
    },
  );

  test(
    'identity update preserves a newer optimistic profile mutation',
    () async {
      final repository = _IdentityProfileRepository(initial);
      final notifier = await createNotifier(repository);
      addTearDown(notifier.dispose);

      final started = repository.waitForIdentityStart();
      final identity = notifier.updateIdentity(
        displayName: 'Nont',
        avatarMode: ProfileAvatarMode.custom,
        avatarPath: '/profile.png',
      );
      await started;

      notifier.updateColorSeason(ColorSeason.winter);
      repository.requests.single.result.complete(
        initial.copyWith(
          name: 'Nont',
          avatarMode: ProfileAvatarMode.custom,
          avatarPath: '/profile.png',
          avatarDisplayUrl: '/profile.png',
        ),
      );

      await identity;
      await notifier.flush();

      expect(notifier.state.name, 'Nont');
      expect(notifier.state.avatarPath, '/profile.png');
      expect(notifier.state.colorSeason, ColorSeason.winter);
      expect(repository.profile.colorSeason, ColorSeason.winter);
    },
  );

  test('preference save queues behind identity update', () async {
    final repository = _IdentityProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final started = repository.waitForIdentityStart();
    final identity = notifier.updateIdentity(
      displayName: 'Nont',
      avatarMode: ProfileAvatarMode.none,
    );
    await started;

    final preferences = notifier.saveStylePreferences(['Streetwear']);
    repository.requests.single.result.complete(initial.copyWith(name: 'Nont'));

    await Future.wait([identity, preferences]);
    await notifier.flush();

    expect(notifier.state.name, 'Nont');
    expect(notifier.state.stylePreferences, ['Streetwear']);
    expect(repository.profile.stylePreferences, ['Streetwear']);
  });

  test('identity updates execute in request order', () async {
    final repository = _IdentityProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final firstStarted = repository.waitForIdentityStart();
    final first = notifier.updateIdentity(
      displayName: 'First',
      avatarMode: ProfileAvatarMode.none,
    );
    await firstStarted;

    final secondStarted = repository.waitForIdentityStart();
    final second = notifier.updateIdentity(
      displayName: 'Second',
      avatarMode: ProfileAvatarMode.none,
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.requests, hasLength(1));

    repository.requests[0].result.complete(initial.copyWith(name: 'First'));
    await first;
    await secondStarted;
    expect(repository.requests.map((request) => request.displayName), [
      'First',
      'Second',
    ]);

    repository.requests[1].result.complete(initial.copyWith(name: 'Second'));
    await second;
    expect(notifier.state.name, 'Second');
  });

  test('failed identity update does not poison the write queue', () async {
    final repository = _IdentityProfileRepository(initial);
    final notifier = await createNotifier(repository);
    addTearDown(notifier.dispose);

    final started = repository.waitForIdentityStart();
    final identity = notifier.updateIdentity(
      displayName: 'Nont',
      avatarMode: ProfileAvatarMode.none,
    );
    await started;
    repository.requests.single.result.completeError(StateError('offline'));

    await expectLater(identity, throwsA(isA<StateError>()));
    await notifier.saveStylePreferences(['Streetwear']);

    expect(notifier.state.name, 'Guest');
    expect(notifier.state.stylePreferences, ['Streetwear']);
  });

  test('initial load cannot overwrite a local mutation', () async {
    final repository = _DelayedProfileRepository();
    final notifier = UserProfileNotifier(null, repository);
    addTearDown(notifier.dispose);

    notifier.updateName('Fresh');
    repository.fetches.single.complete(initial.copyWith(name: 'Stale'));
    await notifier.flush();
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.name, 'Fresh');
  });

  test('an explicit reload supersedes the constructor load', () async {
    final repository = _DelayedProfileRepository();
    final notifier = UserProfileNotifier(null, repository);
    addTearDown(notifier.dispose);

    final reload = notifier.load();
    expect(repository.fetches, hasLength(2));
    repository.fetches[1].complete(initial.copyWith(name: 'Reloaded'));
    await reload;
    repository.fetches[0].complete(initial.copyWith(name: 'Stale'));
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.name, 'Reloaded');
  });

  test('disposing during a load prevents post-dispose application', () async {
    final repository = _DelayedProfileRepository();
    final notifier = UserProfileNotifier(null, repository);
    final reload = notifier.load();
    notifier.dispose();

    repository.fetches[1].complete(initial.copyWith(name: 'Reloaded'));
    await expectLater(reload, completes);
    repository.fetches[0].complete(initial.copyWith(name: 'Stale'));
    await Future<void>.delayed(Duration.zero);

    expect(notifier.mounted, isFalse);
  });
}
