// lib/screens/home/home_screen.dart
//
// Phase 5B — Removed curated playlists entirely.
// Home now shows: Recently Played, Liked Songs (count card), User Playlists.
// No AI-generated or fake playlist data.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/queue_provider.dart';
import 'package:armonia/providers/recently_played_provider.dart';
import 'package:armonia/widgets/song/song_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final RecentlyPlayedState recent = ref.watch(recentlyPlayedProvider);
    final PlaylistState ps = ref.watch(playlistProvider);
    final QueueNotifier queueNotifier = ref.read(queueProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── HEADER ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.profile),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: context.appColors.bgElevated,
                        child: Icon(
                          Icons.person_rounded,
                          color: accent,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.currentGreeting(),
                            style: AppTypography.bodySm.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Armonia',
                            style: AppTypography.displaySm.copyWith(
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── LIKED SONGS CARD ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _LikedSongsCard(
                  count: ps.likedSongs.length,
                  accent: accent,
                  onTap: () => context.push(AppRoutes.likedSongs),
                ),
              ),
            ),

            // ── USER PLAYLISTS ────────────────────────────────────────────
            if (ps.playlists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your Playlists',
                          style: AppTypography.titleLg.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.library),
                        child: Text(
                          'See all',
                          style: AppTypography.bodySm.copyWith(
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  // 112px: icon(36) + gap(8) + title text(~18) +
                  // caption text(~14) + vertical padding(12+12) + 2 safety.
                  // Previously 96px caused an 11px overflow on small devices
                  // when font scaling pushed the two Text rows beyond 60px.
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ps.playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final pl = ps.playlists[index];
                      return _PlaylistChip(
                        name: pl.name,
                        count: pl.songCount,
                        accent: accent,
                        onTap: () => context.push(
                            AppRoutes.userPlaylistPath(pl.id)),
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── RECENTLY PLAYED ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Text(
                  'Recently Played',
                  style: AppTypography.titleLg.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ),

            if (recent.songs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.appColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: accent,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Songs you play will show up here.',
                            style: AppTypography.bodyMd.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList.separated(
                  itemCount: recent.songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final song = recent.songs[index];
                    return SongTile(
                      song: song,
                      onTap: () {
                        debugPrint(
                          '[HomeScreen][RecentlyPlayed] tap → playFromList('
                          'title="${song.title}", '
                          'artist="${song.artist}", '
                          'videoId="${song.videoId}", '
                          'index=$index)',
                        );
                        queueNotifier.playFromList(recent.songs, index);
                        context.push(AppRoutes.player);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIKED SONGS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LikedSongsCard extends StatelessWidget {
  const _LikedSongsCard({
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.premiumCardGradientFor(
                context, AppColors.liked),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.liked.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppColors.liked, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liked Songs',
                      style: AppTypography.titleMd.copyWith(
                          color: context.appColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 1 ? '1 song' : '$count songs',
                      style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST CHIP (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistChip extends StatelessWidget {
  const _PlaylistChip({
    required this.name,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final String name;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        // No explicit height — the SizedBox parent (112px) constrains
        // the ListView row. The chip stretches to fill that height via
        // the ListView's cross-axis stretch, so the Column can use
        // mainAxisAlignment.spaceBetween without overflow risk.
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // spaceBetween distributes the fixed parent height evenly
          // between icon, name, and count — no child can push the
          // column taller than its parent.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.queue_music_rounded, color: accent, size: 18),
            ),
            // Text rows in a Column with spaceBetween: they receive
            // whatever vertical space remains after the icon. Both use
            // maxLines:1 + ellipsis so they never wrap.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm.copyWith(
                      color: context.appColors.textPrimary),
                ),
                Text(
                  count == 1 ? '1 song' : '$count songs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption
                      .copyWith(color: context.appColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
