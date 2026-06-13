// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/screens/analytics/analytics_screen.dart';
import 'package:armonia/screens/auth/auth_screen.dart';
import 'package:armonia/screens/home/home_screen.dart';
import 'package:armonia/screens/library/library_screen.dart';
import 'package:armonia/screens/offline/offline_screen.dart';
import 'package:armonia/screens/player/player_screen.dart';
import 'package:armonia/screens/profile/profile_screen.dart';
import 'package:armonia/screens/search/search_screen.dart';
import 'package:armonia/screens/settings/settings_screen.dart';
import 'package:armonia/screens/splash/splash_screen.dart';
import 'package:armonia/widgets/layout/app_scaffold.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String player = '/player';
  static const String settings = '/settings';
  static const String offline = '/offline';

  static String playlistPath(String id) => '/library/playlist/$id';
  static String artistPath(String id) => '/artist/$id';
  static String albumPath(String id) => '/album/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.auth,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AuthScreen()),
      ),

      // Full-screen player (no bottom nav)
      GoRoute(
        path: AppRoutes.player,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PlayerScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // Offline
      GoRoute(
        path: AppRoutes.offline,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OfflineScreen()),
      ),

      // Settings — pushed from Profile (no bottom nav)
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // Shell route — bottom nav tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),

          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SearchScreen()),
              ),
            ],
          ),

          // Tab 2: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LibraryScreen()),
              ),
            ],
          ),

          // Tab 3: Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analytics,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AnalyticsScreen()),
              ),
            ],
          ),

          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Text(
          'Route not found: ${state.error}',
          style: const TextStyle(color: Color(0xFFF0F0F0)),
        ),
      ),
    ),
  );
});
