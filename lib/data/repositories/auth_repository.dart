// lib/data/repositories/auth_repository.dart
//
// Phase 6B — Production Authentication (Supabase).
//
// What changed from Phase 6A:
//   • signInWithEmail()      — now calls SupabaseAuthService (was stub).
//   • createAccountWithEmail() — now calls SupabaseAuthService (was stub).
//   • signInWithGoogle()     — now calls SupabaseAuthService (was stub).
//   • signOut()              — now also calls SupabaseAuthService.signOut().
//   • Added sendPasswordResetEmail() — new public method.
//   • Added _fromServiceSuccess() — builds UserModel from AuthServiceSuccess.
//   • Added _startSessionRefreshListener() — keeps local cache in sync with
//     Supabase's background token refresh. Guest sessions are unaffected.
//
// What is UNCHANGED from Phase 6A:
//   • All SharedPreferences keys (_keyUser, _keyGuestUid, _keyOnboardingDone).
//   • hasOnboardingCompleted() / setOnboardingCompleted() / clearOnboardingCompleted().
//   • loadPersistedUserSync() / loadPersistedUser() / persistUser() / clearPersistedUser().
//   • signInAsGuest() — identical.
//   • AuthResult / AuthSuccess / AuthFailure sealed types.
//   • Guest UID generation (_generateUid / _getOrCreateGuestUid).
//
// ARCHITECTURE CONTRACT (unchanged from Phase 6A):
//   • auth_provider.dart depends on this repository — not the reverse.
//   • playlist_provider, audio_provider, queue_provider remain untouched.
//   • This file contains ZERO Flutter widgets.
//
// GUEST → AUTH MIGRATION STRATEGY
//   All user data (liked songs, playlists, recently played, search history,
//   settings) is stored in SharedPreferences under fixed keys that are NOT
//   namespaced by UID. When a guest signs in with Google or email, these keys
//   remain untouched. Only armonia_auth_user_v1 changes to the authenticated
//   UserModel. This preserves 100% of guest data with zero migration code.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/data/models/user_model.dart';
import 'package:armonia/data/repositories/supabase_auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RESULT TYPES (unchanged from Phase 6A — auth_provider.dart depends on these)
// ─────────────────────────────────────────────────────────────────────────────

sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess({required this.user});
  final UserModel user;
}

final class AuthFailure extends AuthResult {
  const AuthFailure({required this.message, this.code});
  final String message;
  final String? code;
}

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {
  AuthRepository({required SharedPreferences prefs}) : _prefs = prefs {
    // Start listening to Supabase's background session refresh events.
    // This ensures the local UserModel cache stays in sync when Supabase
    // refreshes an expired token silently in the background.
    _startSessionRefreshListener();
  }

  final SharedPreferences _prefs;
  StreamSubscription<AuthServiceSuccess?>? _supabaseSessionSub;

  // ── Keys ──────────────────────────────────────────────────────────────────

  static const String _keyUser = 'armonia_auth_user_v1';
  static const String _keyGuestUid = 'armonia_auth_guest_uid';

  /// Set to `true` the moment the user completes onboarding for the first
  /// time. Never cleared by sign-out — only by app-data wipe / reinstall.
  static const String _keyOnboardingDone = 'armonia_onboarding_done_v1';

  // ── Onboarding flag ───────────────────────────────────────────────────────

  bool hasOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_keyOnboardingDone, true);
  }

  Future<void> clearOnboardingCompleted() async {
    await _prefs.remove(_keyOnboardingDone);
  }

  // ── Session persistence ───────────────────────────────────────────────────

  /// Loads the persisted [UserModel] synchronously from SharedPreferences.
  ///
  /// Safe to call from SplashScreen's initState because SharedPreferences is
  /// resolved before runApp() in main.dart.
  UserModel? loadPersistedUserSync() {
    try {
      final String? raw = _prefs.getString(_keyUser);
      if (raw == null || raw.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AuthRepository] loadPersistedUserSync FAILED: $e');
      return null;
    }
  }

  /// Async alias kept for callers that run outside the splash context.
  UserModel? loadPersistedUser() => loadPersistedUserSync();

  Future<void> persistUser(UserModel user) async {
    try {
      await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('[AuthRepository] persistUser FAILED: $e');
    }
  }

  Future<void> clearPersistedUser() async {
    try {
      await _prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('[AuthRepository] clearPersistedUser FAILED: $e');
    }
  }

  // ── Guest sign-in ─────────────────────────────────────────────────────────

  Future<AuthResult> signInAsGuest() async {
    try {
      final String guestUid = _getOrCreateGuestUid();
      final UserModel user = UserModel.guest(guestUid: guestUid);
      await persistUser(user);
      return AuthSuccess(user: user);
    } catch (e) {
      return AuthFailure(message: 'Could not start guest session: $e');
    }
  }

  String _getOrCreateGuestUid() {
    final String? stored = _prefs.getString(_keyGuestUid);
    if (stored != null && stored.isNotEmpty) return stored;
    final String generated = _generateUid();
    _prefs.setString(_keyGuestUid, generated);
    return generated;
  }

  // ── Email sign-in ─────────────────────────────────────────────────────────

  /// Signs in with email + password using Supabase Auth.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final AuthServiceResult result =
        await SupabaseAuthService.instance.signInWithEmail(
      email: email,
      password: password,
    );
    return _fromServiceResult(result, AccountType.email);
  }

  // ── Email sign-up ─────────────────────────────────────────────────────────

  /// Creates a new account with email + password using Supabase Auth.
  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final AuthServiceResult result =
        await SupabaseAuthService.instance.createAccountWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _fromServiceResult(result, AccountType.email);
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  /// Signs in with Google using native picker → Supabase id_token exchange.
  Future<AuthResult> signInWithGoogle() async {
    final AuthServiceResult result =
        await SupabaseAuthService.instance.signInWithGoogle();
    return _fromServiceResult(result, AccountType.google);
  }

  // ── Password reset ────────────────────────────────────────────────────────

  /// Sends a password reset email. Returns null on success, AuthFailure on error.
  Future<AuthResult?> sendPasswordResetEmail(String email) async {
    final AuthServiceError? error =
        await SupabaseAuthService.instance.sendPasswordResetEmail(email);
    if (error == null) return null; // success
    return AuthFailure(message: error.message, code: error.code);
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  /// Signs out the current user.
  ///
  /// Calls Supabase sign-out (which also signs out from Google if applicable)
  /// then clears the locally persisted UserModel. The onboarding flag is NOT
  /// cleared — sign-out must not re-trigger the full welcome flow.
  Future<void> signOut() async {
    await SupabaseAuthService.instance.signOut();
    await clearPersistedUser();
    debugPrint('[AuthRepository] User signed out.');
  }

  // ── Session refresh listener ──────────────────────────────────────────────

  /// Listens to Supabase's auth state stream so that when the SDK silently
  /// refreshes an expired access token, our local UserModel cache is updated
  /// with the new session metadata.
  ///
  /// This prevents the edge case where the app restarts mid-session, the
  /// Supabase SDK refreshes the token, but the locally cached UserModel still
  /// has the old lastLogin timestamp.
  void _startSessionRefreshListener() {
    _supabaseSessionSub?.cancel();
    _supabaseSessionSub =
        SupabaseAuthService.instance.authStateChanges.listen(
      (AuthServiceSuccess? success) async {
        if (success == null) return;

        // Only update the cache if we already have a persisted authenticated
        // user (not a guest). This avoids accidentally overwriting a guest
        // session with a stale Supabase event.
        final UserModel? current = loadPersistedUserSync();
        if (current == null || current.isGuest) return;

        // Refresh lastLogin in the persisted model to match the new session.
        final UserModel refreshed = current.copyWith(
          lastLogin: DateTime.now().toUtc(),
          photoUrl: () => success.photoUrl ?? current.photoUrl,
        );
        await persistUser(refreshed);
        debugPrint('[AuthRepository] Session refreshed for ${refreshed.uid}');
      },
      onError: (Object e) {
        // Non-fatal — Supabase will retry the refresh automatically.
        debugPrint('[AuthRepository] Session refresh stream error: $e');
      },
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Converts an [AuthServiceResult] into an [AuthResult], persisting the
  /// [UserModel] on success.
  Future<AuthResult> _fromServiceResult(
    AuthServiceResult result,
    AccountType expectedType,
  ) async {
    switch (result) {
      case AuthServiceResultSuccess(:final value):
        final UserModel user = _fromServiceSuccess(value, expectedType);
        await persistUser(user);
        debugPrint('[AuthRepository] Auth success: '
            '${user.accountType.name} uid=${user.uid}');
        return AuthSuccess(user: user);

      case AuthServiceResultError(:final error):
        debugPrint('[AuthRepository] Auth error: '
            '${error.code} — ${error.message}');
        return AuthFailure(message: error.message, code: error.code);
    }
  }

  /// Builds a [UserModel] from an [AuthServiceSuccess].
  ///
  /// The [expectedType] is only used as a fallback; the actual provider
  /// reported by [AuthServiceSuccess.provider] takes precedence.
  UserModel _fromServiceSuccess(
    AuthServiceSuccess success,
    AccountType expectedType,
  ) {
    final AccountType accountType =
        success.provider == AuthServiceProvider.google
            ? AccountType.google
            : AccountType.email;

    // If there is already a persisted user for this UID, preserve createdAt.
    final UserModel? existing = loadPersistedUserSync();
    final DateTime createdAt =
        (existing != null && existing.uid == success.uid)
            ? existing.createdAt
            : DateTime.now().toUtc();

    return UserModel(
      uid: success.uid,
      displayName: success.displayName,
      email: success.email,
      photoUrl: success.photoUrl,
      accountType: accountType,
      createdAt: createdAt,
      lastLogin: DateTime.now().toUtc(),
    );
  }

  static String _generateUid() {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}'
        '-${bytes.sublist(4, 6).map(hex).join()}'
        '-${bytes.sublist(6, 8).map(hex).join()}'
        '-${bytes.sublist(8, 10).map(hex).join()}'
        '-${bytes.sublist(10, 16).map(hex).join()}';
  }
}
