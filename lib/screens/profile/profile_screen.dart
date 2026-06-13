// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

/// Profile screen.
/// Full implementation (avatar, quick stats, badges, streak card) arrives
/// in Phase 9. Settings navigation is wired now.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: AppTypography.displaySm.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(AppRoutes.settings),
                    color: AppColors.darkTextSecondary,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.darkBgSurface,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.darkBorderSubtle),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: accent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Profile',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Avatar, listening stats, streak card, and badges '
                        'arrive in Phase 9.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.settings),
                          icon: const Icon(Icons.settings_outlined,
                              size: 18),
                          label: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
