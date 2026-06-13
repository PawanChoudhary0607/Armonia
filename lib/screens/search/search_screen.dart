// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/core/utils/formatters.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/audio_provider.dart';
import 'package:armonia/providers/search_provider.dart';

/// Search screen.
///
/// Phase 2B: real YouTube search via [MusicSearchService]
/// (`youtube_explode_dart`), with a debounced search bar, loading/error
/// states, and a results list. Tapping a result plays it through the
/// existing [audioProvider] and opens the Player screen.
///
/// Suggestions, voice search, and genre categories remain out of scope for
/// this phase.
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
                style: AppTypography.displaySm.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBar(accent: accent),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _SearchBody(search: search, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _controller = TextEditingController(
      text: ref.read(searchProvider).query,
    );
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
    final String query = ref.watch(
      searchProvider.select((s) => s.query),
    );

    // Keep the controller in sync if the query is cleared externally.
    if (query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.darkBorderStrong
              : AppColors.darkBorderMedium,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyLg.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          hintText: 'Songs, artists, albums...',
          hintStyle: AppTypography.bodyLg.copyWith(
            color: AppColors.darkTextTertiary,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.darkTextTertiary,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.darkTextTertiary,
                  ),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchProvider.notifier).clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {}); // refresh suffix icon visibility
          ref.read(searchProvider.notifier).setQuery(value);
        },
        onSubmitted: (_) => ref.read(searchProvider.notifier).submit(),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.search, required this.notifier});

  final SearchState search;
  final SearchNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (search.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.darkTextSecondary,
        ),
      );
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
      return const _StatusMessage(
        icon: Icons.search_rounded,
        title: 'Search Armonia',
        subtitle: 'Find any song, artist, or album.',
      );
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
      itemBuilder: (context, index) {
        final Song song = search.results[index];
        return _SearchResultTile(song: song);
      },
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ref.read(audioProvider.notifier).playSong(song);
        context.push(AppRoutes.player);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: song.thumbnail.isNotEmpty
                    ? Image.network(
                        song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _ThumbnailFallback(),
                      )
                    : const _ThumbnailFallback(),
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
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.duration(song.duration),
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSurface,
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.darkTextTertiary,
        size: 20,
      ),
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
                color: AppColors.darkBgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBorderSubtle),
              ),
              child: Icon(icon, color: accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.darkTextInverted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTypography.titleSm.copyWith(
                    color: AppColors.darkTextInverted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
