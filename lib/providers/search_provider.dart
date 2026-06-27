// lib/providers/search_provider.dart
//
// Phase 5A Recovery — persistent search history (last 20 unique queries).
//
// UNCHANGED: debounce logic, stale-search guard, MusicSearchService call.
// ADDED: history persisted to SharedPreferences; removeFromHistory /
//        clearHistory exposed to the UI.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/constants/app_constants.dart';
import 'package:armonia/data/models/song.dart';
import 'package:armonia/providers/settings_provider.dart';
import 'package:armonia/services/music_search_service.dart';

@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.results = const <Song>[],
    this.history = const <String>[],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
  });

  final String query;
  final List<Song> results;

  /// Persisted list of past unique query strings, most-recent first.
  /// Capped at [AppConstants.maxSearchHistoryItems].
  final List<String> history;

  final bool isLoading;
  final bool hasSearched;
  final String? error;

  SearchState copyWith({
    String? query,
    List<Song>? results,
    List<String>? history,
    bool? isLoading,
    bool? hasSearched,
    String? error,
    bool clearError = false,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        history: history ?? this.history,
        isLoading: isLoading ?? this.isLoading,
        hasSearched: hasSearched ?? this.hasSearched,
        error: clearError ? null : (error ?? this.error),
      );
}

final musicSearchServiceProvider = Provider<MusicSearchService>((ref) {
  return const MusicSearchService();
});

class SearchNotifier extends Notifier<SearchState> {
  late final MusicSearchService _service;
  late final SharedPreferences _prefs;
  Timer? _debounce;
  int _searchId = 0;

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  SearchState build() {
    _service = ref.read(musicSearchServiceProvider);
    _prefs = ref.read(sharedPreferencesProvider);
    ref.onDispose(() => _debounce?.cancel());
    return SearchState(history: _loadHistory());
  }

  // ── History persistence ──────────────────────────────────────────────────

  List<String> _loadHistory() {
    try {
      final String? raw =
          _prefs.getString(AppConstants.prefSearchHistory);
      if (raw == null || raw.isEmpty) return const <String>[];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toList();
    } catch (e) {
      debugPrint('[SearchProvider] _loadHistory FAILED: $e');
      return const <String>[];
    }
  }

  void _persistHistory(List<String> history) {
    try {
      _prefs.setString(
          AppConstants.prefSearchHistory, jsonEncode(history));
    } catch (e) {
      debugPrint('[SearchProvider] _persistHistory FAILED: $e');
    }
  }

  /// Prepends [query] to history, deduplicates, trims to max.
  void _recordHistory(String query) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final List<String> updated = <String>[
      trimmed,
      ...state.history.where((q) => q != trimmed),
    ];
    final List<String> capped =
        updated.length > AppConstants.maxSearchHistoryItems
            ? updated.sublist(0, AppConstants.maxSearchHistoryItems)
            : updated;
    state = state.copyWith(history: capped);
    _persistHistory(capped);
  }

  void removeFromHistory(String query) {
    final List<String> updated =
        state.history.where((q) => q != query).toList();
    state = state.copyWith(history: updated);
    _persistHistory(updated);
  }

  void clearHistory() {
    state = state.copyWith(history: const <String>[]);
    _persistHistory(const <String>[]);
  }

  // ── Query handling ───────────────────────────────────────────────────────

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
    _debounce =
        Timer(_debounceDuration, () => _performSearch(trimmed));
  }

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
      if (id != _searchId) return;
      _recordHistory(query);
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

  void clear() {
    _debounce?.cancel();
    _searchId++;
    state = SearchState(history: state.history);
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
