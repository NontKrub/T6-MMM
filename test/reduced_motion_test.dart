import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/home/widgets/avatar_viewer.dart';
import 'package:mix_match_mood/shared/models/user_profile.dart';

void main() {
  testWidgets('avatar does not restart auto-spin after a reduced-motion drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const SizedBox(
            width: 320,
            height: 420,
            child: AvatarViewer(avatarType: AvatarType.human),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(AvatarViewer), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
