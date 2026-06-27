// lib/providers/playlist_provider.dart
//
// Phase 5A Recovery — User Playlists + Liked Songs.
//
// Contracts:
//   • UserPlaylist  — named, user-created collection. Full CRUD.
//   • Liked Songs   — special built-in list; toggling via toggleLike().
//   • Both persisted to SharedPreferences as JSON.
//   • FavoritesProvider left unchanged for backward-compat.
//
// NEVER TOUCHED: audio_provider.dart, stream_extractor.dart.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/constants/app_constants.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    this.songs = const <Song>[],
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;

  int get songCount => songs.length;

  UserPlaylist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    DateTime? createdAt,
  }) =>
      UserPlaylist(
        id: id ?? this.id,
        name: name ?? this.name,
        songs: songs ?? this.songs,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSongs =
        json['songs'] as List<dynamic>? ?? <dynamic>[];
    return UserPlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      songs: rawSongs
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class PlaylistState {
  const PlaylistState({
    this.playlists = const <UserPlaylist>[],
    this.likedSongs = const <Song>[],
  });

  final List<UserPlaylist> playlists;
  final List<Song> likedSongs;

  bool isLiked(String videoId) =>
      likedSongs.any((s) => s.videoId == videoId);

  PlaylistState copyWith({
    List<UserPlaylist>? playlists,
    List<Song>? likedSongs,
  }) =>
      PlaylistState(
        playlists: playlists ?? this.playlists,
        likedSongs: likedSongs ?? this.likedSongs,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistNotifier extends Notifier<PlaylistState> {
  late final SharedPreferences _prefs;

  @override
  PlaylistState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return PlaylistState(
      playlists: _loadPlaylists(),
      likedSongs: _loadLikedSongs(),
    );
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  String _newId() => 'pl_${DateTime.now().millisecondsSinceEpoch}';

  List<UserPlaylist> _loadPlaylists() {
    try {
      final String? raw =
          _prefs.getString(AppConstants.prefUserPlaylists);
      if (raw == null || raw.isEmpty) return const <UserPlaylist>[];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UserPlaylist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PlaylistProvider] _loadPlaylists FAILED: $e');
      return const <UserPlaylist>[];
    }
  }

  void _persistPlaylists(List<UserPlaylist> playlists) {
    try {
      _prefs.setString(
        AppConstants.prefUserPlaylists,
        jsonEncode(playlists.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[PlaylistProvider] _persistPlaylists FAILED: $e');
    }
  }

  List<Song> _loadLikedSongs() {
    try {
      final String? raw = _prefs.getString(AppConstants.prefLikedSongs);
      if (raw == null || raw.isEmpty) return const <Song>[];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PlaylistProvider] _loadLikedSongs FAILED: $e');
      return const <Song>[];
    }
  }

  void _persistLikedSongs(List<Song> songs) {
    try {
      _prefs.setString(
        AppConstants.prefLikedSongs,
        jsonEncode(songs.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[PlaylistProvider] _persistLikedSongs FAILED: $e');
    }
  }

  // ── User Playlist CRUD ───────────────────────────────────────────────────

  /// Creates a new playlist. Returns the new playlist id, or '' on error.
  String createPlaylist(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final UserPlaylist playlist = UserPlaylist(
      id: _newId(),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    final List<UserPlaylist> updated = <UserPlaylist>[
      ...state.playlists,
      playlist,
    ];
    state = state.copyWith(playlists: updated);
    _persistPlaylists(updated);
    return playlist.id;
  }

  void renamePlaylist(String id, String newName) {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final List<UserPlaylist> updated = state.playlists
        .map((p) => p.id == id ? p.copyWith(name: trimmed) : p)
        .toList();
    state = state.copyWith(playlists: updated);
    _persistPlaylists(updated);
  }

  void deletePlaylist(String id) {
    final List<UserPlaylist> updated =
        state.playlists.where((p) => p.id != id).toList();
    state = state.copyWith(playlists: updated);
    _persistPlaylists(updated);
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final List<UserPlaylist> updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      if (p.songs.any((s) => s.videoId == song.videoId)) return p;
      if (p.songs.length >= AppConstants.maxPlaylistSongs) return p;
      return p.copyWith(songs: <Song>[...p.songs, song]);
    }).toList();
    state = state.copyWith(playlists: updated);
    _persistPlaylists(updated);
  }

  void removeSongFromPlaylist(String playlistId, String videoId) {
    final List<UserPlaylist> updated = state.playlists.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(
        songs: p.songs.where((s) => s.videoId != videoId).toList(),
      );
    }).toList();
    state = state.copyWith(playlists: updated);
    _persistPlaylists(updated);
  }

  /// Returns the playlist with [id], or `null` if not found.
  UserPlaylist? playlistById(String id) {
    for (final UserPlaylist p in state.playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Liked Songs ──────────────────────────────────────────────────────────

  /// Toggles liked status. Liked songs are prepended (most-recent first).
  void toggleLike(Song song) {
    final List<Song> current = List<Song>.from(state.likedSongs);
    final bool alreadyLiked =
        current.any((s) => s.videoId == song.videoId);
    final List<Song> updated = alreadyLiked
        ? current.where((s) => s.videoId != song.videoId).toList()
        : <Song>[song, ...current];
    state = state.copyWith(likedSongs: updated);
    _persistLikedSongs(updated);
  }

  bool isLiked(String videoId) => state.isLiked(videoId);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final playlistProvider =
    NotifierProvider<PlaylistNotifier, PlaylistState>(PlaylistNotifier.new);
