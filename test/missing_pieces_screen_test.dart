import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/features/missing_pieces/missing_pieces_screen.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/widgets/mmm_gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('requires top and pants before selected-item analysis', (
    tester,
  ) async {
    final items = [
      _item('top', 'White Shirt', ClothingCategory.top),
      _item('pants', 'Blue Jeans', ClothingCategory.pants),
    ];
    SharedPreferences.setMockInitialValues({
      'mmm_guest_enabled': true,
      'mmm_guest_wardrobe': jsonEncode(
        items.map((item) => item.toJson()).toList(),
      ),
    });
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MissingPiecesScreen())),
    );
    await tester.pumpAndSettle();

    var button = tester.widget<MmmGradientButton>(
      find.byKey(const Key('missing-piece-analyze')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const Key('missing-piece-top')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('White Shirt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('missing-piece-pants')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Jeans').last);
    await tester.pumpAndSettle();

    button = tester.widget<MmmGradientButton>(
      find.byKey(const Key('missing-piece-analyze')),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('missing-piece-analyze')));
    await tester.pumpAndSettle();
    expect(find.text('Add neutral shoes'), findsOneWidget);
  });
}

ClothingItem _item(String id, String name, ClothingCategory category) =>
    ClothingItem(id: id, name: name, category: category, imageUrl: '');
