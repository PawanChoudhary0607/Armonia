// lib/widgets/layout/app_scaffold.dart
//
// Bug 4 fix — Mini Player clips on devices with a home indicator:
//   Root cause: the Column inside bottomNavigationBar had no SafeArea.
//   MiniPlayer sits above the nav bar inside the Column. On devices with
//   a bottom system bar the MiniPlayer bottom edge was being hidden under
//   the system UI because only the nav bar itself had bottom padding applied,
//   not the MiniPlayer above it.
//   Fix: wrap the entire Column in a ColoredBox+SafeArea so the system
//   bottom inset is consumed ONCE for the whole stack, not just the nav bar.
//   The MiniPlayer keeps its existing Padding(fromLTRB(12,0,12,8)) which
//   gives it visual breathing room above the nav bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/widgets/layout/mini_player.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: context.appColors.glassHeavy,
        // SafeArea here ensures the home indicator / gesture bar
        // is always outside the MiniPlayer + NavBar stack. Without
        // this, the MiniPlayer was partially occluded on notched
        // and gesture-bar devices.
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              _BottomNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(
                  index,
                  initialLocation:
                      index == navigationShell.currentIndex,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Analytics',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.appColors.borderSubtle),
          ),
        ),
        child: Row(
          children: List.generate(
            _items.length,
            (i) => Expanded(
              child: _NavBarItem(
                item: _items[i],
                isActive: currentIndex == i,
                accent: accent,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? accent : context.appColors.textSecondary,
              size: 24,
              semanticLabel: item.label,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
