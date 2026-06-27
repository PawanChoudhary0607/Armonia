// lib/data/models/curated_playlist.dart

import 'package:flutter/material.dart';
import 'package:armonia/data/models/song.dart';

/// A single static, curated Armonia playlist containing fully-resolved
/// [Song] objects with real YouTube video IDs.
@immutable
class CuratedPlaylist {
  const CuratedPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tintColor,
    required this.songs,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color tintColor;
  final List<Song> songs;
  final String? coverUrl;

  int get songCount => songs.length;
}
