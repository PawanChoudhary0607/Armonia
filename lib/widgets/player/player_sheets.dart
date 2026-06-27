// lib/widgets/player/player_sheets.dart
//
// Phase 5B — compile-clean, layout-safe version.
//
// Fix vs previous version:
//   • Replaced ReorderableListView.builder(shrinkWrap:true) inside
//     CustomScrollView with SliverReorderableList — the correct approach
//     for drag-to-reorder inside a sliver-based scroll view.
//     The previous approach caused a runtime layout assertion:
//     "RenderFlex children have non-zero flex but incoming height
//     constraints are unbounded."
//   • _QueueSheet remains a ConsumerWidget watching live queueProvider.
//   • Dismissible retained on each upcoming tile.
//   • showQueueSheet signature unchanged.
//
// PROTECTED FILES UNTOUCHED.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/queue_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

void showLyricsComingSoonSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _ComingSoonSheet(
      icon: Icons.lyrics_outlined,
      title: 'Lyrics',
      message: 'Synced lyrics are coming to Armonia soon.',
    ),
  );
}

/// Opens the live queue management sheet.
/// The [queue] parameter is kept for call-site compatibility but the sheet
/// subscribes to [queueProvider] directly for live updates.
void showQueueSheet(BuildContext context, QueueState queue) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QueueSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LYRICS PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppTypography.titleLg
                    .copyWith(color: context.appColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd
                    .copyWith(color: context.appColors.textSecondary)),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.appColors.bgElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('COMING SOON',
                  style: AppTypography.label
                      .copyWith(color: context.appColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE SHEET — live, editable, layout-safe
// ─────────────────────────────────────────────────────────────────────────────

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QueueState queue = ref.watch(queueProvider);
    final QueueNotifier notifier = ref.read(queueProvider.notifier);
    final Color accent = Theme.of(context).colorScheme.primary;
    final Song? current = queue.currentSong;
    final List<Song> upcoming = queue.upcoming;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
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
              // ── Fixed header — not scrollable ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Queue',
                              style: AppTypography.titleLg.copyWith(
                                  color: context
                                      .appColors.textPrimary)),
                        ),
                        if (upcoming.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              for (int i =
                                      queue.songs.length - 1;
                                  i > queue.currentIndex;
                                  i--) {
                                notifier.removeAt(i);
                              }
                            },
                            child: Text('Clear next',
                                style: AppTypography.bodySm
                                    .copyWith(
                                        color: context.appColors
                                            .textSecondary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Scrollable + reorderable body ─────────────────────────
              Expanded(
                child: current == null
                    ? Center(
                        child: Text('Nothing queued.',
                            style: AppTypography.bodyMd.copyWith(
                                color: context
                                    .appColors.textSecondary)))
                    : CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          // NOW PLAYING — static, not reorderable
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 0, 24, 0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('NOW PLAYING',
                                      style: AppTypography.label
                                          .copyWith(color: accent)),
                                  const SizedBox(height: 8),
                                  _QueueTile(
                                      song: current,
                                      isActive: true),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),

                          if (upcoming.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(
                                        24, 0, 24, 8),
                                child: Text('UP NEXT',
                                    style: AppTypography.label
                                        .copyWith(
                                            color: context.appColors
                                                .textTertiary)),
                              ),
                            ),

                            // SliverReorderableList is the correct
                            // approach inside a CustomScrollView —
                            // no shrinkWrap, no nested scroll physics.
                            SliverReorderableList(
                              itemCount: upcoming.length,
                              onReorder: (oldIndex, newIndex) {
                                final int absOld =
                                    queue.currentIndex +
                                        1 +
                                        oldIndex;
                                final int absNew =
                                    queue.currentIndex +
                                        1 +
                                        newIndex;
                                notifier.reorder(absOld, absNew);
                              },
                              proxyDecorator:
                                  (child, index, animation) =>
                                      Material(
                                color: Colors.transparent,
                                child: child,
                              ),
                              itemBuilder: (context, i) {
                                final Song song = upcoming[i];
                                final int absIndex =
                                    queue.currentIndex + 1 + i;
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey(
                                      '${song.videoId}_$absIndex'),
                                  index: i,
                                  child: Dismissible(
                                    key: ValueKey(
                                        'dismiss_${song.videoId}_$absIndex'),
                                    direction:
                                        DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 4),
                                      alignment:
                                          Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(
                                              right: 20),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: Icon(
                                          Icons
                                              .remove_circle_outline_rounded,
                                          color: AppColors.danger,
                                          size: 22),
                                    ),
                                    onDismissed: (_) =>
                                        notifier.removeAt(absIndex),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              24, 0, 24, 4),
                                      child: _QueueTile(
                                          song: song,
                                          isActive: false),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 24 +
                                  MediaQuery.paddingOf(context)
                                      .bottom,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE TILE
// ─────────────────────────────────────────────────────────────────────────────

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.song, required this.isActive});

  final Song song;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? context.appColors.bgElevated
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border(left: BorderSide(color: accent, width: 3))
            : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: context.appColors.bgElevated,
              child: song.thumbnail.isNotEmpty
                  ? Image.network(
                      song.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: accent,
                          size: 18),
                    )
                  : Icon(Icons.music_note_rounded,
                      color: accent, size: 18),
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
                    color: isActive
                        ? accent
                        : context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!isActive)
            Icon(Icons.drag_handle_rounded,
                color: context.appColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.appColors.textTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
