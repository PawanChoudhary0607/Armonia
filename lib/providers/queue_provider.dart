// lib/providers/queue_provider.dart
//
// Bug 5 fix — Queue index stays stale after natural end-of-track:
//
//   Root cause: audio_provider.dart (PROTECTED) handles
//   ProcessingState.completed by setting isPlaying:false but never
//   advances the queue. queueProvider had no listener on audioProvider
//   state, so natural song completion left currentIndex frozen and the
//   next song never played.
//
//   Fix (no changes to protected files):
//     QueueNotifier.build() now sets up a ref.listen on audioProvider.
//     When it observes the transition:
//       previous.isLoading == false && previous.isPlaying == true
//       next.isPlaying    == false && next.isLoading  == false
//       next.currentSong == previous.currentSong  (same song, not a
//                                                  manual skip)
//     AND state.hasNext is true — it calls next() to advance the queue.
//
//     The guard "next.currentSong == previous.currentSong" prevents a
//     false trigger when the user manually taps a different song (which
//     also transitions isPlaying true→false briefly during loading).
//     When a manual playSong call fires, audioProvider sets currentSong
//     to the NEW song before emitting isPlaying:false — so the guard
//     fires only for natural completion where the song field doesn't
//     change during the pause.
//
// PROTECTED FILES UNTOUCHED: audio_provider.dart, stream_extractor.dart,
// audio_handler.dart.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/audio_provider.dart';

/// Immutable state for the playback queue.
@immutable
class QueueState {
  const QueueState({
    this.songs = const <Song>[],
    this.currentIndex = -1,
  });

  final List<Song> songs;
  final int currentIndex;

  bool get isEmpty => songs.isEmpty;

  Song? get currentSong {
    if (currentIndex < 0 || currentIndex >= songs.length) return null;
    return songs[currentIndex];
  }

  bool get hasPrevious => songs.isNotEmpty && currentIndex > 0;

  bool get hasNext =>
      songs.isNotEmpty &&
      currentIndex >= 0 &&
      currentIndex < songs.length - 1;

  List<Song> get upcoming {
    if (currentIndex < 0 || currentIndex + 1 >= songs.length) {
      return const <Song>[];
    }
    return songs.sublist(currentIndex + 1);
  }

  QueueState copyWith({List<Song>? songs, int? currentIndex}) {
    return QueueState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class QueueNotifier extends Notifier<QueueState> {
  @override
  QueueState build() {
    // ── Natural end-of-track auto-advance ──────────────────────────────
    //
    // audio_provider.dart is protected and does not call next() when a
    // song completes naturally (ProcessingState.completed sets isPlaying
    // false but does not touch queueProvider). We detect the completion
    // here by watching audioProvider state transitions.
    //
    // Trigger condition (all must be true):
    //   1. Previous state: isPlaying=true, isLoading=false
    //   2. Next state:     isPlaying=false, isLoading=false
    //   3. currentSong is unchanged (same videoId) — this distinguishes
    //      natural completion from a manual song change, which also
    //      briefly transitions to isPlaying=false but simultaneously
    //      changes currentSong.
    //   4. state.hasNext — there is a next song in the queue.
    //
    // When all four conditions hold, we advance to the next song.
    ref.listen<AudioState>(
      audioProvider,
      (AudioState? previous, AudioState next) {
        if (previous == null) return;

        final bool wasPlaying =
            previous.isPlaying && !previous.isLoading;
        final bool isNowStopped =
            !next.isPlaying && !next.isLoading;

        // Guard: currentSong must be the same object (same videoId).
        // A manual song change updates currentSong BEFORE emitting
        // isPlaying:false, so the videoIds will differ.
        final bool sameSong =
            previous.currentSong?.videoId != null &&
            previous.currentSong?.videoId ==
                next.currentSong?.videoId;

        // Guard: next song must have had a positive duration — a song
        // that failed to load will have duration == zero.
        final bool hadDuration = next.duration > Duration.zero;

        // Guard: progress must be at or very near the end. "Very near"
        // is within 2 seconds to account for buffering rounding.
        final bool atEnd = hadDuration &&
            (next.duration - next.progress).inMilliseconds.abs() <
                2000;

        if (wasPlaying && isNowStopped && sameSong && atEnd) {
          debugPrint(
            '[QueueNotifier] natural completion detected — '
            'advancing queue (currentIndex=${state.currentIndex}, '
            'hasNext=${state.hasNext})',
          );
          if (state.hasNext) {
            // Use Future.microtask so we don't mutate state inside a
            // listener callback, which Riverpod forbids during the same
            // frame.
            Future.microtask(next_);
          }
        }
      },
    );

    return const QueueState();
  }

  // ── Internal advance used by the auto-advance listener ───────────────

  Future<void> next_() async {
    if (!state.hasNext) return;
    final int newIndex = state.currentIndex + 1;
    state = state.copyWith(currentIndex: newIndex);
    await ref
        .read(audioProvider.notifier)
        .playSong(state.songs[newIndex]);
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Replaces the entire queue with [songs] and starts playback at
  /// [startIndex].
  void playFromList(List<Song> songs, int startIndex) {
    if (songs.isEmpty ||
        startIndex < 0 ||
        startIndex >= songs.length) return;
    state = QueueState(
      songs: List<Song>.unmodifiable(songs),
      currentIndex: startIndex,
    );
    ref.read(audioProvider.notifier).playSong(songs[startIndex]);
  }

  /// Plays [song] as a single-item queue.
  void playSingle(Song song) {
    state = QueueState(songs: <Song>[song], currentIndex: 0);
    ref.read(audioProvider.notifier).playSong(song);
  }

  /// Advances to the next song in the queue. No-op when [hasNext] is
  /// false.
  Future<void> next() async {
    if (!state.hasNext) return;
    await next_();
  }

  /// Goes back to the previous song. No-op when [hasPrevious] is false.
  Future<void> previous() async {
    if (!state.hasPrevious) return;
    final int newIndex = state.currentIndex - 1;
    state = state.copyWith(currentIndex: newIndex);
    await ref
        .read(audioProvider.notifier)
        .playSong(state.songs[newIndex]);
  }

  /// Appends [song] to the end of the queue without changing
  /// [currentIndex] or interrupting playback.
  /// If the queue is empty, starts playback immediately.
  void addToQueue(Song song) {
    final List<Song> current = List<Song>.from(state.songs);
    current.add(song);
    if (state.isEmpty) {
      state = QueueState(
        songs: List<Song>.unmodifiable(current),
        currentIndex: 0,
      );
      ref.read(audioProvider.notifier).playSong(song);
    } else {
      state = state.copyWith(songs: List<Song>.unmodifiable(current));
    }
  }

  /// Removes the song at absolute index [index] from the queue.
  ///
  /// Rules:
  ///   • Removing the currently playing song starts the next one (or
  ///     stops if there is no next).
  ///   • Removing a song before [currentIndex] decrements the index so
  ///     the current song is unchanged.
  ///   • Removing a song after [currentIndex] has no effect on the
  ///     current song.
  void removeAt(int index) {
    final List<Song> current = List<Song>.from(state.songs);
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);

    if (current.isEmpty) {
      state = const QueueState();
      return;
    }

    int newIndex = state.currentIndex;
    if (index < newIndex) {
      newIndex -= 1;
    } else if (index == newIndex) {
      if (newIndex >= current.length) {
        newIndex = current.length - 1;
      }
      state = QueueState(
        songs: List<Song>.unmodifiable(current),
        currentIndex: newIndex,
      );
      ref
          .read(audioProvider.notifier)
          .playSong(current[newIndex]);
      return;
    }

    state = QueueState(
      songs: List<Song>.unmodifiable(current),
      currentIndex: newIndex,
    );
  }

  /// Reorders the queue by moving a song from [oldIndex] to [newIndex]
  /// (same semantics as [ReorderableListView]: indices are pre-removal).
  void reorder(int oldIndex, int newIndex) {
    final List<Song> current = List<Song>.from(state.songs);
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final Song moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);

    int newCurrentIndex = state.currentIndex;
    final Song? playing = state.currentSong;
    if (playing != null) {
      newCurrentIndex =
          current.indexWhere((s) => s.videoId == playing.videoId);
      if (newCurrentIndex == -1) newCurrentIndex = state.currentIndex;
    }

    state = QueueState(
      songs: List<Song>.unmodifiable(current),
      currentIndex: newCurrentIndex,
    );
  }

  /// Clears the queue entirely. Does not stop current playback.
  void clear() => state = const QueueState();
}

final queueProvider =
    NotifierProvider<QueueNotifier, QueueState>(QueueNotifier.new);
