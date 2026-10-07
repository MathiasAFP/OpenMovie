import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:omdb/models/movie.dart';
import 'package:omdb/services/user_library_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  const movie = MovieSummary(
    imdbId: 'tt1877830',
    title: 'The Batman',
    year: '2022',
    type: 'movie',
    posterUrl: 'N/A',
  );

  test('stores and removes library titles without duplicates', () async {
    final store = UserLibraryStore();
    await store.set(MovieCollection.favorites, movie, true);
    await store.set(MovieCollection.favorites, movie, true);
    await store.set(MovieCollection.watchLater, movie, true);
    await store.set(MovieCollection.watched, movie, true);

    final reopenedStore = UserLibraryStore();
    expect(
      (await reopenedStore.read(
        MovieCollection.favorites,
      )).map((item) => item.imdbId),
      [movie.imdbId],
    );
    expect(
      (await reopenedStore.read(
        MovieCollection.watchLater,
      )).map((item) => item.imdbId),
      [movie.imdbId],
    );
    expect(
      (await reopenedStore.read(
        MovieCollection.watched,
      )).map((item) => item.imdbId),
      [movie.imdbId],
    );
    expect(
      await reopenedStore.contains(MovieCollection.favorites, movie.imdbId),
      isTrue,
    );

    await reopenedStore.set(MovieCollection.favorites, movie, false);
    expect(await store.read(MovieCollection.favorites), isEmpty);
  });

  test('stores watched episodes separately for each series', () async {
    final store = UserLibraryStore();
    await store.setEpisodeWatched('tt0903747', 'tt0959621', true);
    await store.setEpisodeWatched('tt0944947', 'tt1480055', true);

    final reopenedStore = UserLibraryStore();
    expect(await reopenedStore.readWatchedEpisodes('tt0903747'), {'tt0959621'});
    expect(await reopenedStore.readWatchedEpisodes('tt0944947'), {'tt1480055'});

    await reopenedStore.setEpisodeWatched('tt0903747', 'tt0959621', false);
    expect(await store.readWatchedEpisodes('tt0903747'), isEmpty);
  });
}
