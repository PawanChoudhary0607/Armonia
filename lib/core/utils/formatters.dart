// lib/core/utils/formatters.dart

abstract final class Formatters {
  /// Duration to mm:ss or h:mm:ss string.
  static String duration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${_pad(m)}:${_pad(s)}';
    return '$m:${_pad(s)}';
  }

  /// Total seconds to duration string.
  static String seconds(int totalSeconds) =>
      duration(Duration(seconds: totalSeconds));

  /// Byte count to human-readable size.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Total seconds to listening time string. e.g. "14h 22m"
  static String listeningTime(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// DateTime to 'YYYY-MM-DD' string.
  static String dateKey(DateTime date) =>
      '${date.year}-${_pad(date.month)}-${_pad(date.day)}';

  /// Today's date key.
  static String todayKey() => dateKey(DateTime.now());

  /// Yesterday's date key.
  static String yesterdayKey() =>
      dateKey(DateTime.now().subtract(const Duration(days: 1)));

  /// Sanitise artist name for use as a Firestore document ID.
  static String artistKey(String artistName) => artistName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  /// Time-of-day greeting for a given hour (0–23).
  static String greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Current time-of-day greeting.
  static String currentGreeting() => greeting(DateTime.now().hour);

  /// Large integer to compact display string.
  static String compactNumber(int value) {
    if (value < 1000) return value.toString();
    if (value < 1000000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
