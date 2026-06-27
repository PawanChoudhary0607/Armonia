// lib/core/routes/app_router.dart
//
// Phase 5B Stability Patch:
//   • Removed AppRoutes.favorites constant and its GoRoute.
//   • Removed import of favorites_screen.dart.
//   • Profile → Liked Songs now uses AppRoutes.likedSongs (already existed).
//   • AppRoutes.recentlyPlayed retained — Profile → Recently Played.
//   • All other routes unchanged.
//
// Phase 6A — Authentication:
//   • Added AppRoutes.onboarding constant.
//   • Added GoRoute for /onboarding → OnboardingScreen.
//   • SplashScreen now reads authProvider and routes to onboarding or home.
//   • No auth guard on existing routes — guest users navigate freely.
//
// PROTECTED FILES UNTOUCHED.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/screens/analytics/analytics_screen.dart';
import 'package:armonia/screens/auth/auth_screen.dart';
import 'package:armonia/screens/auth/onboarding_screen.dart';
import 'package:armonia/screens/home/home_screen.dart';
import 'package:armonia/screens/library/library_screen.dart'
    show LibraryScreen, PlaylistDetailScreen;
import 'package:armonia/screens/library/recently_played_screen.dart';
import 'package:armonia/screens/offline/offline_screen.dart';
import 'package:armonia/screens/player/player_screen.dart';
import 'package:armonia/screens/profile/profile_screen.dart';
import 'package:armonia/screens/search/search_screen.dart';
import 'package:armonia/screens/settings/settings_screen.dart';
import 'package:armonia/screens/splash/splash_screen.dart';
import 'package:armonia/widgets/layout/app_scaffold.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String player = '/player';
  static const String settings = '/settings';
  static const String offline = '/offline';

  /// Liked Songs playlist (pinned, always available via Library and Profile).
  static const String likedSongs = '/library/liked';

  /// Recently Played dedicated screen (reached from Profile).
  static const String recentlyPlayed = '/recently-played';

  /// Helper that produces the path for a user-created playlist.
  static String userPlaylistPath(String id) => '/library/playlist/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),

      // ── Onboarding ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auth,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AuthScreen()),
      ),

      // ── Full-screen Player (no bottom nav) ──────────────────────────────
      GoRoute(
        path: AppRoutes.player,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PlayerScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // ── Offline ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.offline,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OfflineScreen()),
      ),

      // ── Settings ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // ── Liked Songs (Library pinned + Profile entry point) ──────────────
      GoRoute(
        path: AppRoutes.likedSongs,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PlaylistDetailScreen(isLikedSongs: true),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // ── Recently Played (Profile entry point) ───────────────────────────
      GoRoute(
        path: AppRoutes.recentlyPlayed,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const RecentlyPlayedScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // ── User Playlist detail ────────────────────────────────────────────
      GoRoute(
        path: '/library/playlist/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final String id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            child: PlaylistDetailScreen(playlistId: id),
            transitionsBuilder: (context, animation, _, child) =>
                SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 250),
          );
        },
      ),

      // ── Shell route — bottom nav tabs ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.search,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SearchScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.library,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: LibraryScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.analytics,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AnalyticsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: Center(
        child: Text(
          'Route not found: ${state.error}',
          style: TextStyle(color: context.appColors.textPrimary),
        ),
      ),
    ),
  );
});
