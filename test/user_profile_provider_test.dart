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
}
