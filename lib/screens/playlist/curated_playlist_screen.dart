// lib/screens/playlist/curated_playlist_screen.dart
//
// Phase 5B — Curated playlists removed.
// Stub kept so the router file (if old version still imports it) compiles.

import 'package:flutter/material.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

class CuratedPlaylistScreen extends StatelessWidget {
  const CuratedPlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        backgroundColor: context.appColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: context.appColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Not available',
          style: AppTypography.titleLg
              .copyWith(color: context.appColors.textPrimary),
        ),
      ),
      body: Center(
        child: Text(
          'Curated playlists have been removed.',
          style: AppTypography.bodyMd
              .copyWith(color: context.appColors.textSecondary),
        ),
      ),
    );
  }
}
