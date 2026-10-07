import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omdb/screens/details_screen.dart';
import 'package:omdb/screens/home_screen.dart';
import 'package:omdb/services/omdb_service.dart';
import 'package:omdb/services/user_library_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:omdb/main.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('mostra a identidade e a busca inicial do OpenMovie', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenMovieApp());

    expect(find.text('OpenMovie'), findsOneWidget);
    expect(find.text('Encontre seu\npróximo filme'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
  });

  testWidgets('busca, abre detalhes e mantém favoritos na biblioteca', (
    WidgetTester tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.queryParameters.containsKey('s')) {
        return http.Response(
          jsonEncode({
            'Response': 'True',
            'totalResults': '1',
            'Search': [
              {
                'Title': 'The Batman',
                'Year': '2022',
                'imdbID': 'tt1877830',
                'Type': 'movie',
                'Poster': 'N/A',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'Response': 'True',
          'Title': 'The Batman',
          'Year': '2022',
          'Released': '04 Mar 2022',
          'Runtime': '176 min',
          'Rated': 'PG-13',
          'Type': 'movie',
          'Poster': 'N/A',
          'Genre': 'Action, Crime',
          'Plot': 'Batman investiga crimes em Gotham.',
          'Director': 'Matt Reeves',
          'Actors': 'Robert Pattinson',
          'imdbRating': '7.8',
          'Language': 'English',
          'imdbID': 'tt1877830',
        }),
        200,
      );
    });
    final service = OmdbService(client: client, apiKey: 'test-key');
    final libraryStore = UserLibraryStore();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(service: service, libraryStore: libraryStore),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.ensureVisible(searchField);
    await tester.enterText(searchField, 'Batman');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('The Batman'), findsOneWidget);

    await tester.tap(find.text('The Batman'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Sinopse'), findsOneWidget);

    await tester.tap(find.text('Favoritar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistir mais tarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar assistido'));
    await tester.pumpAndSettle();
    expect(
      await libraryStore.contains(MovieCollection.favorites, 'tt1877830'),
      isTrue,
    );
    expect(
      await libraryStore.contains(MovieCollection.watchLater, 'tt1877830'),
      isTrue,
    );
    expect(
      await libraryStore.contains(MovieCollection.watched, 'tt1877830'),
      isTrue,
    );

    await tester.tap(find.byTooltip('Voltar aos resultados'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Minha biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos (1)'), findsOneWidget);
    expect(find.text('Assistir mais tarde (1)'), findsOneWidget);
    expect(find.text('Assistidos (1)'), findsOneWidget);
    expect(find.text('The Batman'), findsNWidgets(2));
  });

  testWidgets('marca episódios da série como assistidos', (
    WidgetTester tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.queryParameters.containsKey('Season')) {
        return http.Response(
          jsonEncode({
            'Response': 'True',
            'Season': '1',
            'totalSeasons': '1',
            'Episodes': [
              {
                'Title': 'Episode One',
                'Released': '01 Jan 2024',
                'Episode': '1',
                'imdbRating': '8.1',
                'imdbID': 'tt0959621',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'Response': 'True',
          'Title': 'Breaking Bad',
          'Year': '2008-2013',
          'Released': '20 Jan 2008',
          'Runtime': '49 min',
          'Rated': 'TV-MA',
          'Type': 'series',
          'Poster': 'N/A',
          'Genre': 'Crime, Drama',
          'Plot': 'A história de Walter White.',
          'Director': 'Vince Gilligan',
          'Actors': 'Bryan Cranston',
          'imdbRating': '9.5',
          'Language': 'English',
          'imdbID': 'tt0903747',
          'totalSeasons': '1',
        }),
        200,
      );
    });
    final libraryStore = UserLibraryStore();

    await tester.pumpWidget(
      MaterialApp(
        home: DetailsScreen(
          imdbId: 'tt0903747',
          service: OmdbService(client: client, apiKey: 'test-key'),
          libraryStore: libraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Episode One'), findsOneWidget);
    await tester.ensureVisible(find.text('Episode One'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Marcar assistido'));
    await tester.pumpAndSettle();

    expect(
      await libraryStore.readWatchedEpisodes('tt0903747'),
      contains('tt0959621'),
    );
    expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('Marcar como não assistido'));
    await tester.pumpAndSettle();
    expect(await libraryStore.readWatchedEpisodes('tt0903747'), isEmpty);
  });
}
