// lib/widgets/song/song_tile.dart

import 'package:flutter/material.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/data/models/song.dart';

/// Compact horizontal row representing a single song: thumbnail, title,
/// artist, duration. Used by the Favorites screen and the Home screen's
/// Recently Played section.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.trailing,
  });

  final Song song;
  final VoidCallback onTap;

  /// Optional trailing widget (e.g. a remove/favorite icon button). If
  /// null, the song's duration is shown instead.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: context.appColors.bgElevated,
                child: song.thumbnail.isNotEmpty
                    ? Image.network(
                        song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: accent,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        color: accent,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Text(
                  Formatters.duration(song.duration),
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textTertiary,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
