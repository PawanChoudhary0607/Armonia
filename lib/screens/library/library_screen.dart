// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

/// Library screen.
/// Full implementation (Firestore playlists, Liked Songs, Downloads)
/// arrives in Phase 4.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

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
                      'Library',
                      style: AppTypography.displaySm.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {},
                    color: AppColors.darkTextSecondary,
                    tooltip: 'Create playlist',
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
                          Icons.library_music_outlined,
                          color: accent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Library',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Firestore playlists, Liked Songs, and Downloads '
                        'arrive in Phase 4.',
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
