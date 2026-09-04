import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/features/settings/settings_screen.dart';

void main() {
  test('application version uses the bundle version and build number', () {
    expect(formatApplicationVersion('2.4.1', '37'), '2.4.1 (build 37)');
    expect(formatApplicationVersion('', '37'), '—');
    expect(formatApplicationVersion('2.4.1', ''), '—');
  });
}
