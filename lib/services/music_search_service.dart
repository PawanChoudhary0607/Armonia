// lib/services/music_search_service.dart

import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:armonia/data/models/song.dart';

/// Thrown when [MusicSearchService] cannot complete a search query.
class MusicSearchException implements Exception {
  const MusicSearchException(this.message);

  final String message;

  @override
  String toString() => 'MusicSearchException: $message';
}

/// Searches YouTube for tracks using `youtube_explode_dart` (PINNED at
/// 2.5.3 — never upgrade to v3, which requires a `deno` runtime unavailable
/// on Android) and converts the results into [Song] objects.
///
/// This runs entirely on-device with no backend server, reusing the same
/// `youtube_explode_dart` dependency already used by [StreamExtractor].
class MusicSearchService {
  const MusicSearchService();

  /// Returns up to [limit] [Song] results for [query].
  ///
  /// Throws [MusicSearchException] if the search fails or [query] is blank.
  Future<List<Song>> search(String query, {int limit = 25}) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <Song>[];
    }

    final YoutubeExplode yt = YoutubeExplode();

    try {
      debugPrint('[MusicSearchService] search started (query="$trimmed")');

      final VideoSearchList results = await yt.search.search(trimmed);

      debugPrint('[MusicSearchService] search returned ${results.length} results');

      final List<Song> songs = results
          .take(limit)
          .map(_videoToSong)
          .where((song) => song.videoId.length == 11)
          .toList();

      debugPrint('[MusicSearchService] mapped ${songs.length} songs');

      return songs;
    } catch (e, stackTrace) {
      debugPrint('[MusicSearchService] FULL ERROR: $e');
      debugPrint('[MusicSearchService] STACK TRACE: $stackTrace');
      throw MusicSearchException('Search failed: $e');
    } finally {
      yt.close();
    }
  }

  Song _videoToSong(Video video) {
    final String thumbnail = video.thumbnails.standardResUrl;

    return Song(
      videoId: video.id.value,
      title: video.title,
      artist: video.author,
      album: '',
      thumbnail: thumbnail,
      duration: video.duration ?? Duration.zero,
    );
  }
}
