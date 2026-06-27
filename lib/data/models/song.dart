// lib/data/models/song.dart

import 'package:flutter/foundation.dart';

/// Core song model used across the playback engine, search, library, and
/// downloads. [videoId] is always the 11-character YouTube video ID.
@immutable
class Song {
  const Song({
    required this.videoId,
    required this.title,
    required this.artist,
    this.album = '',
    this.thumbnail = '',
    this.duration = Duration.zero,
  });

  final String videoId;
  final String title;
  final String artist;
  final String album;
  final String thumbnail;
  final Duration duration;

  /// Builds a [Song] from a YouTube Music InnerTube-style JSON map.
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      duration: Duration(seconds: (json['durationSeconds'] as num?)?.toInt() ?? 0),
    );
  }

  /// Builds a [Song] from a SQLite row map (e.g. `history` or
  /// `downloaded_tracks` tables), where duration is stored as an int
  /// number of seconds.
  factory Song.fromSqlite(Map<String, dynamic> row) {
    return Song(
      videoId: row['videoId'] as String? ?? '',
      title: row['title'] as String? ?? '',
      artist: row['artist'] as String? ?? '',
      album: row['album'] as String? ?? '',
      thumbnail: row['thumbnail'] as String? ?? '',
      duration: Duration(seconds: (row['duration'] as int?) ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'videoId': videoId,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnail': thumbnail,
      'durationSeconds': duration.inSeconds,
    };
  }

  Song copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? album,
    String? thumbnail,
    Duration? duration,
  }) {
    return Song(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song &&
        other.videoId == videoId &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.thumbnail == thumbnail &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(videoId, title, artist, album, thumbnail, duration);

  @override
  String toString() => 'Song(videoId: $videoId, title: $title, artist: $artist)';
}
