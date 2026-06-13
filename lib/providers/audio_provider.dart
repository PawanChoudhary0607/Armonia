// lib/providers/audio_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/services/stream_extractor.dart';

/// Immutable playback state exposed to the UI.
@immutable
class AudioState {
  const AudioState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.progress = Duration.zero,
    this.duration = Duration.zero,
    this.loadError,
  });

  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration progress;
  final Duration duration;
  final String? loadError;

  AudioState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? progress,
    Duration? duration,
    String? loadError,
    bool clearError = false,
  }) {
    return AudioState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      loadError: clearError ? null : (loadError ?? this.loadError),
    );
  }
}

/// Provides the singleton [StreamExtractor] used to resolve playable audio
/// URLs from YouTube video IDs.
final streamExtractorProvider = Provider<StreamExtractor>((ref) {
  return const StreamExtractor();
});

/// Manages the core audio playback lifecycle for Armonia using `just_audio`.
///
/// This Phase 2A implementation focuses purely on reliable single-track
/// playback: play, pause, resume, seek, stop, and live position/duration
/// tracking. Background playback (`audio_service`), the queue, crossfade,
/// downloads, and stats reporting are intentionally out of scope and arrive
/// in later phases.
class AudioNotifier extends Notifier<AudioState> {
  late final AudioPlayer _player;
  late final StreamExtractor _extractor;

  /// Guards against a stale async `playSong` call overwriting state from a
  /// newer one (e.g. user taps a second song before the first finishes
  /// resolving its stream URL).
  int _loadGeneration = 0;

  @override
  AudioState build() {
    _player = AudioPlayer();
    _extractor = ref.read(streamExtractorProvider);

    final positionSub = _player.positionStream.listen((position) {
      state = state.copyWith(progress: position);
    });

    final durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    final playerStateSub = _player.playerStateStream.listen((playerState) {
      debugPrint(
        '[AudioProvider] playerStateStream: '
        'playing=${playerState.playing}, '
        'processingState=${playerState.processingState}',
      );

      final bool isPlaying = playerState.playing;
      final ProcessingState processing = playerState.processingState;

      switch (processing) {
        case ProcessingState.idle:
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          state = state.copyWith(isLoading: true, isPlaying: isPlaying);
          break;
        case ProcessingState.ready:
          state = state.copyWith(isLoading: false, isPlaying: isPlaying);
          break;
        case ProcessingState.completed:
          state = state.copyWith(
            isPlaying: false,
            progress: state.duration,
          );
          break;
      }
    });

    final processingStateSub = _player.processingStateStream.listen((
      processingState,
    ) {
      debugPrint(
        '[AudioProvider] processingStateStream: $processingState',
      );
    });

    ref.onDispose(() {
      positionSub.cancel();
      durationSub.cancel();
      playerStateSub.cancel();
      processingStateSub.cancel();
      _player.dispose();
    });

    return const AudioState();
  }

  /// Loads and plays [song].
  ///
  /// Validates the YouTube video ID, resolves a direct CDN audio stream URL
  /// via [StreamExtractor], and begins playback. If a newer call to
  /// [playSong] is made before this one completes, this call's result is
  /// discarded (stale-load guard).
  Future<void> playSong(Song song) async {
    if (song.videoId.length != 11) {
      state = state.copyWith(
        loadError: 'Invalid video ID: "${song.videoId}" (must be 11 characters).',
      );
      return;
    }

    final int generation = ++_loadGeneration;

    debugPrint('[AudioProvider] playSong started (videoId=${song.videoId})');

    // Immediately stop whatever is currently playing/buffering so a
    // previously-loading song cannot start audio after this newer
    // selection, and so no overlap occurs even momentarily.
    try {
      await _player.stop();
      debugPrint('[AudioProvider] stopped previous playback before loading new song');
    } catch (e) {
      debugPrint('[AudioProvider] stop before load FAILED (ignored): $e');
    }

    // Another playSong() was triggered while we were stopping — let that
    // newer call own playback; abandon this one.
    if (generation != _loadGeneration) {
      debugPrint('[AudioProvider] stale generation after pre-stop — aborting');
      return;
    }

    state = state.copyWith(
      currentSong: song,
      isLoading: true,
      isPlaying: false,
      progress: Duration.zero,
      duration: song.duration,
      clearError: true,
    );

    try {
      final String url = await _extractor.getAudioStreamUrl(song.videoId);

      // A newer playSong() call superseded this one — discard our result.
      if (generation != _loadGeneration) {
        debugPrint('[AudioProvider] stale generation after extraction — aborting');
        return;
      }

      debugPrint('[AudioProvider] setUrl started: $url');
      try {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'com.google.android.apps.youtube.music/6.42.52 (Linux; U; Android 11) gzip',
            },
          ),
        );
        debugPrint('[AudioProvider] setUrl success');
      } catch (e, st) {
        debugPrint('[AudioProvider] setUrl FAILED: $e');
        debugPrint('[AudioProvider] setUrl STACK TRACE: $st');
        rethrow;
      }

      // A newer playSong() call superseded this one while setAudioSource
      // was resolving — stop the source we just loaded so it cannot start
      // playing, and let the newer call's source remain in control.
      if (generation != _loadGeneration) {
        debugPrint('[AudioProvider] stale generation after setUrl — aborting');
        try {
          await _player.stop();
        } catch (_) {}
        return;
      }

      debugPrint('[AudioProvider] play started');
      try {
        await _player.play();
        debugPrint('[AudioProvider] play success');
      } catch (e, st) {
        debugPrint('[AudioProvider] play FAILED: $e');
        debugPrint('[AudioProvider] play STACK TRACE: $st');
        rethrow;
      }

      // Final check: if a newer selection arrived just as playback started,
      // stop immediately so two tracks never sound simultaneously.
      if (generation != _loadGeneration) {
        debugPrint('[AudioProvider] stale generation after play — stopping');
        try {
          await _player.stop();
        } catch (_) {}
        return;
      }
    } catch (e, stackTrace) {
      debugPrint('[AudioProvider] FULL ERROR: $e');
      debugPrint('[AudioProvider] STACK TRACE: $stackTrace');

      if (generation != _loadGeneration) return;

      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        loadError: 'Could not play "${song.title}": $e',
      );
    }
  }

  /// Pauses playback. Position is preserved for [resume].
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resumes playback from the current position.
  Future<void> resume() async {
    await _player.play();
  }

  /// Seeks to [position] within the current track.
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  /// Stops playback entirely and resets position/loaded state.
  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(
      isPlaying: false,
      isLoading: false,
      progress: Duration.zero,
    );
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioState>(
  AudioNotifier.new,
);
