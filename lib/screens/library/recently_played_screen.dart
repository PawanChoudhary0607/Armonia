// lib/screens/library/recently_played_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/providers/queue_provider.dart';
import 'package:armonia/providers/recently_played_provider.dart';
import 'package:armonia/widgets/layout/mini_player.dart';
import 'package:armonia/widgets/song/song_tile.dart';

/// Full Recently Played list — opened from the Home quick-access grid.
///
/// Reads [recentlyPlayedProvider] directly (untouched). Tapping a song sets
/// the playback queue to this list starting at the tapped position via
/// [queueProvider], then opens the full Player screen.
class RecentlyPlayedScreen extends ConsumerWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecentlyPlayedState recent = ref.watch(recentlyPlayedProvider);
    final QueueNotifier queueNotifier = ref.read(queueProvider.notifier);
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        backgroundColor: context.appColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: context.appColors.textPrimary,
        ),
        title: Text(
          'Recently Played',
          style: AppTypography.titleLg.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: recent.songs.isEmpty
          ? _EmptyState(accent: accent)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: recent.songs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final song = recent.songs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    queueNotifier.playFromList(recent.songs, index);
                    context.push(AppRoutes.player);
                  },
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.appColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.borderSubtle),
              ),
              child: Icon(Icons.history_rounded, color: accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing played yet',
              style: AppTypography.titleLg.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Songs you play will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
