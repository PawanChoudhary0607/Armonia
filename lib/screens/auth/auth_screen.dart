// lib/screens/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/screens/splash/splash_screen.dart';

/// Authentication screen.
/// Full implementation (Firebase Auth, Google Sign-In, email/password) arrives
/// in Phase 2. This screen shows the Armonia brand and the phase status.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.darkBgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ArmoniaLogoMark(color: accent, size: 48),
              const SizedBox(height: 12),
              Text(
                'armonia',
                style: AppTypography.displayMd.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your music, understood.',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const Spacer(flex: 3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkBgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Firebase Auth, Google Sign-In, and email/password '
                      'flows arrive in Phase 2.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
