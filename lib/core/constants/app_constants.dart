// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'Armonia';
  static const String appVersion = '1.0.0';

  // Playback
  static const int statsThresholdSeconds = 30;
  static const int maxAutoSkipAttempts = 3;
  static const int queueRefillThreshold = 7;
  static const int maxHistorySize = 50;

  // Crossfade
  static const int minCrossfadeSeconds = 0;
  static const int maxCrossfadeSeconds = 12;

  // Search
  static const int searchDebounceSuggestionMs = 200;
  static const int searchDebounceFullMs = 550;
  static const int maxSearchHistoryItems = 20;

  // SQLite
  static const int maxSQLiteHistoryRows = 100;

  // Lists
  static const int maxRecentlyPlayedItems = 20;
  static const int maxUserPlaylists = 50;
  static const int maxPlaylistSongs = 500;

  // UI
  static const double bottomNavHeight = 64.0;
  static const double miniPlayerHeight = 64.0;
  static const double playerAlbumArtSize = 240.0;

  // Streak milestones
  static const List<int> streakMilestones = [7, 21, 60];

  // SharedPreferences keys
  static const String prefThemeMode = 'armonia_theme_mode';
  static const String prefAccentColor = 'armonia_accent_color_int';
  static const String prefStreamingQuality = 'armonia_streaming_quality';
  static const String prefDownloadQuality = 'armonia_download_quality';
  static const String prefCrossfadeSeconds = 'armonia_crossfade_seconds';
  static const String prefDataSaver = 'armonia_data_saver';
  static const String prefStreakNotifications = 'armonia_notif_streak';
  static const String prefBadgeNotifications = 'armonia_notif_badges';
  static const String prefRecapNotifications = 'armonia_notif_recap';
  static const String prefDownloadSort = 'armonia_dl_sort_key';
  static const String prefLibraryViewMode = 'armonia_lib_view_mode';
  static const String prefSearchHistory = 'armonia_search_history';
  static const String prefOnboardingDone = 'armonia_onboarding_done';
  static const String prefFavorites = 'armonia_favorites';
  static const String prefRecentlyPlayed = 'armonia_recently_played';

  // Phase 5A Recovery — new persistence keys
  static const String prefUserPlaylists = 'armonia_user_playlists';
  static const String prefLikedSongs = 'armonia_liked_songs';

  // Phase 6A — Auth persistence (see AuthRepository for full key list)
  // These constants are declared here as documentation of the key namespace.
  // AuthRepository uses its own private constants to keep auth isolation clean.
  static const String prefOnboardingSeen = 'armonia_onboarding_seen_v1';

  // Defaults
  static const int defaultAccentColorValue = 0xFF22D3EE;
  static const String defaultThemeMode = 'dark';
  static const String defaultStreamingQuality = 'high';
  static const String defaultDownloadQuality = 'high';
  static const int defaultCrossfadeSeconds = 0;
}
