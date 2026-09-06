import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/features/home/widgets/outfit_flatlay.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

void main() {
  test('flatlay placements are deterministic and category-specific', () {
    final top = OutfitFlatlayPlacement.forCategory(ClothingCategory.top);
    final pants = OutfitFlatlayPlacement.forCategory(ClothingCategory.pants);
    final dress = OutfitFlatlayPlacement.forCategory(ClothingCategory.dress);

    final topAgain = OutfitFlatlayPlacement.forCategory(ClothingCategory.top);
    expect(top.left, topAgain.left);
    expect(top.top, topAgain.top);
    expect(top.top, lessThan(pants.top));
    expect(dress.height, greaterThan(top.height));
  });
}
