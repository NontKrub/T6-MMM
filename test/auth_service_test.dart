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

  testWidgets('iOS shows Apple and Google while keeping Guest visible', (
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
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsNothing);
  });

  testWidgets('Android hides Apple and keeps Google and Guest visible', (
    tester,
  ) async {
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
    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
