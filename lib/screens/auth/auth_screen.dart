// lib/screens/auth/auth_screen.dart
//
// Phase 6A — This route now redirects to /onboarding.
//
// The /auth route is kept in the router for backward compatibility
// (deep links, bookmarks). In Phase 6A it simply pushes onboarding.
// The actual auth UI lives in onboarding_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Immediately redirect to the onboarding flow, which handles all auth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(AppRoutes.onboarding);
    });

    // Render a blank splash-like screen for the single frame before redirect.
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: const SizedBox.shrink(),
    );
  }
}
