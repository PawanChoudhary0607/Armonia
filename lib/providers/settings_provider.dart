// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/constants/app_constants.dart';
import 'package:armonia/core/theme/app_colors.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = const Color(AppConstants.defaultAccentColorValue),
    this.streamingQuality = AppConstants.defaultStreamingQuality,
    this.downloadQuality = AppConstants.defaultDownloadQuality,
    this.crossfadeSeconds = AppConstants.defaultCrossfadeSeconds,
    this.dataSaverEnabled = false,
    this.streakNotificationsEnabled = true,
    this.badgeNotificationsEnabled = true,
    this.recapNotificationsEnabled = false,
    this.downloadSortKey = 'recent',
    this.libraryViewMode = 'list',
  });

  final ThemeMode themeMode;
  final Color accentColor;
  final String streamingQuality;
  final String downloadQuality;
  final int crossfadeSeconds;
  final bool dataSaverEnabled;
  final bool streakNotificationsEnabled;
  final bool badgeNotificationsEnabled;
  final bool recapNotificationsEnabled;
  final String downloadSortKey;
  final String libraryViewMode;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    String? streamingQuality,
    String? downloadQuality,
    int? crossfadeSeconds,
    bool? dataSaverEnabled,
    bool? streakNotificationsEnabled,
    bool? badgeNotificationsEnabled,
    bool? recapNotificationsEnabled,
    String? downloadSortKey,
    String? libraryViewMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
      streakNotificationsEnabled:
          streakNotificationsEnabled ?? this.streakNotificationsEnabled,
      badgeNotificationsEnabled:
          badgeNotificationsEnabled ?? this.badgeNotificationsEnabled,
      recapNotificationsEnabled:
          recapNotificationsEnabled ?? this.recapNotificationsEnabled,
      downloadSortKey: downloadSortKey ?? this.downloadSortKey,
      libraryViewMode: libraryViewMode ?? this.libraryViewMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          accentColor == other.accentColor &&
          streamingQuality == other.streamingQuality &&
          downloadQuality == other.downloadQuality &&
          crossfadeSeconds == other.crossfadeSeconds &&
          dataSaverEnabled == other.dataSaverEnabled &&
          streakNotificationsEnabled == other.streakNotificationsEnabled &&
          badgeNotificationsEnabled == other.badgeNotificationsEnabled &&
          recapNotificationsEnabled == other.recapNotificationsEnabled &&
          downloadSortKey == other.downloadSortKey &&
          libraryViewMode == other.libraryViewMode;

  @override
  int get hashCode => Object.hash(
        themeMode,
        accentColor,
        streamingQuality,
        downloadQuality,
        crossfadeSeconds,
        dataSaverEnabled,
        streakNotificationsEnabled,
        badgeNotificationsEnabled,
        recapNotificationsEnabled,
        downloadSortKey,
        libraryViewMode,
      );
}

/// Provides the app-wide [SharedPreferences] instance.
///
/// This MUST be overridden in `main.dart` with a value obtained via
/// `await SharedPreferences.getInstance()` *before* `runApp()` is called:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(
///   ProviderScope(
///     overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///     child: const ArmoniaApp(),
///   ),
/// );
/// ```
///
/// Reading this provider without overriding it is a programming error and
/// throws immediately, by design — it should never silently fall back to
/// an unpersisted in-memory instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider was not overridden. '
    'Override it in main.dart with the resolved SharedPreferences '
    'instance before calling runApp().',
  );
});

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;

  /// Synchronously builds the initial [SettingsState] by reading from
  /// [sharedPreferencesProvider].
  ///
  /// Because [sharedPreferencesProvider] is overridden with an already
  /// resolved [SharedPreferences] instance before `runApp()`, this `build()`
  /// method can read persisted values immediately on first construction.
  /// This avoids ever mutating `state` from outside the provider's own
  /// lifecycle (e.g. from a widget's `initState`), which is what previously
  /// caused the `!_dirty is not true` assertion during startup.
  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    final String themeString =
        _prefs.getString(AppConstants.prefThemeMode) ??
            AppConstants.defaultThemeMode;

    final int accentInt = _prefs.getInt(AppConstants.prefAccentColor) ??
        AppConstants.defaultAccentColorValue;

    return SettingsState(
      themeMode: _themeModeFromString(themeString),
      accentColor: Color(accentInt),
      streamingQuality:
          _prefs.getString(AppConstants.prefStreamingQuality) ??
              AppConstants.defaultStreamingQuality,
      downloadQuality:
          _prefs.getString(AppConstants.prefDownloadQuality) ??
              AppConstants.defaultDownloadQuality,
      crossfadeSeconds:
          _prefs.getInt(AppConstants.prefCrossfadeSeconds) ??
              AppConstants.defaultCrossfadeSeconds,
      dataSaverEnabled:
          _prefs.getBool(AppConstants.prefDataSaver) ?? false,
      streakNotificationsEnabled:
          _prefs.getBool(AppConstants.prefStreakNotifications) ?? true,
      badgeNotificationsEnabled:
          _prefs.getBool(AppConstants.prefBadgeNotifications) ?? true,
      recapNotificationsEnabled:
          _prefs.getBool(AppConstants.prefRecapNotifications) ?? false,
      downloadSortKey:
          _prefs.getString(AppConstants.prefDownloadSort) ?? 'recent',
      libraryViewMode:
          _prefs.getString(AppConstants.prefLibraryViewMode) ?? 'list',
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(AppConstants.prefThemeMode, _themeModeToString(mode));
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    _prefs.setInt(AppConstants.prefAccentColor, color.toARGB32());
  }

  void setStreamingQuality(String quality) {
    state = state.copyWith(streamingQuality: quality);
    _prefs.setString(AppConstants.prefStreamingQuality, quality);
  }

  void setDownloadQuality(String quality) {
    state = state.copyWith(downloadQuality: quality);
    _prefs.setString(AppConstants.prefDownloadQuality, quality);
  }

  void setCrossfadeSeconds(int seconds) {
    final int clamped = seconds.clamp(
      AppConstants.minCrossfadeSeconds,
      AppConstants.maxCrossfadeSeconds,
    );
    state = state.copyWith(crossfadeSeconds: clamped);
    _prefs.setInt(AppConstants.prefCrossfadeSeconds, clamped);
  }

  void toggleDataSaver() {
    final bool v = !state.dataSaverEnabled;
    state = state.copyWith(dataSaverEnabled: v);
    _prefs.setBool(AppConstants.prefDataSaver, v);
  }

  void toggleStreakNotifications() {
    final bool v = !state.streakNotificationsEnabled;
    state = state.copyWith(streakNotificationsEnabled: v);
    _prefs.setBool(AppConstants.prefStreakNotifications, v);
  }

  void toggleBadgeNotifications() {
    final bool v = !state.badgeNotificationsEnabled;
    state = state.copyWith(badgeNotificationsEnabled: v);
    _prefs.setBool(AppConstants.prefBadgeNotifications, v);
  }

  void toggleRecapNotifications() {
    final bool v = !state.recapNotificationsEnabled;
    state = state.copyWith(recapNotificationsEnabled: v);
    _prefs.setBool(AppConstants.prefRecapNotifications, v);
  }

  void setDownloadSortKey(String key) {
    state = state.copyWith(downloadSortKey: key);
    _prefs.setString(AppConstants.prefDownloadSort, key);
  }

  void setLibraryViewMode(String mode) {
    state = state.copyWith(libraryViewMode: mode);
    _prefs.setString(AppConstants.prefLibraryViewMode, mode);
  }

  List<Color> get accentPresets => AppColors.accentPresets;
  List<String> get accentPresetNames => AppColors.accentPresetNames;

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
