import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStore {
  SearchHistoryStore() : _preferences = SharedPreferencesAsync();

  static const _storageKey = 'openmovie.recent-searches.v1';

  final SharedPreferencesAsync _preferences;

  Future<List<String>> read() async {
    return await _preferences.getStringList(_storageKey) ?? const <String>[];
  }

  Future<List<String>> record(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return read();

    final current = await read();
    final normalized = cleanQuery.toLowerCase();
    final updated = <String>[
      cleanQuery,
      ...current.where((item) => item.toLowerCase() != normalized),
    ].take(5).toList(growable: false);

    await _preferences.setStringList(_storageKey, updated);
    return updated;
  }

  Future<void> clear() => _preferences.remove(_storageKey);
}
