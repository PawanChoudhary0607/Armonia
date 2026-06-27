// lib/services/audio_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges the app's single [AudioPlayer] instance (owned by
/// `AudioNotifier`) to the operating system via `audio_service`.
///
/// This handler does not own playback decisions — it mirrors the state of
/// the existing `just_audio` player into [playbackState] / [mediaItem] so
/// that the lock screen and the media notification stay in sync, and it
/// forwards OS-originated commands (notification / lock screen taps) back
/// into the player.
///
/// Stream extraction, source selection, and all playback business logic
/// remain entirely inside `AudioNotifier` / `StreamExtractor` and are not
/// touched by this class.
class ArmoniaAudioHandler extends BaseAudioHandler with SeekHandler {
  ArmoniaAudioHandler(this._player) {
    _listenToPlayer();
  }

  final AudioPlayer _player;

  /// Set by [AudioNotifier] so that notification/lock-screen "next" and
  /// "previous" taps can be routed back into the app. These are
  /// placeholders until the queue system (a later phase) exists.
  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;

  void _listenToPlayer() {
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    }, onError: (Object e, StackTrace st) {
      // Stream extraction / playback errors are already surfaced through
      // AudioNotifier's own error handling; avoid crashing the handler.
    });

    _player.playingStream.listen((_) => _broadcastState());
  }

  /// Pushes the current [just_audio] player state into [playbackState] so
  /// the OS notification and lock screen reflect play/pause/buffering and
  /// the current position.
  void _broadcastState() {
    final bool playing = _player.playing;

    final List<MediaControl> controls = [
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Called by [AudioNotifier] whenever a new song begins loading. Updates
  /// the notification/lock-screen artwork, title, and artist immediately
  /// (before playback actually starts), so the OS surfaces never lag
  /// behind the UI.
  void setCurrentMediaItem({
    required String id,
    required String title,
    required String artist,
    required Duration duration,
    String? artUri,
  }) {
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        duration: duration > Duration.zero ? duration : null,
        artUri: (artUri != null && artUri.isNotEmpty) ? Uri.parse(artUri) : null,
      ),
    );
  }

  /// Indicates to the OS that media is buffering, which on Android keeps
  /// the foreground service alive during the (async) stream-resolution
  /// step performed by `StreamExtractor`.
  void setBufferingState() {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
        playing: false,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Commands originating from the OS (notification / lock screen)
  // ---------------------------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }
}
