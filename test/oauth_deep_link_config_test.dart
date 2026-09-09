import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Supabase's app_links listener owns OAuth callbacks. Flutter's default
  // handler would also send them to GoRouter, whose fallback opens Welcome.
  test('iOS leaves OAuth callbacks to Supabase', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>FlutterDeepLinkingEnabled</key>\s*<false\s*/>',
      ).hasMatch(plist),
      isTrue,
    );
    expect(plist, contains('<string>mmm</string>'));
  });

  test('Android leaves OAuth callbacks to Supabase', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = RegExp(
      r'<activity\b[\s\S]*?</activity>',
    ).firstMatch(manifest)!.group(0)!;
    expect(
      RegExp(
        r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+'
        r'android:value="false"\s*/>',
      ).hasMatch(activity),
      isTrue,
    );
    expect(activity, contains('android:scheme="mmm"'));
    expect(activity, contains('android:host="login-callback"'));
  });
}
