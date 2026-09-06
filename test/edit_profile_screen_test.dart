import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mix_match_mood/core/providers/user_profile_provider.dart';
import 'package:mix_match_mood/core/services/image_pick_service.dart';
import 'package:mix_match_mood/core/services/profile_repository.dart';
import 'package:mix_match_mood/features/profile/edit_profile_screen.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;
  Completer<void>? updateGate;
  int updateCalls = 0;

  @override
  Future<UserProfile?> fetchProfile() async => profile;

  @override
  Future<UserProfile> updateIdentity({
    required String displayName,
    required ProfileAvatarMode avatarMode,
    String? avatarPath,
    Uint8List? customAvatarBytes,
    String customAvatarName = 'profile.png',
  }) async {
    updateCalls++;
    final gate = updateGate;
    if (gate != null) await gate.future;
    profile = profile.copyWith(
      name: displayName,
      avatarMode: avatarMode,
      avatarPath: avatarPath,
    );
    return profile;
  }
}

class _EmptyImagePickerClient implements ImagePickerClient {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
  }) async => null;

  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

class _MemoryPurposeStore implements ImagePickPurposeStore {
  ImagePickPurpose? purpose;

  @override
  Future<ImagePickPurpose?> read() async => purpose;

  @override
  Future<void> write(ImagePickPurpose value) async => purpose = value;

  @override
  Future<void> clear() async => purpose = null;
}

void main() {
  const initial = UserProfile(id: 'local_guest', name: 'Nont');

  Future<_FakeProfileRepository> pumpEditProfile(
    WidgetTester tester, {
    Completer<void>? updateGate,
  }) async {
    final repository = _FakeProfileRepository(initial)..updateGate = updateGate;
    final notifier = UserProfileNotifier(null, repository);
    await notifier.load();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-edit-profile'),
                onPressed: () => context.push('/profile/edit'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const EditProfileScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((_) => notifier),
          imagePickServiceProvider.overrideWith(
            (_) => ImagePickService(
              client: _EmptyImagePickerClient(),
              purposeStore: _MemoryPurposeStore(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.byKey(const Key('open-edit-profile')));
    await tester.pump();
    await tester.pump();
    return repository;
  }

  Future<void> editName(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Changed');
    await tester.pump();
  }

  testWidgets('AppBar Back and Discard exits without a second dialog', (
    tester,
  ) async {
    await pumpEditProfile(tester);
    await editName(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('Keep editing leaves dirty values and no second dialog', (
    tester,
  ) async {
    await pumpEditProfile(tester);
    await editName(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Changed'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('system back uses the same single discard path', (tester) async {
    await pumpEditProfile(tester);
    await editName(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('clean screen exits without confirmation', (tester) async {
    await pumpEditProfile(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('successful Save exits without confirmation', (tester) async {
    final repository = await pumpEditProfile(tester);
    await editName(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('saving blocks AppBar and system back until Save completes', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = await pumpEditProfile(tester, updateGate: gate);
    await editName(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(repository.updateCalls, 1);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
  });
}
