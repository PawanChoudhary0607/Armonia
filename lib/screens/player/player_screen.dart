// lib/screens/player/player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/providers/audio_provider.dart';

/// Full-screen player.
///
/// Phase 2A established minimal but fully functional playback controls
/// wired to [audioProvider] — play, pause, resume, seek, and stop, with
/// live position/duration tracking. Phase 2B feeds this screen real songs
/// from search (the hardcoded test song has been removed). The bloom
/// background, breathing album art, lyrics flip, and queue sheet arrive in
/// a later phase.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final AudioState audio = ref.watch(audioProvider);
    final AudioNotifier notifier = ref.read(audioProvider.notifier);

    final bool hasSong = audio.currentSong != null;
    final Duration duration = audio.duration > Duration.zero
        ? audio.duration
        : const Duration(seconds: 1);
    final double sliderMax = duration.inMilliseconds.toDouble();
    final double sliderValue = audio.progress.inMilliseconds
        .clamp(0, sliderMax.round())
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.darkBgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.darkTextPrimary,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.darkBgSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkBorderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: (hasSong && audio.currentSong!.thumbnail.isNotEmpty)
                      ? Image.network(
                          audio.currentSong!.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            audio.isLoading
                                ? Icons.hourglass_top_rounded
                                : Icons.music_note_rounded,
                            color: accent,
                            size: 72,
                          ),
                        )
                      : Icon(
                          audio.isLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.music_note_rounded,
                          color: accent,
                          size: 72,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                hasSong ? audio.currentSong!.title : 'No song loaded',
                textAlign: TextAlign.center,
                style: AppTypography.displayMd.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSong ? audio.currentSong!.artist : 'Press play to begin',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),

              if (audio.loadError != null) ...[
                const SizedBox(height: 16),
                Text(
                  audio.loadError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Seek bar + time labels
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: accent,
                  inactiveTrackColor: AppColors.darkBgElevated,
                  thumbColor: Colors.white,
                  overlayColor: accent.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: sliderValue,
                  min: 0,
                  max: sliderMax,
                  onChanged: hasSong
                      ? (value) {
                          notifier.seekTo(
                            Duration(milliseconds: value.round()),
                          );
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.duration(audio.progress),
                      style: AppTypography.monoLg.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    Text(
                      Formatters.duration(audio.duration),
                      style: AppTypography.monoLg.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transport controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    color: hasSong
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextTertiary,
                    icon: const Icon(Icons.stop_rounded),
                    onPressed: hasSong ? () => notifier.stop() : null,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 32,
                      color: AppColors.darkTextInverted,
                      icon: audio.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.darkTextInverted,
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
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 32,
                    color: hasSong
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextTertiary,
                    icon: const Icon(Icons.replay_rounded),
                    onPressed: hasSong
                        ? () => notifier.seekTo(Duration.zero)
                        : null,
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
