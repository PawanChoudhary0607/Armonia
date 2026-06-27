// lib/widgets/layout/mini_player.dart
//
// Phase 5B Stability Patch:
//   • Removed import of favorites_provider.dart.
//     Heart now reads playlistProvider directly (same source of truth as
//     player_screen.dart and search_screen.dart).
//   • Added Next button wired to queueProvider.notifier.next(), disabled
//     when QueueState.hasNext is false.
//   • Swipe left → next; swipe right → previous (gesture on whole bar).
//   • Tooltip text updated: "Add to Liked Songs" / "Remove from Liked Songs".
//
// PROTECTED FILES UNTOUCHED: audio_provider.dart, stream_extractor.dart,
// audio_handler.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/audio_provider.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/queue_provider.dart';

/// Persistent mini player bar shown above the bottom navigation.
///
/// Renders nothing when [AudioState.currentSong] is null. Safe to place in
/// every screen's layout — it produces a zero-height widget until a song loads.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioState audio = ref.watch(audioProvider);
    final Song? song = audio.currentSong;

    if (song == null) return const SizedBox.shrink();

    final Color accent = Theme.of(context).colorScheme.primary;
    final AudioNotifier audioNotifier = ref.read(audioProvider.notifier);

    // ── Liked Songs — read directly from playlistProvider (single source) ──
    final bool isLiked =
        ref.watch(playlistProvider.select((s) => s.isLiked(song.videoId)));

    // ── Queue — for Next button ───────────────────────────────────────────
    final bool hasNext =
        ref.watch(queueProvider.select((q) => q.hasNext));
    final QueueNotifier queueNotifier = ref.read(queueProvider.notifier);

    final double progress = audio.duration.inMilliseconds > 0
        ? (audio.progress.inMilliseconds / audio.duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tap on bar body → expand to full player.
        onTap: () => context.push(AppRoutes.player),
        // Swipe left → next; swipe right → previous.
        onHorizontalDragEnd: (DragEndDetails details) {
          final double velocity = details.primaryVelocity ?? 0;
          if (velocity < -300) {
            queueNotifier.next();
          } else if (velocity > 300) {
            queueNotifier.previous();
          }
        },
        child: Container(
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appColors.glassHeavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: Stack(
            children: [
              // Playback progress bar along the bottom edge.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        accent.withValues(alpha: 0.9)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // ── Artwork ──────────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: context.appColors.bgElevated,
                        child: song.thumbnail.isNotEmpty
                            ? Image.network(
                                song.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.music_note_rounded,
                                    color: accent,
                                    size: 20),
                              )
                            : Icon(Icons.music_note_rounded,
                                color: accent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Title + Artist ────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                                color: context.appColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // ── Like button ───────────────────────────────────────
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded),
                      color: isLiked ? accent : context.appColors.textSecondary,
                      tooltip: isLiked
                          ? 'Remove from Liked Songs'
                          : 'Add to Liked Songs',
                      onPressed: () => ref
                          .read(playlistProvider.notifier)
                          .toggleLike(song),
                    ),

                    // ── Play / Pause ──────────────────────────────────────
                    IconButton(
                      iconSize: 26,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: audio.isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: context.appColors.textPrimary,
                              ),
                            )
                          : Icon(audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      color: context.appColors.textPrimary,
                      tooltip: audio.isPlaying ? 'Pause' : 'Play',
                      onPressed: audio.isLoading
                          ? null
                          : () {
                              if (audio.isPlaying) {
                                audioNotifier.pause();
                              } else {
                                audioNotifier.resume();
                              }
                            },
                    ),

                    // ── Next ─────────────────────────────────────────────
                    IconButton(
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.skip_next_rounded),
                      color: hasNext
                          ? context.appColors.textPrimary
                          : context.appColors.textTertiary,
                      tooltip: 'Next',
                      onPressed: hasNext ? () => queueNotifier.next() : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
