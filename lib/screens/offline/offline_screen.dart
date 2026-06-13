// lib/screens/offline/offline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

/// Offline screen.
/// Shown automatically when the device has no internet connection.
/// ConnectivityPlus wiring into AppScaffold arrives in Phase 5.
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBgBase,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkBorderSubtle),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No connection',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection\nand try again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text(
                      'Retry',
                      style: AppTypography.titleSm.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
