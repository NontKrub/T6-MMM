import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_match_mood/core/theme/app_theme.dart';
import 'package:mix_match_mood/features/chatbot/chatbot_screen.dart';
import 'package:mix_match_mood/features/home/home_screen.dart';
import 'package:mix_match_mood/features/auth/auth_screen.dart';
import 'package:mix_match_mood/features/item_detail/item_detail_screen.dart';
import 'package:mix_match_mood/features/language/language_screen.dart';
import 'package:mix_match_mood/features/missing_pieces/missing_pieces_screen.dart';
import 'package:mix_match_mood/features/onboarding/onboarding_screen.dart';
import 'package:mix_match_mood/features/outfit_generator/outfit_generator_sheet.dart';
import 'package:mix_match_mood/features/profile/profile_screen.dart';
import 'package:mix_match_mood/features/shell/main_shell.dart';
import 'package:mix_match_mood/features/settings/settings_screen.dart';
import 'package:mix_match_mood/features/welcome/welcome_screen.dart';
import 'package:mix_match_mood/features/wardrobe/add_item_sheet.dart';
import 'package:mix_match_mood/features/wardrobe/wardrobe_screen.dart';
import 'package:mix_match_mood/l10n/app_localizations.dart';
import 'package:mix_match_mood/shared/models/clothing_item.dart';
import 'package:mix_match_mood/shared/models/outfit.dart';
import 'package:mix_match_mood/shared/widgets/outfit_card.dart';

Widget _scaledApp(
  Widget child,
  double scale, {
  Locale locale = const Locale('en'),
}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, builtChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: builtChild!,
    ),
    home: child,
  ),
);

void main() {
  testWidgets(
    'entry screens remain scroll-safe at short height and 200% text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final locale in [const Locale('en'), const Locale('th')]) {
        for (final scale in [1.0, 1.35, 2.0]) {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          for (final screen in [
            const WelcomeScreen(),
            const LanguageScreen(),
            const AuthScreen(),
          ]) {
            await tester.pumpWidget(_scaledApp(screen, scale, locale: locale));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${locale.languageCode} scale $scale',
            );
          }
        }
      }
    },
  );

  testWidgets(
    'floating navigation grows for large text without clipping labels',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final scale in [1.0, 1.35, 2.0]) {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            ShellRoute(
              builder: (_, __, child) => MainShell(child: child),
              routes: [
                for (final path in ['/home', '/wardrobe', '/missing', '/chat'])
                  GoRoute(
                    path: path,
                    builder: (_, __) => Scaffold(body: Text(path)),
                  ),
              ],
            ),
          ],
        );
        await tester.binding.setSurfaceSize(const Size(320, 568));
        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(tester.getSize(find.byType(MainShell)).height, greaterThan(0));
        expect(tester.takeException(), isNull, reason: 'scale $scale');
      }
    },
  );

  testWidgets(
    'core product surfaces render without compact large-text overflow',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));
      for (final locale in [const Locale('en'), const Locale('th')]) {
        for (final screen in [
          const HomeScreen(),
          const WardrobeScreen(),
          const ChatbotScreen(),
          const MissingPiecesScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ]) {
          await tester.pumpWidget(_scaledApp(screen, 2, locale: locale));
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${screen.runtimeType} at 320x568/200%/${locale.languageCode}',
          );
        }
      }
    },
  );

  testWidgets(
    'forms and detail surfaces remain scroll-safe at compact large text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));
      for (final screen in <Widget>[
        const Material(child: AddItemSheet()),
        const ItemDetailScreen(itemId: 'missing'),
        const OnboardingScreen(isGuest: true),
      ]) {
        await tester.pumpWidget(
          _scaledApp(screen, 2, locale: const Locale('th')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at 320x568/200%',
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('th'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Material(
              child: Consumer(
                builder: (context, ref, _) => OutfitGeneratorSheet(ref: ref),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: 'OutfitGeneratorSheet at 320x568/200%',
      );
    },
  );

  testWidgets('populated outfit cards remain usable on compact large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    const items = [
      ClothingItem(
        id: 'top',
        name: 'White tee',
        category: ClothingCategory.top,
        imageUrl: '',
      ),
      ClothingItem(
        id: 'pants',
        name: 'Blue jeans',
        category: ClothingCategory.pants,
        imageUrl: '',
      ),
      ClothingItem(
        id: 'shoes',
        name: 'Loafers',
        category: ClothingCategory.shoes,
        imageUrl: '',
      ),
      ClothingItem(
        id: 'bag',
        name: 'Tote bag',
        category: ClothingCategory.bag,
        imageUrl: '',
      ),
    ];
    await tester.pumpWidget(
      _scaledApp(
        const Scaffold(
          body: SingleChildScrollView(
            child: OutfitCard(
              outfit: Outfit(
                id: 'outfit',
                name: 'A very considered everyday outfit',
                itemIds: ['top', 'pants', 'shoes', 'bag'],
                reason: 'A balanced mix for a busy day.',
                score: 92,
                style: 'casual',
                selectionFactors: ['color_harmony', 'weather'],
              ),
              items: items,
              onWear: _noop,
            ),
          ),
        ),
        2,
        locale: const Locale('th'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
