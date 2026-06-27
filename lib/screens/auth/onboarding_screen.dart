// lib/screens/auth/onboarding_screen.dart
//
// Phase 6A — First-launch onboarding.
// Phase 6A.1 — Session persistence fix.
// Phase 6B — Added Forgot Password flow.
//
// Changes from Phase 6A / 6A.1:
//   • markOnboardingComplete() is called after every successful auth choice
//     (guest, email, Google). This writes the onboarding flag that
//     SplashScreen checks on every subsequent launch.
//   • The screen detects whether onboarding has already been completed
//     (sign-out flow) and starts directly on page 2 (auth options), skipping
//     the welcome page.
//   • Phase 6B: Added "Forgot password?" link (shown on Sign In tab only)
//     that opens _ForgotPasswordSheet — calls AuthRepository.sendPasswordResetEmail.
//
// Navigation contract:
//   • On any successful AuthSignedIn: route to AppRoutes.home.
//   • Onboarding never appears again unless the user signs out or data is cleared.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/data/repositories/auth_repository.dart';
import 'package:armonia/providers/auth_provider.dart';
import 'package:armonia/providers/settings_provider.dart';
import 'package:armonia/screens/splash/splash_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // If the user has already completed onboarding before (e.g. they signed
    // out), skip directly to page 2 (auth options) so they don't see the
    // welcome animation again.
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final bool alreadyOnboarded =
        AuthRepository(prefs: prefs).hasOnboardingCompleted();
    final int initialPage = alreadyOnboarded ? 1 : 0;

    _pageController = PageController(initialPage: initialPage);
    _currentPage = initialPage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation helper ─────────────────────────────────────────────────────

  void _nextPage() {
    setState(() => _errorMessage = null);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  /// Shared post-auth handler: mark onboarding done and navigate home.
  Future<void> _onAuthSuccess() async {
    // Persist the onboarding completion flag. This is what SplashScreen
    // checks on every subsequent launch to skip onboarding.
    await ref.read(authProvider.notifier).markOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await ref.read(authProvider.notifier).continueAsGuest();
    if (!mounted) return;
    final authState = ref.read(authProvider).valueOrNull;
    if (authState is AuthSignedIn) {
      await _onAuthSuccess();
    } else if (authState is AuthError) {
      setState(() {
        _isLoading = false;
        _errorMessage = authState.message;
      });
    }
  }

  Future<void> _continueWithEmail() async {
    setState(() => _errorMessage = null);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EmailAuthSheet(),
    );
    if (!mounted) return;
    final authState = ref.read(authProvider).valueOrNull;
    if (authState is AuthSignedIn) {
      await _onAuthSuccess();
    } else if (authState is AuthError) {
      setState(() => _errorMessage = authState.message);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final authState = ref.read(authProvider).valueOrNull;
    if (authState is AuthSignedIn) {
      await _onAuthSuccess();
    } else if (authState is AuthError) {
      setState(() {
        _isLoading = false;
        _errorMessage = authState.message;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      final s = next.valueOrNull;
      if (s is AuthSignedIn && mounted) {
        _onAuthSuccess();
      }
    });

    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // ── Page indicator ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24, right: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: _PageDots(
                  count: 2,
                  currentIndex: _currentPage,
                  accent: accent,
                ),
              ),
            ),

            // ── Pages ──────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(accent: accent, onContinue: _nextPage),
                  _AuthOptionsPage(
                    accent: accent,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onGoogle: _continueWithGoogle,
                    onEmail: _continueWithEmail,
                    onGuest: _continueAsGuest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1 — WELCOME
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.accent, required this.onContinue});

  final Color accent;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),
          ArmoniaLogoMark(color: accent, size: 64),
          const SizedBox(height: 20),
          Text(
            'Armonia',
            style: AppTypography.displayLg.copyWith(
              color: context.appColors.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your music, understood.',
            textAlign: TextAlign.center,
            style: AppTypography.titleMd.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(flex: 2),
          _FeatureRow(
            icon: Icons.graphic_eq_rounded,
            color: accent,
            title: 'Stream anything',
            subtitle: 'Full YouTube Music catalog, zero compromise.',
          ),
          const SizedBox(height: 20),
          _FeatureRow(
            icon: Icons.favorite_rounded,
            color: AppColors.liked,
            title: 'Build your library',
            subtitle: 'Playlists, liked songs, and listening history.',
          ),
          const SizedBox(height: 20),
          _FeatureRow(
            icon: Icons.bar_chart_rounded,
            color: AppColors.accentEmerald,
            title: 'Understand yourself',
            subtitle: 'Analytics that reveal your listening identity.',
          ),
          const Spacer(flex: 3),
          _PrimaryButton(
            label: "Let's go",
            accent: accent,
            onTap: onContinue,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2 — AUTH OPTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _AuthOptionsPage extends StatelessWidget {
  const _AuthOptionsPage({
    required this.accent,
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogle,
    required this.onEmail,
    required this.onGuest,
  });

  final Color accent;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Choose how to\ncontinue',
            textAlign: TextAlign.center,
            style: AppTypography.displayMd.copyWith(
              color: context.appColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your music stays with you. No account required.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(flex: 2),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
            )
          else ...[
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Continue with Google',
              onTap: onGoogle,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.email_outlined,
              label: 'Continue with Email',
              onTap: onEmail,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: context.appColors.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: AppTypography.caption.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.appColors.borderSubtle)),
              ],
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Continue as Guest',
              accent: accent,
              onTap: onGuest,
            ),
          ],
          if (errorMessage != null && !isLoading) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.danger),
              ),
            ),
          ],
          const Spacer(flex: 1),
          Text(
            'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: context.appColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL AUTH BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EmailAuthSheet extends ConsumerStatefulWidget {
  const _EmailAuthSheet();

  @override
  ConsumerState<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends ConsumerState<_EmailAuthSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPassword(BuildContext context) async {
    final String email = _emailController.text.trim();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(prefillEmail: email),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_tabController.index == 0) {
      await ref.read(authProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } else {
      await ref.read(authProvider.notifier).createAccountWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    }

    if (!mounted) return;
    final s = ref.read(authProvider).valueOrNull;
    if (s is AuthSignedIn) {
      Navigator.of(context).pop();
    } else if (s is AuthError) {
      setState(() {
        _isLoading = false;
        _error = s.message;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.appColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTypography.titleSm,
                labelColor: AppColors.contrastingTextColor(accent),
                unselectedLabelColor: context.appColors.textSecondary,
                tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _tabController.index == 1
                        ? Column(
                            key: const ValueKey('nameField'),
                            children: [
                              _AuthTextField(
                                controller: _nameController,
                                hint: 'Display name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => (v == null || v.trim().length < 2)
                                    ? 'Name must be at least 2 characters'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('noNameField')),
                  ),
                  _AuthTextField(
                    controller: _emailController,
                    hint: 'Email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
                  ),
                  const SizedBox(height: 12),
                  _AuthTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    trailing: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: context.appColors.textTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),
                ],
              ),
            ),
            // "Forgot password?" link — Sign In tab only.
            if (!_isLoading && _tabController.index == 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPassword(context),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style:
                        AppTypography.bodySm.copyWith(color: accent),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              CircularProgressIndicator(strokeWidth: 2.5, color: accent)
            else
              _PrimaryButton(
                label: _tabController.index == 0 ? 'Sign In' : 'Create Account',
                accent: accent,
                onTap: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({this.prefillEmail = ''});

  /// Pre-fills the email field with whatever the user had typed in the
  /// sign-in form, so they don't have to type it again.
  final String prefillEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    // Check if an error was stored.
    final s = ref.read(authProvider).valueOrNull;
    if (s is AuthError) {
      setState(() {
        _isLoading = false;
        _error = s.message;
      });
    } else {
      // Treat everything else as success — we always show "check your inbox"
      // to avoid email enumeration.
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_sent) ...[
              // ── Success state ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_read_outlined,
                      color: accent, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                style: AppTypography.titleLg
                    .copyWith(color: context.appColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'If ${_emailController.text.trim()} is registered, '
                'you\'ll receive a password reset link shortly.',
                style: AppTypography.bodyMd
                    .copyWith(color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to Sign In',
                    style: AppTypography.bodyLg.copyWith(color: accent),
                  ),
                ),
              ),
            ] else ...[
              // ── Input state ────────────────────────────────────────────
              Text(
                'Reset your password',
                style: AppTypography.titleLg
                    .copyWith(color: context.appColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your email address and we\'ll send you a reset link.',
                style: AppTypography.bodyMd
                    .copyWith(color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: _AuthTextField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email address'
                      : null,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.bodySm.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.5, color: accent),
                )
              else
                _PrimaryButton(
                  label: 'Send Reset Link',
                  accent: accent,
                  onTap: _sendReset,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentIndex, required this.accent});
  final int count;
  final int currentIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final bool active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: active ? 20 : 6,
          height: 6,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? accent : context.appColors.borderMedium,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.titleSm
                      .copyWith(color: context.appColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTypography.bodySm
                      .copyWith(color: context.appColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.accent, required this.onTap});
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.contrastingTextColor(accent),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: AppTypography.titleSm),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: AppTypography.titleSm),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.appColors.textPrimary,
          side: BorderSide(color: context.appColors.borderMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.trailing,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? trailing;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTypography.bodyLg.copyWith(color: context.appColors.textPrimary),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyLg.copyWith(color: context.appColors.textTertiary),
        prefixIcon: Icon(icon, color: context.appColors.textTertiary, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: context.appColors.bgElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.appColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.appColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.danger.withValues(alpha: 0.70)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
      ),
    );
  }
}
