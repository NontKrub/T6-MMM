import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/outfit_provider.dart';

void main() {
  test('rush unavailable message describes wardrobe requirements', () {
    expect(
      rushOutfitUnavailableMessage,
      'No compatible rush outfit is available. Add shoes and a top + bottom or a dress.',
    );
  });
}
