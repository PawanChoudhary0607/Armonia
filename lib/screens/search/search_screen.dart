// lib/screens/search/search_screen.dart
//
// Bug 7 fix — Search result action hit targets:
//   Root cause: the heart GestureDetector used HitTestBehavior.opaque,
//   which swallowed InkWell ripples visually but still competed with the
//   row tap. The three-dot GestureDetector had no behavior specified
//   (defaulted to deferToChild), so taps on its padding area fell through
//   to the row InkWell and played the song instead of opening the menu.
//   Fix:
//     • Both the heart and three-dot are now IconButton widgets with
//       explicit constraints(40×40). IconButton handles its own hit-test
//       correctly inside an InkWell parent — Flutter's gesture arena
//       resolves them correctly because IconButton uses a GestureDetector
//       with opaque behavior internally, but the arena still distinguishes
//       the specific recognisers.
//     • The row InkWell uses onTap for play and onLongPress for options —
//       long-press is the secondary action, matching Spotify's UX.
//     • Three-dot button calls _showSongOptions via its own onPressed,
//       not via a GestureDetector with fallthrough padding.
//
// UNCHANGED: debounce, stale-search guard, MusicSearchService call,
//            search history, AddToPlaylist sheet, CreateAndAddDialog.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/queue_provider.dart';
import 'package:armonia/providers/search_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN ROOT
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final SearchState search = ref.watch(searchProvider);
    final SearchNotifier notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Search',
                style: AppTypography.displaySm
                    .copyWith(color: context.appColors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBar(accent: accent),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _SearchBody(
                  search: search, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar({required this.accent});
  final Color accent;

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(searchProvider).query);
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query =
        ref.watch(searchProvider.select((s) => s.query));
    if (query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focusNode.hasFocus
              ? context.appColors.borderStrong
              : context.appColors.borderMedium,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyLg
            .copyWith(color: context.appColors.textPrimary),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          hintText: 'Songs, artists, albums...',
          hintStyle: AppTypography.bodyLg
              .copyWith(color: context.appColors.textTertiary),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded,
              color: context.appColors.textTertiary),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.appColors.textTertiary),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchProvider.notifier).clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {});
          ref.read(searchProvider.notifier).setQuery(value);
        },
        onSubmitted: (_) =>
            ref.read(searchProvider.notifier).submit(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BODY
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBody extends ConsumerWidget {
  const _SearchBody(
      {required this.search, required this.notifier});

  final SearchState search;
  final SearchNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (search.isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: context.appColors.textSecondary));
    }

    if (search.error != null) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: search.error!,
        actionLabel: 'Retry',
        onAction: () => notifier.submit(),
      );
    }

    if (!search.hasSearched) {
      if (search.history.isEmpty) {
        return const _StatusMessage(
          icon: Icons.search_rounded,
          title: 'Search Armonia',
          subtitle: 'Find any song, artist or album.',
        );
      }
      return _HistoryList(
          history: search.history, notifier: notifier);
    }

    if (search.results.isEmpty) {
      return const _StatusMessage(
        icon: Icons.search_off_rounded,
        title: 'No results',
        subtitle: 'Try a different search term.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: search.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => _SearchResultTile(
        results: search.results,
        index: index,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY LIST
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryList extends ConsumerWidget {
  const _HistoryList(
      {required this.history, required this.notifier});

  final List<String> history;
  final SearchNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Recent Searches',
                    style: AppTypography.titleSm.copyWith(
                        color: context.appColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => notifier.clearHistory(),
                child: Text('Clear all',
                    style: AppTypography.bodySm.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .primary)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final String query = history[index];
              return _HistoryItem(
                query: query,
                onTap: () {
                  ref
                      .read(searchProvider.notifier)
                      .setQuery(query);
                  ref.read(searchProvider.notifier).submit();
                },
                onRemove: () =>
                    notifier.removeFromHistory(query),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history_rounded,
                size: 18, color: context.appColors.textTertiary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                      color: context.appColors.textPrimary)),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 16,
                    color: context.appColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH RESULT TILE
//
// Bug 7 fix: replaced GestureDetector wrappers for heart and three-dot with
// IconButton. This lets Flutter's gesture arena correctly route taps:
//   • Tap anywhere on the row body → play (InkWell.onTap)
//   • Tap the ♥ icon button → toggleLike (IconButton.onPressed)
//   • Tap the ⋮ icon button → song options sheet (IconButton.onPressed)
//   • Long-press anywhere on the row → song options sheet (InkWell.onLongPress)
// Previously the GestureDetector padding area for ⋮ was falling through to
// the row InkWell and playing the song instead of opening the menu.
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile(
      {required this.results, required this.index});

  final List<Song> results;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Song song = results[index];
    final bool isLiked = ref.watch(
        playlistProvider.select((s) => s.isLiked(song.videoId)));
    final Color accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        debugPrint(
          '[Search] tap → playFromList index=$index '
          'videoId="${song.videoId}" title="${song.title}"',
        );
        ref
            .read(queueProvider.notifier)
            .playFromList(results, index);
        context.push(AppRoutes.player);
      },
      onLongPress: () => _showSongOptions(context, ref, song),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: song.thumbnail.isNotEmpty
                    ? Image.network(song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _ThumbFallback())
                    : const _ThumbFallback(),
              ),
            ),
            const SizedBox(width: 12),
            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                          color:
                              context.appColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                          color: context
                              .appColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Duration
            Text(Formatters.duration(song.duration),
                style: AppTypography.caption.copyWith(
                    color: context.appColors.textTertiary)),
            // ── Heart — IconButton so hit test is scoped
            //    to the icon's 40×40 touch target only.
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked
                    ? accent
                    : context.appColors.textTertiary,
              ),
              tooltip: isLiked
                  ? 'Remove from Liked Songs'
                  : 'Add to Liked Songs',
              onPressed: () => ref
                  .read(playlistProvider.notifier)
                  .toggleLike(song),
            ),
            // ── Three-dot — IconButton with explicit constraints.
            //    onPressed is the sole entry point; no padding falls
            //    through to the parent InkWell.
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(Icons.more_vert_rounded,
                  color: context.appColors.textTertiary),
              tooltip: 'More options',
              onPressed: () =>
                  _showSongOptions(context, ref, song),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(
      BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) =>
          _SongOptionsSheet(song: song),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONG OPTIONS SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SongOptionsSheet extends ConsumerWidget {
  const _SongOptionsSheet({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaylistState ps = ref.watch(playlistProvider);
    final PlaylistNotifier pn =
        ref.read(playlistProvider.notifier);
    final bool isLiked = ps.isLiked(song.videoId);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        border:
            Border.all(color: context.appColors.borderSubtle),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin:
                  const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: song.thumbnail.isNotEmpty
                        ? Image.network(song.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _ThumbFallback())
                        : const _ThumbFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMd
                              .copyWith(
                                  color: context
                                      .appColors.textPrimary)),
                      Text(song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                              color: context
                                  .appColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              color: context.appColors.borderSubtle, height: 1),
          _SheetOption(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: isLiked
                ? AppColors.liked
                : context.appColors.textSecondary,
            label: isLiked
                ? 'Remove from Liked Songs'
                : 'Add to Liked Songs',
            onTap: () {
              pn.toggleLike(song);
              Navigator.of(context).pop();
            },
          ),
          _SheetOption(
            icon: Icons.playlist_add_rounded,
            iconColor: context.appColors.textSecondary,
            label: 'Add to playlist',
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) =>
                    _AddToPlaylistSheet(song: song),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: AppTypography.bodyLg.copyWith(
                    color: context.appColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD TO PLAYLIST SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaylistState ps = ref.watch(playlistProvider);
    final PlaylistNotifier notifier =
        ref.read(playlistProvider.notifier);
    final Color accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        border:
            Border.all(color: context.appColors.borderSubtle),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6),
      padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin:
                  const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Add to playlist',
                style: AppTypography.titleLg.copyWith(
                    color: context.appColors.textPrimary)),
          ),
          Divider(
              color: context.appColors.borderSubtle,
              height: 1),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              _showCreateAndAdd(context, notifier, song);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text('New playlist',
                      style: AppTypography.bodyLg.copyWith(
                          color:
                              context.appColors.textPrimary)),
                ],
              ),
            ),
          ),
          if (ps.playlists.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('No playlists yet.',
                  style: AppTypography.bodySm.copyWith(
                      color:
                          context.appColors.textTertiary)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ps.playlists.length,
                itemBuilder: (context, index) {
                  final UserPlaylist pl =
                      ps.playlists[index];
                  final bool already = pl.songs
                      .any((s) => s.videoId == song.videoId);
                  return InkWell(
                    onTap: already
                        ? null
                        : () {
                            notifier.addSongToPlaylist(
                                pl.id, song);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  'Added to "${pl.name}"',
                                  style:
                                      AppTypography.bodyMd),
                              duration:
                                  const Duration(seconds: 2),
                              behavior:
                                  SnackBarBehavior.floating,
                              backgroundColor: context
                                  .appColors.bgElevated,
                            ));
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context
                                  .appColors.bgElevated,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(
                                Icons.queue_music_rounded,
                                color: already
                                    ? context.appColors
                                        .textTertiary
                                    : accent,
                                size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(pl.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: AppTypography.bodyLg
                                    .copyWith(
                                        color: already
                                            ? context.appColors
                                                .textTertiary
                                            : context.appColors
                                                .textPrimary)),
                          ),
                          if (already)
                            Icon(Icons.check_rounded,
                                color: context
                                    .appColors.textTertiary,
                                size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateAndAdd(BuildContext context,
      PlaylistNotifier notifier, Song song) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateAndAddDialog(
        notifier: notifier,
        song: song,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE-AND-ADD DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _CreateAndAddDialog extends StatefulWidget {
  const _CreateAndAddDialog({
    required this.notifier,
    required this.song,
  });

  final PlaylistNotifier notifier;
  final Song song;

  @override
  State<_CreateAndAddDialog> createState() =>
      _CreateAndAddDialogState();
}

class _CreateAndAddDialogState
    extends State<_CreateAndAddDialog> {
  final TextEditingController _ctrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm(BuildContext ctx) {
    final String name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter a playlist name');
      return;
    }
    final String id = widget.notifier.createPlaylist(name);
    if (id.isNotEmpty) {
      widget.notifier.addSongToPlaylist(id, widget.song);
    }
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      backgroundColor: context.appColors.bgSurface,
      title: Text('New Playlist',
          style: AppTypography.titleLg
              .copyWith(color: context.appColors.textPrimary)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypography.bodyLg
            .copyWith(color: context.appColors.textPrimary),
        cursorColor: accent,
        decoration: InputDecoration(
          hintText: 'Playlist name',
          hintStyle: AppTypography.bodyLg.copyWith(
              color: context.appColors.textTertiary),
          errorText: _errorText,
          errorStyle: AppTypography.bodySm.copyWith(
              color: AppColors.danger),
          filled: true,
          fillColor: context.appColors.bgElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: context.appColors.borderMedium),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: context.appColors.borderMedium),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.danger),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _confirm(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: AppTypography.titleSm.copyWith(
                  color: context.appColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => _confirm(context),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Create',
              style: AppTypography.titleSm
                  .copyWith(color: Colors.black)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.bgSurface,
      child: Icon(Icons.music_note_rounded,
          color: context.appColors.textTertiary, size: 20),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.appColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: context.appColors.borderSubtle),
              ),
              child: Icon(icon, color: accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLg.copyWith(
                    color: context.appColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                    color: context.appColors.textSecondary)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      context.appColors.textInverted,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10)),
                ),
                onPressed: onAction,
                child: Text(actionLabel!,
                    style: AppTypography.titleSm.copyWith(
                        color:
                            context.appColors.textInverted)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
