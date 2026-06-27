// lib/screens/library/library_screen.dart
//
// Bug-fix session:
//
// Bug 1 — Playlist card bottom overflow:
//   Root cause: _PlaylistCard used a Container without a fixed height, letting
//   the PopupMenuButton expand the Row vertically beyond the clip boundary.
//   Fix: replaced outer Container+clipBehavior with a ClipRRect wrapping a
//   fixed-height (72dp) InkWell content row. PopupMenuButton is constrained
//   to SizedBox(width:40,height:40) and aligned with crossAxisAlignment.center.
//
// Bug 3 — Add Songs flow:
//   The _AddSongsSheet was already correct (ConsumerStatefulWidget, inline
//   search, no navigation away). No further change needed.
//
// PROTECTED FILES UNTOUCHED.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/queue_provider.dart';
import 'package:armonia/providers/search_provider.dart';
import 'package:armonia/widgets/layout/mini_player.dart';
import 'package:armonia/widgets/song/song_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LIBRARY SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaylistState ps = ref.watch(playlistProvider);
    final PlaylistNotifier notifier = ref.read(playlistProvider.notifier);
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Library',
                          style: AppTypography.displaySm.copyWith(
                              color: context.appColors.textPrimary)),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: accent),
                      tooltip: 'Create playlist',
                      onPressed: () =>
                          _showCreateDialog(context, notifier),
                    ),
                  ],
                ),
              ),
            ),

            // Liked Songs pinned card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _PinnedPlaylistCard(
                  label: 'Liked Songs',
                  icon: Icons.favorite_rounded,
                  color: AppColors.liked,
                  count: ps.likedSongs.length,
                  onTap: () => context.push(AppRoutes.likedSongs),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text('Your Playlists',
                    style: AppTypography.titleLg.copyWith(
                        color: context.appColors.textPrimary)),
              ),
            ),

            if (ps.playlists.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: _EmptyPlaylists(
                    accent: accent,
                    onCreateTap: () =>
                        _showCreateDialog(context, notifier),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList.separated(
                  itemCount: ps.playlists.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final UserPlaylist pl = ps.playlists[index];
                    return _PlaylistCard(
                      playlist: pl,
                      accent: accent,
                      onTap: () => context
                          .push(AppRoutes.userPlaylistPath(pl.id)),
                      onAddSongs: () =>
                          _showAddSongsSheet(context, pl.id),
                      onPlayAll: () {
                        if (pl.songs.isEmpty) return;
                        ref
                            .read(queueProvider.notifier)
                            .playFromList(pl.songs, 0);
                        context.push(AppRoutes.player);
                      },
                      onShuffle: () {
                        if (pl.songs.isEmpty) return;
                        final List<Song> shuffled =
                            List<Song>.from(pl.songs)..shuffle();
                        ref
                            .read(queueProvider.notifier)
                            .playFromList(shuffled, 0);
                        context.push(AppRoutes.player);
                      },
                      onRename: () =>
                          _showRenameDialog(context, notifier, pl),
                      onDelete: () =>
                          _showDeleteDialog(context, notifier, pl),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, PlaylistNotifier notifier) {
    final TextEditingController ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => _PlaylistNameDialog(
        title: 'New Playlist',
        actionLabel: 'Create',
        controller: ctrl,
        onConfirm: () {
          final String name = ctrl.text.trim();
          if (name.isEmpty) return;
          notifier.createPlaylist(name);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context,
      PlaylistNotifier notifier, UserPlaylist pl) {
    final TextEditingController ctrl =
        TextEditingController(text: pl.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => _PlaylistNameDialog(
        title: 'Rename Playlist',
        actionLabel: 'Save',
        controller: ctrl,
        onConfirm: () {
          final String name = ctrl.text.trim();
          if (name.isEmpty) return;
          notifier.renamePlaylist(pl.id, name);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      PlaylistNotifier notifier, UserPlaylist pl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.bgSurface,
        title: Text('Delete "${pl.name}"?',
            style: AppTypography.titleLg
                .copyWith(color: context.appColors.textPrimary)),
        content: Text('This cannot be undone.',
            style: AppTypography.bodyMd
                .copyWith(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTypography.titleSm.copyWith(
                    color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.deletePlaylist(pl.id);
              Navigator.of(ctx).pop();
            },
            child: Text('Delete',
                style: AppTypography.titleSm
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD SONGS SHEET — ConsumerStatefulWidget, reads own ref
// ─────────────────────────────────────────────────────────────────────────────

void _showAddSongsSheet(BuildContext context, String playlistId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => _AddSongsSheet(playlistId: playlistId),
  );
}

class _AddSongsSheet extends ConsumerStatefulWidget {
  const _AddSongsSheet({required this.playlistId});
  final String playlistId;

  @override
  ConsumerState<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends ConsumerState<_AddSongsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<Song> _results = const <Song>[];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const <Song>[];
        _isLoading = false;
        _error = null;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(
        const Duration(milliseconds: 500), () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    try {
      final List<Song> results =
          await ref.read(musicSearchServiceProvider).search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = const <Song>[];
          _isLoading = false;
          _error = 'Search failed. Try again.';
        });
      }
    }
  }

  void _addSong(Song song) {
    ref
        .read(playlistProvider.notifier)
        .addSongToPlaylist(widget.playlistId, song);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Added "${song.title}"', style: AppTypography.bodyMd),
      backgroundColor: context.appColors.bgElevated,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final UserPlaylist? pl = ref
        .read(playlistProvider.notifier)
        .playlistById(widget.playlistId);
    final Set<String> existingIds =
        pl?.songs.map((s) => s.videoId).toSet() ?? <String>{};

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.bgSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin:
                      const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Add Songs',
                          style: AppTypography.titleLg.copyWith(
                              color:
                                  context.appColors.textPrimary)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color:
                              context.appColors.textSecondary),
                      onPressed: () =>
                          Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: AppTypography.bodyLg.copyWith(
                      color: context.appColors.textPrimary),
                  cursorColor: accent,
                  decoration: InputDecoration(
                    hintText: 'Search for songs to add...',
                    hintStyle: AppTypography.bodyLg.copyWith(
                        color: context.appColors.textTertiary),
                    filled: true,
                    fillColor: context.appColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: context.appColors.borderMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: context.appColors.borderMedium),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.appColors.textTertiary),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: context
                                    .appColors.textTertiary),
                            onPressed: () {
                              _ctrl.clear();
                              _onQueryChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    if (v.trim().isNotEmpty) _search(v.trim());
                  },
                ),
              ),
              Divider(
                  height: 1,
                  color: context.appColors.borderSubtle),
              Expanded(
                  child: _buildResults(
                      accent, existingIds, scrollController)),
              SizedBox(
                  height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(Color accent, Set<String> existingIds,
      ScrollController scrollController) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(_error!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd
                .copyWith(color: context.appColors.textSecondary)),
      ));
    }
    if (_ctrl.text.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded,
                  color: context.appColors.textTertiary,
                  size: 48),
              const SizedBox(height: 16),
              Text('Search for songs to add.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                      color: context.appColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
          child: Text('No results.',
              style: AppTypography.bodyMd.copyWith(
                  color: context.appColors.textSecondary)));
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final Song song = _results[index];
        final bool added = existingIds.contains(song.videoId);
        return _AddSongTile(
          song: song,
          alreadyAdded: added,
          accent: accent,
          onAdd: added ? null : () => _addSong(song),
        );
      },
    );
  }
}

class _AddSongTile extends StatelessWidget {
  const _AddSongTile({
    required this.song,
    required this.alreadyAdded,
    required this.accent,
    required this.onAdd,
  });

  final Song song;
  final bool alreadyAdded;
  final Color accent;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: context.appColors.bgElevated,
            child: song.thumbnail.isNotEmpty
                ? Image.network(song.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.music_note_rounded,
                        color: accent,
                        size: 20))
                : Icon(Icons.music_note_rounded,
                    color: accent, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                      color: context.appColors.textPrimary)),
              const SizedBox(height: 2),
              Text(song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        alreadyAdded
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.check_circle_rounded,
                    color: accent, size: 22),
              )
            : IconButton(
                icon:
                    const Icon(Icons.add_circle_outline_rounded),
                color: accent,
                iconSize: 24,
                constraints: const BoxConstraints(
                    minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                onPressed: onAdd,
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINNED CARD (Liked Songs)
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedPlaylistCard extends StatelessWidget {
  const _PinnedPlaylistCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient:
                AppColors.premiumCardGradientFor(context, color),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: context.appColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.titleMd.copyWith(
                            color:
                                context.appColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      count == 1 ? '1 song' : '$count songs',
                      style: AppTypography.bodySm.copyWith(
                          color:
                              context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textTertiary,
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST CARD
//
// Bug 1 fix: removed Container+clipBehavior wrapper. The card is now a
// Material+InkWell with a fixed-height (72dp) content row. PopupMenuButton
// sits in a SizedBox(width:40,height:40) so it can never expand the row
// height and cause overflow. crossAxisAlignment.center keeps everything
// vertically aligned without letting any child grow the row unboundedly.
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.accent,
    required this.onTap,
    required this.onAddSongs,
    required this.onPlayAll,
    required this.onShuffle,
    required this.onRename,
    required this.onDelete,
  });

  final UserPlaylist playlist;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onAddSongs;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          // Fixed height prevents the PopupMenuButton from expanding
          // the row and causing a bottom overflow.
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: context.appColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Playlist icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.queue_music_rounded,
                    color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              // Title + count — Expanded fills remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd.copyWith(
                          color: context.appColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playlist.songCount == 1
                          ? '1 song'
                          : '${playlist.songCount} songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                          color:
                              context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // PopupMenuButton in a fixed 40×40 box — cannot grow
              // the row height regardless of what the OS renders.
              SizedBox(
                width: 40,
                height: 40,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded,
                      color: context.appColors.textTertiary,
                      size: 20),
                  color: context.appColors.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: context.appColors.borderSubtle),
                  ),
                  onSelected: (String v) {
                    switch (v) {
                      case 'add':
                        onAddSongs();
                      case 'play':
                        onPlayAll();
                      case 'shuffle':
                        onShuffle();
                      case 'rename':
                        onRename();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    _item(context,
                        value: 'add',
                        icon: Icons.add_rounded,
                        label: 'Add Songs',
                        color: context.appColors.textSecondary),
                    _item(context,
                        value: 'play',
                        icon: Icons.play_arrow_rounded,
                        label: 'Play All',
                        color: context.appColors.textSecondary),
                    _item(context,
                        value: 'shuffle',
                        icon: Icons.shuffle_rounded,
                        label: 'Shuffle',
                        color: context.appColors.textSecondary),
                    _item(context,
                        value: 'rename',
                        icon: Icons.edit_rounded,
                        label: 'Rename',
                        color: context.appColors.textSecondary),
                    _item(context,
                        value: 'delete',
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: AppColors.danger),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(BuildContext context,
          {required String value,
          required IconData icon,
          required String label,
          required Color color}) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: AppTypography.bodyMd.copyWith(color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY PLAYLISTS STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists(
      {required this.accent, required this.onCreateTap});
  final Color accent;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.add_rounded, color: accent, size: 30),
          ),
          const SizedBox(height: 16),
          Text('No playlists yet',
              style: AppTypography.titleMd
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Create a playlist to organise your music.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                  color: context.appColors.textSecondary)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create playlist'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: AppTypography.titleSm,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST NAME DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistNameDialog extends StatelessWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.actionLabel,
    required this.controller,
    required this.onConfirm,
  });
  final String title;
  final String actionLabel;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      backgroundColor: context.appColors.bgSurface,
      title: Text(title,
          style: AppTypography.titleLg
              .copyWith(color: context.appColors.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypography.bodyLg
            .copyWith(color: context.appColors.textPrimary),
        cursorColor: accent,
        decoration: InputDecoration(
          hintText: 'Playlist name',
          hintStyle: AppTypography.bodyLg
              .copyWith(color: context.appColors.textTertiary),
          filled: true,
          fillColor: context.appColors.bgElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: context.appColors.borderMedium)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: context.appColors.borderMedium)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
        onSubmitted: (_) => onConfirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: AppTypography.titleSm.copyWith(
                  color: context.appColors.textSecondary)),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(actionLabel,
              style: AppTypography.titleSm
                  .copyWith(color: Colors.black)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    this.playlistId,
    this.isLikedSongs = false,
  });

  final String? playlistId;
  final bool isLikedSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaylistState ps = ref.watch(playlistProvider);
    final PlaylistNotifier notifier =
        ref.read(playlistProvider.notifier);
    final Color accent = Theme.of(context).colorScheme.primary;

    final List<Song> songs;
    final String title;

    if (isLikedSongs) {
      songs = ps.likedSongs;
      title = 'Liked Songs';
    } else {
      final UserPlaylist? pl =
          notifier.playlistById(playlistId ?? '');
      if (pl == null) {
        return Scaffold(
          backgroundColor: context.appColors.bgBase,
          appBar: AppBar(
            backgroundColor: context.appColors.bgBase,
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios_new_rounded, size: 20),
              color: context.appColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Playlist',
                style: AppTypography.titleLg.copyWith(
                    color: context.appColors.textPrimary)),
          ),
          bottomNavigationBar:
              const SafeArea(top: false, child: MiniPlayer()),
          body: Center(
            child: Text('Playlist not found.',
                style: AppTypography.bodyMd.copyWith(
                    color: context.appColors.textSecondary)),
          ),
        );
      }
      songs = pl.songs;
      title = pl.name;
    }

    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        backgroundColor: context.appColors.bgBase,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, size: 20),
          color: context.appColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title,
            style: AppTypography.titleLg
                .copyWith(color: context.appColors.textPrimary)),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.shuffle_rounded,
                  color: context.appColors.textSecondary),
              tooltip: 'Shuffle',
              onPressed: () {
                final List<Song> shuffled =
                    List<Song>.from(songs)..shuffle();
                ref
                    .read(queueProvider.notifier)
                    .playFromList(shuffled, 0);
                context.push(AppRoutes.player);
              },
            ),
          if (!isLikedSongs && playlistId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: context.appColors.textSecondary),
              color: context.appColors.bgElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: context.appColors.borderSubtle),
              ),
              onSelected: (String v) {
                switch (v) {
                  case 'add':
                    _showAddSongsSheet(context, playlistId!);
                  case 'play':
                    if (songs.isEmpty) return;
                    ref
                        .read(queueProvider.notifier)
                        .playFromList(songs, 0);
                    context.push(AppRoutes.player);
                  case 'shuffle':
                    if (songs.isEmpty) return;
                    final List<Song> s =
                        List<Song>.from(songs)..shuffle();
                    ref
                        .read(queueProvider.notifier)
                        .playFromList(s, 0);
                    context.push(AppRoutes.player);
                  case 'rename':
                    final UserPlaylist? pl =
                        notifier.playlistById(playlistId!);
                    if (pl != null) {
                      _showRenameDialog(context, notifier, pl);
                    }
                  case 'delete':
                    _showDeleteDialog(
                        context, notifier, playlistId!, title);
                }
              },
              itemBuilder: (_) => [
                _menuItem(context,
                    value: 'add',
                    icon: Icons.add_rounded,
                    label: 'Add Songs',
                    color: context.appColors.textSecondary),
                _menuItem(context,
                    value: 'play',
                    icon: Icons.play_arrow_rounded,
                    label: 'Play All',
                    color: context.appColors.textSecondary),
                _menuItem(context,
                    value: 'shuffle',
                    icon: Icons.shuffle_rounded,
                    label: 'Shuffle',
                    color: context.appColors.textSecondary),
                _menuItem(context,
                    value: 'rename',
                    icon: Icons.edit_rounded,
                    label: 'Rename',
                    color: context.appColors.textSecondary),
                _menuItem(context,
                    value: 'delete',
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: AppColors.danger),
              ],
            ),
        ],
      ),
      bottomNavigationBar:
          const SafeArea(top: false, child: MiniPlayer()),
      body: songs.isEmpty
          ? _EmptySongList(
              accent: accent,
              isLikedSongs: isLikedSongs,
              playlistId: playlistId,
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(queueProvider.notifier)
                            .playFromList(songs, 0);
                        context.push(AppRoutes.player);
                      },
                      icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 20),
                      label:
                          Text('Play All (${songs.length})'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        textStyle: AppTypography.titleSm,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        20, 8, 20, 32),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final Song song = songs[index];
                      return SongTile(
                        song: song,
                        onTap: () {
                          ref
                              .read(queueProvider.notifier)
                              .playFromList(songs, index);
                          context.push(AppRoutes.player);
                        },
                        trailing: !isLikedSongs &&
                                playlistId != null
                            ? IconButton(
                                icon: Icon(
                                  Icons
                                      .remove_circle_outline_rounded,
                                  color: context
                                      .appColors.textTertiary,
                                  size: 20,
                                ),
                                tooltip: 'Remove',
                                onPressed: () =>
                                    notifier.removeSongFromPlaylist(
                                        playlistId!,
                                        song.videoId),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  PopupMenuItem<String> _menuItem(BuildContext context,
          {required String value,
          required IconData icon,
          required String label,
          required Color color}) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style:
                  AppTypography.bodyMd.copyWith(color: color)),
        ]),
      );

  void _showRenameDialog(BuildContext context,
      PlaylistNotifier notifier, UserPlaylist pl) {
    final TextEditingController ctrl =
        TextEditingController(text: pl.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => _PlaylistNameDialog(
        title: 'Rename Playlist',
        actionLabel: 'Save',
        controller: ctrl,
        onConfirm: () {
          final String name = ctrl.text.trim();
          if (name.isNotEmpty) {
            notifier.renamePlaylist(pl.id, name);
          }
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      PlaylistNotifier notifier, String id, String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.bgSurface,
        title: Text('Delete "$name"?',
            style: AppTypography.titleLg
                .copyWith(color: context.appColors.textPrimary)),
        content: Text('This cannot be undone.',
            style: AppTypography.bodyMd.copyWith(
                color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTypography.titleSm.copyWith(
                    color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.deletePlaylist(id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Delete',
                style: AppTypography.titleSm
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY SONG LIST — ConsumerWidget, reads own ref
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySongList extends ConsumerWidget {
  const _EmptySongList({
    required this.accent,
    required this.isLikedSongs,
    required this.playlistId,
  });

  final Color accent;
  final bool isLikedSongs;
  final String? playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.appColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: context.appColors.borderSubtle),
              ),
              child: Icon(Icons.music_note_rounded,
                  color: accent, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              isLikedSongs
                  ? 'No liked songs yet'
                  : 'No songs yet',
              style: AppTypography.titleMd.copyWith(
                  color: context.appColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isLikedSongs
                  ? 'Tap ♥ on any song to save it here.'
                  : 'Use "Add Songs" to search and add music.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                  color: context.appColors.textSecondary),
            ),
            if (!isLikedSongs && playlistId != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    _showAddSongsSheet(context, playlistId!),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Songs'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: AppTypography.titleSm,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
