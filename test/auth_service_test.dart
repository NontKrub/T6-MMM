import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/auth_service.dart';
import 'package:mix_match_mood/features/auth/auth_screen.dart';

void main() {
  test('Apple name is preserved when the credential provides it once', () {
    expect(appleDisplayName('Ada', 'Lovelace'), 'Ada Lovelace');
    expect(appleDisplayName(' Ada ', null), 'Ada');
    expect(appleDisplayName(null, 'Lovelace'), 'Lovelace');
    expect(appleDisplayName(null, null), isNull);
  });

  test('Apple deletion payload contains no client identity token', () {
    const credential = AppleDeletionCredential(
      authorizationCode: 'authorization-code',
      rawNonce: 'raw-nonce',
    );

    expect(credential.toJson(), {
      'apple_authorization_code': 'authorization-code',
      'apple_nonce': 'raw-nonce',
    });
  });

  test(
    'account deletion skips Apple UI when the server deletes immediately',
    () async {
      final calls = <Map<String, String>>[];
      var appleCalls = 0;
      final coordinator = AccountDeletionCoordinator(
        invokeDeletion: (body) async => calls.add(body),
        requestAppleCredential: () async {
          appleCalls++;
          return const AppleDeletionCredential(
            authorizationCode: 'code',
            rawNonce: 'nonce',
          );
        },
      );

      await coordinator.deleteAccount();

      expect(calls, [const <String, String>{}]);
      expect(appleCalls, 0);
    },
  );

  test(
    'account deletion requests Apple only after the server requires it',
    () async {
      final calls = <Map<String, String>>[];
      var appleCalls = 0;
      final coordinator = AccountDeletionCoordinator(
        invokeDeletion: (body) async {
          calls.add(body);
          if (calls.length == 1) {
            throw const AccountDeletionException(
              code: 'apple_reauthentication_required',
            );
          }
        },
        requestAppleCredential: () async {
          appleCalls++;
          return const AppleDeletionCredential(
            authorizationCode: 'code',
            rawNonce: 'nonce',
          );
        },
      );

      await coordinator.deleteAccount();

      expect(appleCalls, 1);
      expect(calls, [
        const <String, String>{},
        {'apple_authorization_code': 'code', 'apple_nonce': 'nonce'},
      ]);
    },
  );

  test(
    'account deletion retry skips Apple UI after server-side revocation',
    () async {
      var appleCalls = 0;
      final coordinator = AccountDeletionCoordinator(
        invokeDeletion: (_) async {},
        requestAppleCredential: () async {
          appleCalls++;
          return const AppleDeletionCredential(
            authorizationCode: 'code',
            rawNonce: 'nonce',
          );
        },
      );

      await coordinator.deleteAccount();

      expect(appleCalls, 0);
    },
  );

  test(
    'account deletion does not open Apple UI for another backend failure',
    () async {
      var appleCalls = 0;
      final coordinator = AccountDeletionCoordinator(
        invokeDeletion: (_) async => throw const AccountDeletionException(
          code: 'account_deletion_failed',
        ),
        requestAppleCredential: () async {
          appleCalls++;
          return const AppleDeletionCredential(
            authorizationCode: 'code',
            rawNonce: 'nonce',
          );
        },
      );

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(isA<AccountDeletionException>()),
      );
      expect(appleCalls, 0);
    },
  );

  test(
    'account deletion cancellation does not make a second server request',
    () async {
      var serverCalls = 0;
      final coordinator = AccountDeletionCoordinator(
        invokeDeletion: (_) async {
          serverCalls++;
          throw const AccountDeletionException(
            code: 'apple_reauthentication_required',
          );
        },
        requestAppleCredential: () async => throw StateError('cancelled'),
      );

      await expectLater(coordinator.deleteAccount(), throwsStateError);
      expect(serverCalls, 1);
    },
  );

  testWidgets('iOS shows Apple and Google with a create-wardrobe path', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Theme(
            data: ThemeData(platform: TargetPlatform.iOS),
            child: const AuthScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('New to MMM? Create a wardrobe'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsNothing);
  });

  testWidgets(
    'Android hides Apple and keeps Google with a create-wardrobe path',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Theme(
              data: ThemeData(platform: TargetPlatform.android),
              child: const AuthScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('New to MMM? Create a wardrobe'), findsOneWidget);
    },
  );
}
