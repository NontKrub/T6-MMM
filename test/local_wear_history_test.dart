import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/services/local_account_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists normalized outfit combinations', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalAccountRepository();

    await repository.recordWearCombination(['top', 'pants']);
    await repository.recordWearCombination(['pants', 'top']);

    expect(await repository.fetchWearCombinations(), [
      ['pants', 'top'],
      ['pants', 'top'],
    ]);
  });
}
