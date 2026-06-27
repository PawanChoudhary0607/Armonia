// lib/providers/auth_provider.dart
//
// Phase 6A — Authentication & User Accounts.
// Phase 6A.1 — Session persistence fix.
//
// Changes from Phase 6A:
//   • Fixed compile error: `lastLogin: () => DateTime.now().toUtc()` →
//     `lastLogin: DateTime.now().toUtc()`.
//   • Added `markOnboardingComplete()` — called by OnboardingScreen after
//     any successful auth choice. Delegates to AuthRepository.
//   • build() logic unchanged.
//
// ARCHITECTURE CONTRACTS:
//   • audio_provider, queue_provider, playlist_provider are UNTOUCHED.
//   • SplashScreen reads SharedPreferences directly (via AuthRepository
//     synchronous helpers) to avoid the AsyncNotifier race condition.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/data/models/user_model.dart';
import 'package:armonia/data/repositories/auth_repository.dart';
import 'package:armonia/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

/// The provider is initialising or an async operation is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A user is signed in. Covers both guest and authenticated accounts.
/// Use [user.isGuest] to distinguish them.
final class AuthSignedIn extends AuthState {
  const AuthSignedIn({required this.user});
  final UserModel user;
}

/// An authentication attempt failed. [message] is user-readable.
final class AuthError extends AuthState {
  const AuthError({required this.message, this.code});
  final String message;
  final String? code;
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;

  @override
  Future<AuthState> build() async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    _repository = AuthRepository(prefs: prefs);

    // Restore previously persisted session.
    final UserModel? restored = _repository.loadPersistedUser();

    if (restored != null) {
      // Refresh lastLogin timestamp silently.
      final UserModel refreshed = restored.copyWith(
        lastLogin: DateTime.now().toUtc(), // ← fixed: was `() => DateTime.now().toUtc()`
      );
      await _repository.persistUser(refreshed);
      debugPrint('[AuthProvider] Session restored: ${refreshed.accountType.name}');
      return AuthSignedIn(user: refreshed);
    }

    debugPrint('[AuthProvider] No session found.');
    return const AuthLoading();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  UserModel? get currentUser {
    final s = state.valueOrNull;
    if (s is AuthSignedIn) return s.user;
    return null;
  }

  bool get hasSession {
    final s = state.valueOrNull;
    return s is AuthSignedIn;
  }

  /// Marks onboarding as permanently complete in SharedPreferences.
  /// Called by OnboardingScreen after any successful auth choice.
  Future<void> markOnboardingComplete() async {
    await _repository.setOnboardingCompleted();
  }

  Future<void> continueAsGuest() async {
    state = const AsyncValue.data(AuthLoading());
    final AuthResult result = await _repository.signInAsGuest();
    if (result is AuthSuccess) {
      debugPrint('[AuthProvider] Guest session started: ${result.user.uid}');
      state = AsyncValue.data(AuthSignedIn(user: result.user));
    } else if (result is AuthFailure) {
      state = AsyncValue.data(
        AuthError(message: result.message, code: result.code),
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.data(AuthLoading());
    final AuthResult result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );
    _handleResult(result);
  }

  Future<void> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.data(AuthLoading());
    final AuthResult result = await _repository.createAccountWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    _handleResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.data(AuthLoading());
    final AuthResult result = await _repository.signInWithGoogle();
    _handleResult(result);
  }

  /// Sends a password reset email.
  ///
  /// On success: state is unchanged (user stays on the reset sheet).
  /// On failure: transitions to AuthError so the sheet can display the message.
  Future<void> sendPasswordResetEmail(String email) async {
    final AuthResult? result = await _repository.sendPasswordResetEmail(email);
    if (result is AuthFailure) {
      state = AsyncValue.data(
        AuthError(message: result.message, code: result.code),
      );
    }
    // On success (result == null): do nothing — the sheet handles UI.
  }

  /// Signs out the current user. Does NOT clear the onboarding flag.
  /// After sign-out the splash will go directly to the auth-options page
  /// (page 2 of onboarding) rather than the full welcome flow.
  Future<void> signOut() async {
    await _repository.signOut();
    debugPrint('[AuthProvider] User signed out.');
    state = const AsyncValue.data(AuthLoading());
  }

  void clearError() {
    if (state.valueOrNull is AuthError) {
      state = const AsyncValue.data(AuthLoading());
    }
  }

  void _handleResult(AuthResult result) {
    if (result is AuthSuccess) {
      debugPrint('[AuthProvider] Auth success: ${result.user.accountType.name}');
      state = AsyncValue.data(AuthSignedIn(user: result.user));
    } else if (result is AuthFailure) {
      debugPrint('[AuthProvider] Auth failure: ${result.message}');
      state = AsyncValue.data(
        AuthError(message: result.message, code: result.code),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
