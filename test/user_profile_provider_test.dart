import 'dart:async';

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
