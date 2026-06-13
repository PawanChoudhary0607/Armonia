// lib/screens/analytics/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

/// Analytics screen.
/// Full implementation (heatmap, bar chart, top song/artist, streak stats)
/// arrives in Phase 8.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

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
              child: Text(
                'Your Stats',
                style: AppTypography.displaySm.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
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
                          Icons.bar_chart_rounded,
                          color: accent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analytics',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Listening heatmap, bar chart, top song/artist, '
                        'and streak data arrive in Phase 8.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.darkTextSecondary,
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
