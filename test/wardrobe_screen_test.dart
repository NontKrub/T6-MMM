import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/wardrobe_provider.dart';
import 'package:mix_match_mood/features/wardrobe/wardrobe_screen.dart';
import 'package:mix_match_mood/l10n/app_localizations.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';

class _TestWardrobeNotifier extends WardrobeNotifier {
  _TestWardrobeNotifier(List<ClothingItem> items) : _items = items;

  final List<ClothingItem> _items;

  @override
  Future<void> load() async {
    state = _items;
  }
}

void main() {
  testWidgets('wardrobe presents image-first rows with localized metadata', (
    tester,
  ) async {
    final item = ClothingItem(
      id: 'linen-shirt',
      name: 'Linen shirt',
      brand: 'MMM Studio',
      category: ClothingCategory.top,
      imageUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeProvider.overrideWith((_) => _TestWardrobeNotifier([item])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WardrobeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wardrobe-list')), findsOneWidget);
    expect(find.byKey(const Key('wardrobe-item-linen-shirt')), findsOneWidget);
    expect(find.text('Linen shirt'), findsOneWidget);
    expect(find.text('MMM Studio'), findsOneWidget);
    expect(find.text('Top'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeProvider.overrideWith((_) => _TestWardrobeNotifier([item])),
        ],
        child: MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WardrobeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เสื้อ'), findsAtLeastNWidgets(1));
  });
}
