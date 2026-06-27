// lib/data/repositories/supabase_auth_service.dart
//
// Phase 6B — Production Authentication (Supabase).
//
// PURPOSE
// -------
// This service is the ONLY file in the codebase that imports the Supabase
// SDK. It exposes a clean, Dart-only API to AuthRepository so the rest of
// the app remains completely decoupled from Supabase's types.
//
// RESPONSIBILITIES
// ----------------
//   • Initialize Supabase (called once from main.dart).
//   • Sign in / sign up / sign out via Supabase Auth.
//   • Google Sign-In OAuth flow (id_token → Supabase).
//   • Password reset email dispatch.
//   • Session restoration and background token refresh.
//   • Mapping Supabase errors → human-readable messages.
//
// WHAT THIS FILE DOES NOT DO
// --------------------------
//   • No Firestore / Firebase calls.
//   • No SharedPreferences reads/writes (that belongs to AuthRepository).
//   • No widget imports.
//   • No routing.
//
// ERROR CODES
// -----------
// AuthServiceError codes are stable strings that AuthRepository translates
// into user-friendly messages. Keeping codes separate from messages means
// messages can be internationalised without touching this service.

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RESULT TYPES (Supabase-free — safe to import anywhere)
// ─────────────────────────────────────────────────────────────────────────────

/// Successful authentication result from Supabase.
///
/// Contains the minimum data AuthRepository needs to construct a [UserModel].
/// No Supabase types leak beyond this file.
final class AuthServiceSuccess {
  const AuthServiceSuccess({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.provider,
  });

  /// Supabase user UUID — used as the stable primary key.
  final String uid;

  /// Email from the Supabase auth record. Never null for email/google flows.
  final String? email;

  /// Display name. Sourced from Google profile or user metadata.
  final String displayName;

  /// Avatar URL. Populated for Google sign-in only.
  final String? photoUrl;

  /// Which provider authenticated this user.
  final AuthServiceProvider provider;
}

/// Authentication failure from Supabase.
final class AuthServiceError {
  const AuthServiceError({required this.message, required this.code});

  /// User-facing message (already translated from Supabase exception).
  final String message;

  /// Stable error code for programmatic handling.
  final String code;
}

/// Which auth provider was used.
enum AuthServiceProvider { email, google }

/// Tagged-union result returned by all auth methods.
sealed class AuthServiceResult {
  const AuthServiceResult();
}

final class AuthServiceResultSuccess extends AuthServiceResult {
  const AuthServiceResultSuccess(this.value);
  final AuthServiceSuccess value;
}

final class AuthServiceResultError extends AuthServiceResult {
  const AuthServiceResultError(this.error);
  final AuthServiceError error;
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseAuthService {
  SupabaseAuthService._();

  static final SupabaseAuthService instance = SupabaseAuthService._();

  // Google Sign-In client. The serverClientId is the OAuth 2.0 Web Client ID
  // from the Google Cloud Console — required for id_token retrieval on Android.
  // On iOS the clientId is read automatically from GoogleService-Info.plist.
  static const String _googleWebClientId =
      '1095909898907-3ns4dega2aod745gn6imgp5mb29a7r43.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Must be called from main.dart BEFORE runApp().
  ///
  /// ```dart
  /// await SupabaseAuthService.instance.initialize(
  ///   supabaseUrl: 'https://your-project.supabase.co',
  ///   supabaseAnonKey: 'your-anon-key',
  /// );
  /// ```
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // authOptions configures automatic session refresh and persistence.
      // Supabase stores the session in secure storage on the device.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _googleSignIn = GoogleSignIn(
      serverClientId: _googleWebClientId,
      scopes: ['email', 'profile'],
    );

    debugPrint('[SupabaseAuthService] Initialized. '
        'User: ${_client.auth.currentUser?.id ?? 'none'}');
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Session restoration ─────────────────────────────────────────────────

  /// Returns the current Supabase session user, if one exists.
  ///
  /// Supabase persists and automatically refreshes sessions using its own
  /// secure storage. Calling this after [initialize] is synchronous.
  AuthServiceSuccess? get currentUser {
    final User? user = _client.auth.currentUser;
    if (user == null) return null;
    return _toSuccess(user);
  }

  /// Stream that emits whenever Supabase auth state changes (sign-in,
  /// sign-out, token refresh). AuthRepository can listen to this to keep
  /// the persisted [UserModel] in sync with the live Supabase session.
  Stream<AuthServiceSuccess?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final User? user = data.session?.user;
      if (user == null) return null;
      return _toSuccess(user);
    });
  }

  // ── Email sign-in ───────────────────────────────────────────────────────

  /// Signs in with email + password via Supabase Auth.
  Future<AuthServiceResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final User? user = response.user;
      if (user == null) {
        return const AuthServiceResultError(
          AuthServiceError(
            message: 'Sign-in failed. Please try again.',
            code: 'no_user_returned',
          ),
        );
      }
      return AuthServiceResultSuccess(_toSuccess(user));
    } on AuthException catch (e, st) {
      debugPrint('─── [AUTH DEBUG] signInWithEmail ───────────────────────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  message     : ${e.message}');
      debugPrint('  statusCode  : ${e.statusCode}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_mapAuthException(e));
    } catch (e, st) {
      debugPrint('─── [AUTH DEBUG] signInWithEmail unexpected ────────────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_unknownError(e));
    }
  }

  // ── Email sign-up ───────────────────────────────────────────────────────

  /// Creates a new account with email + password via Supabase Auth.
  ///
  /// Stores [displayName] in Supabase user metadata so it is retrievable
  /// without a separate database table.
  Future<AuthServiceResult> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'display_name': displayName,
          'full_name': displayName,
        },
      );
      final User? user = response.user;
      if (user == null) {
        return const AuthServiceResultError(
          AuthServiceError(
            message: 'Account creation failed. Please try again.',
            code: 'no_user_returned',
          ),
        );
      }
      return AuthServiceResultSuccess(_toSuccess(user));
    } on AuthException catch (e, st) {
      debugPrint('─── [AUTH DEBUG] createAccountWithEmail ────────────────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  message     : ${e.message}');
      debugPrint('  statusCode  : ${e.statusCode}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_mapAuthException(e));
    } catch (e, st) {
      debugPrint('─── [AUTH DEBUG] createAccountWithEmail unexpected ──────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_unknownError(e));
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────

  /// Initiates Google Sign-In and exchanges the id_token with Supabase.
  ///
  /// Flow:
  ///   1. google_sign_in presents the native Google picker.
  ///   2. We retrieve the id_token from the GoogleSignInAuthentication object.
  ///   3. We pass the id_token to Supabase, which creates or updates the
  ///      user and issues a Supabase session.
  ///
  /// This approach avoids any browser redirect on mobile — the entire flow
  /// stays in-app, which is critical for a smooth UX.
  Future<AuthServiceResult> signInWithGoogle() async {
    try {
      // Step 1: Native Google picker.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User dismissed the picker — not an error, just cancellation.
        return const AuthServiceResultError(
          AuthServiceError(
            message: 'Google sign-in was cancelled.',
            code: 'google_sign_in_cancelled',
          ),
        );
      }

      // Step 2: Retrieve id_token from Google.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        return const AuthServiceResultError(
          AuthServiceError(
            message: 'Could not retrieve Google credentials. Please try again.',
            code: 'google_id_token_null',
          ),
        );
      }

      // Step 3: Exchange with Supabase.
      final AuthResponse response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final User? user = response.user;
      if (user == null) {
        return const AuthServiceResultError(
          AuthServiceError(
            message: 'Google sign-in failed. Please try again.',
            code: 'no_user_returned',
          ),
        );
      }
      return AuthServiceResultSuccess(_toSuccess(user));
    } on AuthException catch (e, st) {
      debugPrint('─── [AUTH DEBUG] signInWithGoogle ──────────────────────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  message     : ${e.message}');
      debugPrint('  statusCode  : ${e.statusCode}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_mapAuthException(e));
    } catch (e, st) {
      debugPrint('─── [AUTH DEBUG] signInWithGoogle unexpected ───────────');
      debugPrint('  runtimeType : ${e.runtimeType}');
      debugPrint('  toString    : ${e.toString()}');
      debugPrint('  stackTrace  :\n$st');
      debugPrint('────────────────────────────────────────────────────────');
      return AuthServiceResultError(_unknownError(e));
    }
  }

  // ── Password reset ──────────────────────────────────────────────────────

  /// Sends a password reset email via Supabase Auth.
  ///
  /// Returns `null` on success, or an [AuthServiceError] on failure.
  Future<AuthServiceError?> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return _mapAuthException(e);
    } catch (e) {
      debugPrint('[SupabaseAuthService] sendPasswordResetEmail unexpected: $e');
      return _unknownError(e);
    }
  }

  // ── Sign-out ────────────────────────────────────────────────────────────

  /// Signs out from Supabase and, if applicable, from Google.
  Future<void> signOut() async {
    try {
      // Sign out from Google if that was the sign-in method.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _client.auth.signOut();
    } catch (e) {
      // Sign-out errors are non-fatal — log and continue.
      debugPrint('[SupabaseAuthService] signOut error (non-fatal): $e');
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Converts a Supabase [User] into an [AuthServiceSuccess].
  ///
  /// Display name priority:
  ///   1. user_metadata['display_name'] — set during createAccountWithEmail
  ///   2. user_metadata['full_name']    — populated by Google OAuth
  ///   3. user_metadata['name']         — fallback from Google
  ///   4. email prefix                  — last resort
  AuthServiceSuccess _toSuccess(User user) {
    final Map<String, dynamic> meta =
        (user.userMetadata ?? <String, dynamic>{});

    final String displayName = (meta['display_name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        _emailPrefix(user.email);

    final String? photoUrl = meta['avatar_url'] as String? ??
        meta['picture'] as String?;

    final AuthServiceProvider provider =
        user.appMetadata['provider'] == 'google'
            ? AuthServiceProvider.google
            : AuthServiceProvider.email;

    return AuthServiceSuccess(
      uid: user.id,
      email: user.email,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider,
    );
  }

  String _emailPrefix(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final int at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  /// Maps Supabase [AuthException] to a user-friendly [AuthServiceError].
  ///
  /// Supabase error messages can be technical or inconsistent across SDK
  /// versions. We translate them here to stable, readable messages.
  AuthServiceError _mapAuthException(AuthException e) {
    final String msg = e.message.toLowerCase();
    debugPrint('[SupabaseAuthService] AuthException: ${e.message} '
        '(statusCode: ${e.statusCode})');

    // Network / connectivity
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return const AuthServiceError(
        message: 'No internet connection. Please check your network and retry.',
        code: 'network_error',
      );
    }

    // Invalid credentials
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password') ||
        msg.contains('incorrect password')) {
      return const AuthServiceError(
        message: 'Incorrect email or password.',
        code: 'invalid_credentials',
      );
    }

    // Email not confirmed
    if (msg.contains('email not confirmed') ||
        msg.contains('email confirmation')) {
      return const AuthServiceError(
        message:
            'Please confirm your email address before signing in. '
            'Check your inbox for a confirmation link.',
        code: 'email_not_confirmed',
      );
    }

    // Email already registered
    if (msg.contains('user already registered') ||
        msg.contains('already exists') ||
        msg.contains('already been registered')) {
      return const AuthServiceError(
        message: 'An account with this email already exists. '
            'Try signing in instead.',
        code: 'email_already_exists',
      );
    }

    // Weak password
    if (msg.contains('password') && msg.contains('weak')) {
      return const AuthServiceError(
        message: 'Password is too weak. Use at least 6 characters.',
        code: 'weak_password',
      );
    }

    // Invalid email format
    if (msg.contains('invalid email') || msg.contains('email is invalid')) {
      return const AuthServiceError(
        message: 'Please enter a valid email address.',
        code: 'invalid_email',
      );
    }

    // Rate limit
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        e.statusCode == '429') {
      return const AuthServiceError(
        message: 'Too many attempts. Please wait a moment and try again.',
        code: 'rate_limit',
      );
    }

    // Session expired
    if (msg.contains('session') && msg.contains('expired')) {
      return const AuthServiceError(
        message: 'Your session has expired. Please sign in again.',
        code: 'session_expired',
      );
    }

    // Generic fallback — include a sanitised version of the Supabase message
    // for debuggability without leaking raw stack traces.
    return AuthServiceError(
      message: 'Authentication failed. Please try again.',
      code: 'supabase_error_${e.statusCode ?? 'unknown'}',
    );
  }

  AuthServiceError _unknownError(Object e) {
    return AuthServiceError(
      message: 'An unexpected error occurred. Please try again.',
      code: 'unknown_${e.runtimeType}',
    );
  }
}
