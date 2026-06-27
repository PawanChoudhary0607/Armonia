// lib/screens/profile/profile_screen.dart
//
// Phase 6A — Authentication & User Accounts.
//
// Changes from Phase 5B:
//   • Reads authProvider to display real user identity (name, email,
//     account type, avatar initial).
//   • Sign Out button shown for authenticated users; guests see an
//     "Upgrade Account" prompt linking back to onboarding.
//   • Removed the "coming soon" info card — auth is now live.
//   • _StatCard, _ProfileNavRow private widgets are unchanged in API.
//
// PROTECTED FILES UNTOUCHED.
// playlist_provider.dart and recently_played_provider.dart are untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/models/user_model.dart';
import 'package:armonia/providers/auth_provider.dart';
import 'package:armonia/providers/playlist_provider.dart';
import 'package:armonia/providers/recently_played_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = Theme.of(context).colorScheme.primary;

    // Auth state — used for identity display.
    final AsyncValue<AuthState> authAsync = ref.watch(authProvider);
    final UserModel? user = ref.watch(
      authProvider.select((a) => a.valueOrNull is AuthSignedIn
          ? (a.valueOrNull! as AuthSignedIn).user
          : null),
    );

    // Counts — unchanged sources of truth.
    final int likedCount =
        ref.watch(playlistProvider.select((s) => s.likedSongs.length));
    final int recentCount =
        ref.watch(recentlyPlayedProvider.select((s) => s.songs.length));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: AppTypography.displaySm
                          .copyWith(color: context.appColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(AppRoutes.settings),
                    color: context.appColors.textSecondary,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    // ── Avatar + Identity ─────────────────────────────────
                    _AvatarSection(user: user, accent: accent),
                    const SizedBox(height: 28),

                    // ── Quick Stats ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.favorite_rounded,
                            value: '$likedCount',
                            label: 'Liked Songs',
                            color: AppColors.liked,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.history_rounded,
                            value: '$recentCount',
                            label: 'Recently Played',
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Navigation rows ───────────────────────────────────
                    _ProfileNavRow(
                      icon: Icons.favorite_rounded,
                      label: 'Liked Songs',
                      onTap: () => context.push(AppRoutes.likedSongs),
                    ),
                    const SizedBox(height: 8),
                    _ProfileNavRow(
                      icon: Icons.history_rounded,
                      label: 'Recently Played',
                      onTap: () => context.push(AppRoutes.recentlyPlayed),
                    ),
                    const SizedBox(height: 8),
                    _ProfileNavRow(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const SizedBox(height: 28),

                    // ── Account actions ───────────────────────────────────
                    authAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (authState) {
                        if (authState is AuthSignedIn &&
                            authState.user.isAuthenticated) {
                          return _SignOutButton(accent: accent);
                        }
                        // Guest — offer upgrade path.
                        return _GuestUpgradeCard(accent: accent);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR + IDENTITY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user, required this.accent});

  final UserModel? user;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.displayName ?? 'Armonia User';
    final String? email = user?.email;
    final AccountType accountType =
        user?.accountType ?? AccountType.guest;

    // Avatar initial letter — first character of display name, uppercased.
    final String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Column(
      children: [
        // Avatar circle
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.premiumCardGradientFor(context, accent),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTypography.displayMd.copyWith(color: accent),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Display name
        Text(
          displayName,
          style: AppTypography.displaySm
              .copyWith(color: context.appColors.textPrimary),
        ),
        const SizedBox(height: 4),

        // Email (if available)
        if (email != null && email.isNotEmpty) ...[
          Text(
            email,
            style: AppTypography.bodyMd
                .copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 4),
        ],

        // Account type chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Text(
            accountType.displayLabel,
            style: AppTypography.caption.copyWith(color: accent),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN OUT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text('Sign Out', style: AppTypography.bodyLg),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.50)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: AppTypography.titleLg
              .copyWith(color: ctx.appColors.textPrimary),
        ),
        content: Text(
          'Your liked songs and playlists are saved locally and '
          'will still be here when you sign back in.',
          style: AppTypography.bodyMd
              .copyWith(color: ctx.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMd
                  .copyWith(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: AppTypography.bodyMd.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.onboarding);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GUEST UPGRADE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GuestUpgradeCard extends StatelessWidget {
  const _GuestUpgradeCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_outlined, color: accent, size: 20),
              const SizedBox(width: 10),
              Text(
                'Create an account',
                style: AppTypography.titleSm.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with Google or email to unlock cloud sync '
            'and access your music across devices.',
            style: AppTypography.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.onboarding),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.contrastingTextColor(accent),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Get Started', style: AppTypography.titleSm),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PRIVATE WIDGETS (unchanged API from Phase 5B)
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.premiumCardGradientFor(context, color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value,
              style: AppTypography.displaySm
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ProfileNavRow extends StatelessWidget {
  const _ProfileNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.appColors.textSecondary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: AppTypography.bodyLg
                        .copyWith(color: context.appColors.textPrimary)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
