// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  // YouTube Music InnerTube
  static const String innerTubeBaseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String innerTubeApiKey =
      'AIzaSyC9XL3ZjWddXya6X74dJoCTL-KLET5YdWk';
  static const String innerTubeClientName = 'WEB_REMIX';
  static const String innerTubeClientVersion = '1.20240101.01.00';
  static const String innerTubeLanguage = 'en';

  // InnerTube endpoints
  static const String endpointSearch = 'search';
  static const String endpointBrowse = 'browse';
  static const String endpointSuggestions = 'music/get_search_suggestions';
  static const String endpointNext = 'next';

  // InnerTube browse IDs
  static const String browseHome = 'FEmusic_home';
  static const String browseTrending = 'FEmusic_trending';

  // InnerTube search type filters
  static const String filterSongs = 'EgWKAQIIAWoKEAkQBRAKEAMQBA==';
  static const String filterArtists = 'EgWKAQIgAWoKEAkQBRAKEAMQBA==';
  static const String filterAlbums = 'EgWKAQIYAWoKEAkQBRAKEAMQBA==';

  // lrclib lyrics
  static const String lrclibBaseUrl = 'https://lrclib.net/api';

  // Timeouts (ms)
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;

  // User agent
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';
}
