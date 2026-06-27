// lib/data/models/user_model.dart
//
// Phase 6A — Authentication & User Accounts.
//
// Scalable user model designed to accommodate every planned future phase
// without requiring a data-layer rewrite:
//   • Cloud Sync (Phase 6B)  — uid field already present
//   • Public Profiles        — displayName + photoUrl
//   • Collaborative features — uid is the join key
//   • Premium / Payments     — accountType field with extensible enum
//   • Analytics Sync         — createdAt / lastLogin timestamps
//
// This model is intentionally pure Dart (no Firebase SDK imports) so the
// auth repository is the only layer that knows how Firebase stores things.

import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// The type of account the user holds.
///
/// [guest]  — No credentials; a device-local UUID is generated. This user can
///             use the app fully but data is not synced to any cloud.
/// [email]  — Email + password authentication (local or cloud, phase-dependent).
/// [google] — OAuth via Google Sign-In.
///
/// Future values (do NOT add until the relevant phase ships):
///   premium, family, student
enum AccountType {
  guest,
  email,
  google;

  /// Canonical string stored in SharedPreferences.
  String toJson() => name;

  static AccountType fromJson(String value) {
    switch (value) {
      case 'email':
        return AccountType.email;
      case 'google':
        return AccountType.google;
      case 'guest':
      default:
        return AccountType.guest;
    }
  }

  /// Human-readable label shown in the Profile screen.
  String get displayLabel {
    switch (this) {
      case AccountType.guest:
        return 'Guest';
      case AccountType.email:
        return 'Email account';
      case AccountType.google:
        return 'Google account';
    }
  }

  bool get isGuest => this == AccountType.guest;
  bool get isAuthenticated => !isGuest;
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable representation of the signed-in (or guest) user.
///
/// All fields that may be absent for a guest account are nullable. The model
/// carries no Firebase-specific types — it is a plain Dart value object that
/// can be serialised to/from JSON (stored in SharedPreferences) and later
/// serialised to/from Firestore documents without changing this class.
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.accountType,
    required this.createdAt,
    required this.lastLogin,
    this.email,
    this.photoUrl,
  });

  /// Unique identifier.
  ///
  /// For [AccountType.guest]  → a UUID-like string generated locally on first
  ///                           launch and stored in SharedPreferences.
  /// For [AccountType.email]  → the Firebase Auth UID.
  /// For [AccountType.google] → the Firebase Auth UID (== Google UID).
  ///
  /// This field is the stable primary key that will be used as the Firestore
  /// document ID in Phase 6B.
  final String uid;

  /// The user's chosen display name.
  ///
  /// For guests: defaults to 'Guest'.
  /// For Google accounts: pre-populated from the Google profile.
  /// For email accounts: supplied by the user during sign-up.
  final String displayName;

  /// Email address. Null for guest accounts.
  final String? email;

  /// URL of the user's avatar image. Null when not set.
  ///
  /// Phase 6A: not editable — sourced from Google profile only.
  /// Future phases: uploadable to Firebase Storage → stored as a URL here.
  final String? photoUrl;

  /// How the user authenticated.
  final AccountType accountType;

  /// UTC timestamp of account creation (or first guest launch).
  final DateTime createdAt;

  /// UTC timestamp of the most recent successful authentication.
  final DateTime lastLogin;

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool get isGuest => accountType.isGuest;
  bool get isAuthenticated => accountType.isAuthenticated;

  /// Returns `true` when the user has a usable display name that is not the
  /// bare default placeholder. Used to decide whether the Profile screen shows
  /// the edit hint.
  bool get hasCustomDisplayName =>
      displayName.isNotEmpty && displayName != 'Guest';

  // ── copyWith ───────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? Function()? email,
    String? Function()? photoUrl,
    AccountType? accountType,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      // Nullable fields use a function-wrapped pattern so that callers can
      // explicitly set them to null via `email: () => null`.
      email: email != null ? email() : this.email,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// Serialises to a JSON-safe map for SharedPreferences storage.
  ///
  /// All values are primitives (String, int, bool) so `jsonEncode()` works
  /// without a custom encoder. This same structure will be written to
  /// Firestore in Phase 6B with only the `FieldValue.serverTimestamp()`
  /// replacement for the timestamp fields.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'accountType': accountType.toJson(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastLogin': lastLogin.millisecondsSinceEpoch,
      };

  /// Deserialises from a JSON map (SharedPreferences or Firestore document).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Guest',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accountType: AccountType.fromJson(
        json['accountType'] as String? ?? 'guest',
      ),
      createdAt: _dateFromMs(json['createdAt']),
      lastLogin: _dateFromMs(json['lastLogin']),
    );
  }

  // ── Factory constructors ───────────────────────────────────────────────────

  /// Creates a new guest user with a locally generated ID.
  ///
  /// The [guestUid] should be generated once, persisted to SharedPreferences,
  /// and reused across app restarts so that guest data is stable.
  factory UserModel.guest({required String guestUid}) {
    final now = DateTime.now().toUtc();
    return UserModel(
      uid: guestUid,
      displayName: 'Guest',
      accountType: AccountType.guest,
      createdAt: now,
      lastLogin: now,
    );
  }

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.accountType == accountType &&
        other.createdAt == createdAt &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        displayName,
        email,
        photoUrl,
        accountType,
        createdAt,
        lastLogin,
      );

  @override
  String toString() =>
      'UserModel(uid: $uid, displayName: $displayName, '
      'accountType: ${accountType.name}, email: $email)';

  // ── Private helpers ────────────────────────────────────────────────────────

  static DateTime _dateFromMs(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value).toUtc();
    return DateTime.now().toUtc();
  }
}
