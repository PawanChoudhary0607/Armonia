// lib/screens/splash/splash_screen.dart
//
// Phase 6A.1 — Session persistence fix.
//
// Root cause of the bug:
//   authProvider is an AsyncNotifier whose build() awaits persistUser().
//   SplashScreen waited 2000ms then read ref.read(authProvider).valueOrNull.
//   If build() hadn't settled, valueOrNull was null → routed to onboarding.
//
// Fix:
//   SplashScreen now reads SharedPreferences directly via AuthRepository's
//   synchronous helpers. SharedPreferences is resolved before runApp() in
//   main.dart, so these reads are always instant with no async dependency.
//
// Routing logic (definitive):
//   1. onboardingDone == false              → /onboarding (first-ever launch)
//   2. onboardingDone == true AND user exists → / (home)
//   3. onboardingDone == true AND no user   → /onboarding (page 2, sign-out)
//
// The animation is unchanged from the Phase 1 implementation.
// All protected files remain untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/repositories/auth_repository.dart';
import 'package:armonia/providers/settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  void _navigate() {
    if (!mounted) return;

    // SharedPreferences is already in memory (resolved before runApp in
    // main.dart via sharedPreferencesProvider). These reads are synchronous
    // and never block or race with any async provider build.
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final AuthRepository repo = AuthRepository(prefs: prefs);

    final bool onboardingDone = repo.hasOnboardingCompleted();
    final bool hasUser = repo.loadPersistedUserSync() != null;

    if (onboardingDone && hasUser) {
      // Normal returning launch — go straight to the app.
      context.go(AppRoutes.home);
    } else {
      // First launch, or signed out: show onboarding.
      // OnboardingScreen handles both the welcome flow (first launch) and
      // the auth-options-only flow (after sign-out), controlled by whether
      // the onboarding flag is set.
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArmoniaLogoMark(
                color: AppColors.accentArmoniaCyan,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Armonia',
                style: AppTypography.displayMd.copyWith(
                  color: context.appColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Armonia logo mark — three vertical bars at different heights.
/// Reusable across splash, auth, and any branding contexts.
class ArmoniaLogoMark extends StatelessWidget {
  const ArmoniaLogoMark({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double barWidth = size * 0.16;
    final double gap = size * 0.10;

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(barWidth, size * 0.55, color),
          SizedBox(width: gap),
          _bar(barWidth, size * 1.0, color),
          SizedBox(width: gap),
          _bar(barWidth, size * 0.75, color),
        ],
      ),
    );
  }

  Widget _bar(double width, double height, Color c) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(width / 2),
        ),
      );
}
