// lib/providers/recently_played_provider.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/constants/app_constants.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/settings_provider.dart';

/// Immutable state for the recently-played list.
///
/// [songs] is ordered most-recent-first, capped at 20 entries. No
/// duplicates: if a song that is already in the list is played again it is
/// moved to position 0 rather than appended as a second entry.
@immutable
class RecentlyPlayedState {
  const RecentlyPlayedState({this.songs = const []});

  final List<Song> songs;

  RecentlyPlayedState copyWith({List<Song>? songs}) =>
      RecentlyPlayedState(songs: songs ?? this.songs);
}

/// Maintains a persisted, duplicate-free, most-recent-first list of the
/// last 20 songs played.
///
/// [add] is called by [AudioNotifier.playSong] on successful playback start.
/// The full list is serialized as JSON to [AppConstants.prefRecentlyPlayed]
/// in [SharedPreferences].
class RecentlyPlayedNotifier extends Notifier<RecentlyPlayedState> {
  late final SharedPreferences _prefs;

  static const int _maxItems = 20;

  @override
  RecentlyPlayedState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return _load();
  }

  RecentlyPlayedState _load() {
    try {
      final String? raw =
          _prefs.getString(AppConstants.prefRecentlyPlayed);
      if (raw == null || raw.isEmpty) return const RecentlyPlayedState();

      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      final List<Song> songs = jsonList
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();

      return RecentlyPlayedState(songs: songs);
    } catch (e) {
      debugPrint(
          '[RecentlyPlayedProvider] load FAILED (returning empty): $e');
      return const RecentlyPlayedState();
    }
  }

  /// Prepends [song] to the list.
  ///
  /// If the song already exists anywhere in the list, the existing entry is
  /// removed first so there are never duplicates. The list is then trimmed
  /// to [_maxItems].
  void add(Song song) {
    final List<Song> updated = [
      song,
      ...state.songs.where((s) => s.videoId != song.videoId),
    ];

    final List<Song> trimmed =
        updated.length > _maxItems ? updated.sublist(0, _maxItems) : updated;

    state = state.copyWith(songs: trimmed);
    _persist(trimmed);
  }

  void _persist(List<Song> songs) {
    try {
      final String encoded =
          jsonEncode(songs.map((s) => s.toJson()).toList());
      _prefs.setString(AppConstants.prefRecentlyPlayed, encoded);
    } catch (e) {
      debugPrint(
          '[RecentlyPlayedProvider] persist FAILED (ignored): $e');
    }
  }
}

final recentlyPlayedProvider =
    NotifierProvider<RecentlyPlayedNotifier, RecentlyPlayedState>(
  RecentlyPlayedNotifier.new,
);
