// lib/providers/search_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/services/music_search_service.dart';

/// Immutable search state exposed to the UI.
@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.results = const <Song>[],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
  });

  final String query;
  final List<Song> results;
  final bool isLoading;

  /// True once at least one search has been submitted — used to
  /// distinguish "haven't searched yet" from "searched, zero results".
  final bool hasSearched;

  final String? error;

  SearchState copyWith({
    String? query,
    List<Song>? results,
    bool? isLoading,
    bool? hasSearched,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provides the singleton [MusicSearchService] used to resolve search
/// results from YouTube.
final musicSearchServiceProvider = Provider<MusicSearchService>((ref) {
  return const MusicSearchService();
});

/// Manages search query state, debouncing, and results for the Search
/// screen.
///
/// Search is debounced by 500ms after the last keystroke. A monotonically
/// increasing search id guards against a stale (superseded) search
/// overwriting results from a newer one.
class SearchNotifier extends Notifier<SearchState> {
  late final MusicSearchService _service;
  Timer? _debounce;
  int _searchId = 0;

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  SearchState build() {
    _service = ref.read(musicSearchServiceProvider);

    ref.onDispose(() {
      _debounce?.cancel();
    });

    return const SearchState();
  }

  /// Updates the query text and schedules a debounced search.
  ///
  /// If [text] is blank, results are cleared immediately without a network
  /// call.
  void setQuery(String text) {
    state = state.copyWith(query: text, clearError: true);

    _debounce?.cancel();

    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        results: const <Song>[],
        isLoading: false,
        hasSearched: false,
        clearError: true,
      );
      return;
    }

    _debounce = Timer(_debounceDuration, () => _performSearch(trimmed));
  }

  /// Immediately runs a search for the current query, bypassing the
  /// debounce (e.g. when the user presses the search/enter key).
  Future<void> submit() async {
    _debounce?.cancel();
    final String trimmed = state.query.trim();
    if (trimmed.isEmpty) return;
    await _performSearch(trimmed);
  }

  Future<void> _performSearch(String query) async {
    final int id = ++_searchId;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Song> songs = await _service.search(query);

      // A newer search superseded this one — discard our result.
      if (id != _searchId) return;

      state = state.copyWith(
        results: songs,
        isLoading: false,
        hasSearched: true,
        clearError: true,
      );
    } catch (e) {
      if (id != _searchId) return;

      state = state.copyWith(
        results: const <Song>[],
        isLoading: false,
        hasSearched: true,
        error: 'Search failed: $e',
      );
    }
  }

  /// Clears the query and all results.
  void clear() {
    _debounce?.cancel();
    _searchId++;
    state = const SearchState();
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
