// lib/screens/player/player_screen.dart
//
// Phase 5B — Heart button now toggles playlistProvider.toggleLike()
// (Liked Songs) instead of favoritesProvider. favoritesProvider references
// are removed from this file. audio_provider.dart is NOT touched.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/audio_provider.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/queue_provider.dart';
import 'package:armonia/widgets/player/player_sheets.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final AudioState audio = ref.watch(audioProvider);
    final AudioNotifier notifier = ref.read(audioProvider.notifier);

    // Phase 5B: use playlistProvider for liked state
    final PlaylistState ps = ref.watch(playlistProvider);
    final PlaylistNotifier playlistNotifier =
        ref.read(playlistProvider.notifier);

    final QueueState queue = ref.watch(queueProvider);
    final QueueNotifier queueNotifier = ref.read(queueProvider.notifier);

    final Song? song = audio.currentSong;
    final bool hasSong = song != null;
    final Duration duration = audio.duration > Duration.zero
        ? audio.duration
        : const Duration(seconds: 1);
    final double sliderMax = duration.inMilliseconds.toDouble();
    final double sliderValue = audio.progress.inMilliseconds
        .clamp(0, sliderMax.round())
        .toDouble();

    final bool isLiked = hasSong && ps.isLiked(song!.videoId);

    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          color: context.appColors.textPrimary,
        ),
        title: Text(
          'NOW PLAYING',
          style: AppTypography.label.copyWith(
            color: context.appColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _PlayerBackground(song: song, accent: accent),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  const Spacer(),

                  // ── ALBUM ART ────────────────────────────────────────
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: context.appColors.bgSurface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: (hasSong && song!.thumbnail.isNotEmpty)
                          ? Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _ArtFallback(
                                accent: accent,
                                isLoading: audio.isLoading,
                              ),
                            )
                          : _ArtFallback(
                              accent: accent,
                              isLoading: audio.isLoading,
                            ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── SONG INFO ────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasSong ? song!.title : 'No song loaded',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displayMd.copyWith(
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasSong
                                  ? song!.artist
                                  : 'Search to start playing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyLg.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (hasSong)
                        IconButton(
                          iconSize: 28,
                          icon: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          color: isLiked
                              ? AppColors.liked
                              : context.appColors.textSecondary,
                          tooltip: isLiked
                              ? 'Remove from Liked Songs'
                              : 'Add to Liked Songs',
                          onPressed: () =>
                              playlistNotifier.toggleLike(song!),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),

                  if (audio.loadError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      audio.loadError!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── SEEK BAR ─────────────────────────────────────────
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: accent,
                      inactiveTrackColor: context.appColors.glassHeavy,
                      thumbColor: Colors.white,
                      overlayColor: accent.withValues(alpha: 0.2),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: 0,
                      max: sliderMax,
                      onChanged: hasSong
                          ? (value) {
                              notifier.seekTo(
                                  Duration(milliseconds: value.round()));
                            }
                          : null,
                    ),
                  ),

                  // ── TIME LABELS ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.duration(audio.progress),
                          style: AppTypography.monoSm.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.duration(
                              audio.duration > Duration.zero
                                  ? audio.duration
                                  : Duration.zero),
                          style: AppTypography.monoSm.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── CONTROLS ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        iconSize: 32,
                        color: queue.hasPrevious
                            ? context.appColors.textPrimary
                            : context.appColors.textTertiary,
                        icon: const Icon(Icons.skip_previous_rounded),
                        tooltip: 'Previous',
                        onPressed: queue.hasPrevious
                            ? () => queueNotifier.previous()
                            : null,
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 34,
                          color: context.appColors.textInverted,
                          icon: audio.isLoading
                              ? SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.appColors.textInverted,
                                  ),
                                )
                              : Icon(
                                  audio.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                          onPressed: (audio.isLoading || !hasSong)
                              ? null
                              : () {
                                  if (audio.isPlaying) {
                                    notifier.pause();
                                  } else {
                                    notifier.resume();
                                  }
                                },
                        ),
                      ),
                      IconButton(
                        iconSize: 32,
                        color: queue.hasNext
                            ? context.appColors.textPrimary
                            : context.appColors.textTertiary,
                        icon: const Icon(Icons.skip_next_rounded),
                        tooltip: 'Next',
                        onPressed:
                            queue.hasNext ? () => queueNotifier.next() : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── LYRICS / QUEUE ENTRY POINTS ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          icon: Icons.lyrics_outlined,
                          label: 'Lyrics',
                          onTap: () => showLyricsComingSoonSheet(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryButton(
                          icon: Icons.queue_music_rounded,
                          label: 'Queue',
                          onTap: () => showQueueSheet(context, queue),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBackground extends StatelessWidget {
  const _PlayerBackground({required this.song, required this.accent});

  final Song? song;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.playerBackgroundGradientFor(context, accent),
          ),
        ),
        if (song != null && song!.thumbnail.isNotEmpty)
          Opacity(
            opacity: 0.30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Image.network(
                song!.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.20),
                context.appColors.bgBase.withValues(alpha: 0.85),
                context.appColors.bgBase,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.accent, required this.isLoading});

  final Color accent;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.bgSurface,
      child: Center(
        child: Icon(
          isLoading ? Icons.hourglass_top_rounded : Icons.music_note_rounded,
          color: accent,
          size: 84,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.glassHeavy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: context.appColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.titleSm.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
