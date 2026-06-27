// lib/widgets/home/quick_access_grid.dart
//
// Phase 5B — Curated playlist entries removed.
// Only Liked Songs and Recently Played remain in the quick-access grid.
// This widget is no longer used by home_screen.dart (HomeScreen was
// rewritten), but is kept so nothing referencing it breaks at compile time.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final List<_Item> items = <_Item>[
      _Item(
        label: 'Liked Songs',
        icon: Icons.favorite_rounded,
        color: AppColors.liked,
        onTap: () => context.push(AppRoutes.likedSongs),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final _Item item = items[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: item.onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    AppColors.premiumCardGradientFor(context, item.color),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: context.appColors.borderSubtle),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSm.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Item {
  const _Item({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
