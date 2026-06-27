// lib/core/utils/thumbnail_utils.dart

abstract final class ThumbnailUtils {
  /// Highest quality thumbnail URL.
  static String highQuality(String url) =>
      _replaceResolution(url, 'maxresdefault');

  /// Medium quality thumbnail (480×360).
  static String mediumQuality(String url) =>
      _replaceResolution(url, 'hqdefault');

  /// Small quality thumbnail (120×90).
  static String smallQuality(String url) =>
      _replaceResolution(url, 'default');

  /// Strip query parameters from a YouTube thumbnail URL.
  static String clean(String url) {
    if (url.isEmpty) return url;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: {}).toString();
  }

  /// Extract video ID from a YouTube thumbnail URL.
  static String? extractVideoId(String thumbnailUrl) {
    final RegExpMatch? match =
        RegExp(r'/vi(?:_webp)?/([^/]+)/').firstMatch(thumbnailUrl);
    return match?.group(1);
  }

  static String _replaceResolution(String url, String resolution) {
    if (url.isEmpty) return url;
    return url.replaceAll(
      RegExp(
        r'(maxresdefault|hqdefault|mqdefault|sddefault|default)\.(jpg|webp)',
      ),
      '$resolution.jpg',
    );
  }
}
