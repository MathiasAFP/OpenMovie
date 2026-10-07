import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

enum MovieCollection { favorites, watchLater, watched }

class UserLibraryStore {
  UserLibraryStore() : _preferences = SharedPreferencesAsync();

  static const _keyPrefix = 'openmovie.library.v1';
  static const _collectionKeys = {
    MovieCollection.favorites: 'favorites',
    MovieCollection.watchLater: 'watch-later',
    MovieCollection.watched: 'watched',
  };

  final SharedPreferencesAsync _preferences;

  Future<List<MovieSummary>> read(MovieCollection collection) async {
    final raw = await _preferences.getString(_collectionKey(collection));
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                MovieSummary.fromLibraryJson(Map<String, dynamic>.from(item)),
          )
          .where((movie) => movie.imdbId.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<bool> contains(MovieCollection collection, String imdbId) async {
    if (imdbId.isEmpty) return false;
    return (await read(collection)).any((movie) => movie.imdbId == imdbId);
  }

  Future<void> set(
    MovieCollection collection,
    MovieSummary movie,
    bool included,
  ) async {
    if (movie.imdbId.isEmpty) return;
    final current = await read(collection);
    final updated = current
        .where((item) => item.imdbId != movie.imdbId)
        .toList(growable: true);
    if (included) updated.insert(0, movie);

    await _preferences.setString(
      _collectionKey(collection),
      jsonEncode(updated.map((item) => item.toLibraryJson()).toList()),
    );
  }

  Future<Set<String>> readWatchedEpisodes(String seriesImdbId) async {
    if (seriesImdbId.isEmpty) return const {};
    final ids = await _preferences.getStringList(_episodeKey(seriesImdbId));
    return (ids ?? const <String>[]).toSet();
  }

  Future<void> setEpisodeWatched(
    String seriesImdbId,
    String episodeImdbId,
    bool watched,
  ) async {
    if (seriesImdbId.isEmpty || episodeImdbId.isEmpty) return;
    final key = _episodeKey(seriesImdbId);
    final current = (await _preferences.getStringList(key) ?? const <String>[])
        .toSet();
    if (watched) {
      current.add(episodeImdbId);
    } else {
      current.remove(episodeImdbId);
    }
    await _preferences.setStringList(key, current.toList()..sort());
  }

  String _collectionKey(MovieCollection collection) =>
      '$_keyPrefix.${_collectionKeys[collection]}';

  String _episodeKey(String seriesImdbId) =>
      '$_keyPrefix.episodes.$seriesImdbId';
}
