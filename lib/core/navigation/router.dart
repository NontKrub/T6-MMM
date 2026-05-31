import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language/language_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/wardrobe/wardrobe_screen.dart';
import '../../features/missing_pieces/missing_pieces_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  onException: (_, __, router) => router.go('/auth'),
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: '/language',
      builder: (_, state) => LanguageScreen(
        fromSettings:
            (state.extra as Map<String, dynamic>?)?['fromSettings'] as bool? ??
            false,
      ),
    ),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (_, state) => OnboardingScreen(
        isGuest:
            (state.extra as Map<String, dynamic>?)?['isGuest'] as bool? ??
            false,
      ),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/item/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          ItemDetailScreen(itemId: state.pathParameters['id']!),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/wardrobe', builder: (_, __) => const WardrobeScreen()),
        GoRoute(
          path: '/missing',
          builder: (_, __) => const MissingPiecesScreen(),
        ),
        GoRoute(path: '/chat', builder: (_, __) => const ChatbotScreen()),
      ],
    ),
  ],
);
