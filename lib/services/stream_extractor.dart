// lib/services/stream_extractor.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Thrown when [StreamExtractor] cannot resolve a playable audio stream URL
/// for a given YouTube video ID.
class StreamExtractionException implements Exception {
  const StreamExtractionException(this.message);

  final String message;

  @override
  String toString() => 'StreamExtractionException: $message';
}

/// Per-client timeout for [YoutubeExplode.videos.streams.getManifest].
///
/// `getManifest` can hang indefinitely (no internal timeout) if a given
/// YouTube client's request stalls on-device. Each client is given this
/// long before being abandoned in favor of the next.
const Duration _kManifestTimeout = Duration(seconds: 15);

/// Resolves a YouTube video ID into a direct, playable CDN audio stream URL
/// using `youtube_explode_dart` (PINNED at 2.5.3 — never upgrade to v3,
/// which requires a `deno` runtime unavailable on Android).
///
/// This runs entirely on-device with no backend server.
class StreamExtractor {
  const StreamExtractor();

  /// The YouTube API clients to attempt, in order. Each is tried with
  /// [_kManifestTimeout]; on failure or timeout, the next client is tried.
  static final List<YoutubeApiClient> _clientsInOrder = [
    YoutubeApiClient.ios,
    YoutubeApiClient.safari,
    YoutubeApiClient.androidVr,
  ];

  /// Returns a direct audio stream URL for [videoId].
  ///
  /// Tries each client in [_clientsInOrder] sequentially, each bounded by
  /// [_kManifestTimeout]. The first client that successfully returns a
  /// manifest is used to select the stream. If every client fails or times
  /// out, throws [StreamExtractionException] listing the failure reason for
  /// each client.
  ///
  /// Prefers an audio-only stream with an `audio/mp4` (m4a) mime type,
  /// falling back to the highest-bitrate audio-only stream of any codec,
  /// and finally to a muxed stream if no audio-only stream is available.
  Future<String> getAudioStreamUrl(String videoId) async {
    final Map<String, String> clientFailures = {};

    for (final YoutubeApiClient client in _clientsInOrder) {
      final String clientName = client.toString();

      debugPrint(
        '[StreamExtractor] manifest fetch started '
        '(videoId=$videoId, client=$clientName, '
        'timeout=${_kManifestTimeout.inSeconds}s)',
      );

      final YoutubeExplode yt = YoutubeExplode();

      try {
        final StreamManifest manifest = await yt.videos.streams
            .getManifest(videoId, ytClients: [client])
            .timeout(_kManifestTimeout);

        debugPrint(
          '[StreamExtractor] manifest fetch success (client=$clientName)',
        );

        final String? selectedUrl = _selectStreamUrl(manifest);

        if (selectedUrl != null) {
          debugPrint(
            '[StreamExtractor] resolved URL via client=$clientName: '
            '$selectedUrl',
          );
          return selectedUrl;
        }

        debugPrint(
          '[StreamExtractor] client=$clientName returned a manifest with '
          'no audio-only or muxed streams',
        );
        clientFailures[clientName] =
            'manifest returned no audio-only or muxed streams';
      } on TimeoutException catch (e) {
        debugPrint(
          '[StreamExtractor] manifest fetch TIMED OUT after '
          '${_kManifestTimeout.inSeconds}s (client=$clientName): $e',
        );
        clientFailures[clientName] =
            'timed out after ${_kManifestTimeout.inSeconds}s';
      } catch (e, stackTrace) {
        debugPrint(
          '[StreamExtractor] manifest fetch FAILED (client=$clientName): $e',
        );
        debugPrint('[StreamExtractor] STACK TRACE: $stackTrace');
        clientFailures[clientName] = e.toString();
      } finally {
        yt.close();
      }

      debugPrint(
        '[StreamExtractor] falling back to next client after '
        '$clientName failed',
      );
    }

    final String summary = clientFailures.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ');

    debugPrint(
      '[StreamExtractor] ALL CLIENTS FAILED (videoId=$videoId): $summary',
    );

    throw StreamExtractionException(
      'Failed to extract stream for "$videoId" — all clients failed. '
      '$summary',
    );
  }

  /// Selects the best stream URL from [manifest], or `null` if no usable
  /// stream exists.
  String? _selectStreamUrl(StreamManifest manifest) {
    final List<AudioOnlyStreamInfo> audioStreams =
        manifest.audioOnly.toList();

    debugPrint('[StreamExtractor] audio stream count: ${audioStreams.length}');

    if (audioStreams.isNotEmpty) {
      // Prefer m4a (audio/mp4) streams — best compatibility with
      // just_audio across Android and iOS.
      final List<AudioOnlyStreamInfo> m4aStreams = audioStreams
          .where((s) => s.codec.mimeType.contains('audio/mp4'))
          .toList();

      final List<AudioOnlyStreamInfo> candidates =
          m4aStreams.isNotEmpty ? m4aStreams : audioStreams;

      candidates.sort(
        (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
      );

      final String selectedUrl = candidates.first.url.toString();
      debugPrint('[StreamExtractor] selected stream URL (audio-only): $selectedUrl');
      return selectedUrl;
    }

    // No audio-only stream — fall back to the highest quality muxed
    // stream (contains both audio and video).
    final List<MuxedStreamInfo> muxedStreams = manifest.muxed.toList();
    debugPrint('[StreamExtractor] muxed stream count: ${muxedStreams.length}');

    if (muxedStreams.isNotEmpty) {
      muxedStreams.sort(
        (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
      );
      final String selectedUrl = muxedStreams.first.url.toString();
      debugPrint('[StreamExtractor] selected stream URL (muxed): $selectedUrl');
      return selectedUrl;
    }

    return null;
  }
}
