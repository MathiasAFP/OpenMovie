import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omdb/services/omdb_service.dart';

void main() {
  group('OmdbService', () {
    test('searches with trimmed text, filters, and page 100', () async {
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'Response': 'True',
            'totalResults': '11',
            'Search': [
              {
                'Title': 'Batman',
                'Year': '2024',
                'imdbID': 'tt1234567',
                'Type': 'series',
                'Poster': 'N/A',
              },
            ],
          }),
          200,
        );
      });

      final result = await OmdbService(
        client: client,
        apiKey: 'test-key',
      ).searchMovies('  Batman  ', page: 100, type: 'series', year: '2024');

      expect(requestedUri?.host, 'www.omdbapi.com');
      expect(requestedUri?.queryParameters, {
        'apikey': 'test-key',
        'r': 'json',
        's': 'Batman',
        'page': '100',
        'type': 'series',
        'y': '2024',
      });
      expect(result.totalResults, 11);
      expect(result.movies.single.title, 'Batman');
      expect(result.movies.single.hasPoster, isFalse);
    });

    test(
      'loads details by IMDb ID and maps optional metadata and ratings',
      () async {
        Uri? requestedUri;
        final client = MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'Response': 'True',
              'Title': 'The Batman',
              'Year': '2022',
              'imdbID': 'tt1877830',
              'Type': 'movie',
              'Writer': 'Matt Reeves',
              'Country': 'United States',
              'Awards': '1 win',
              'Metascore': '72',
              'imdbVotes': '800,000',
              'Ratings': [
                {'Source': 'Rotten Tomatoes', 'Value': '85%'},
              ],
            }),
            200,
          );
        });

        final movie = await OmdbService(
          client: client,
          apiKey: 'test-key',
        ).getMovieDetails('tt1877830');

        expect(requestedUri?.queryParameters['i'], 'tt1877830');
        expect(requestedUri?.queryParameters['plot'], 'full');
        expect(movie.writer, 'Matt Reeves');
        expect(movie.country, 'United States');
        expect(movie.awards, '1 win');
        expect(movie.metascore, '72');
        expect(movie.imdbVotes, '800,000');
        expect(movie.ratings.single.source, 'Rotten Tomatoes');
        expect(movie.ratings.single.value, '85%');
      },
    );

    test('loads episodes for a selected season', () async {
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'Response': 'True',
            'Season': '2',
            'totalSeasons': '5',
            'Episodes': [
              {
                'Title': 'Episode One',
                'Released': '01 Jan 2024',
                'Episode': '1',
                'imdbRating': '8.1',
                'imdbID': 'tt7654321',
              },
            ],
          }),
          200,
        );
      });

      final season = await OmdbService(
        client: client,
        apiKey: 'test-key',
      ).getSeasonEpisodes('tt7654000', 2);

      expect(requestedUri?.queryParameters['i'], 'tt7654000');
      expect(requestedUri?.queryParameters['Season'], '2');
      expect(season.totalSeasons, 5);
      expect(season.episodes.single.title, 'Episode One');
      expect(season.episodes.single.imdbId, 'tt7654321');
    });

    test('translates OMDb errors into a readable exception', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({'Response': 'False', 'Error': 'Movie not found!'}),
          200,
        );
      });

      await expectLater(
        OmdbService(client: client, apiKey: 'test-key').searchMovies('missing'),
        throwsA(
          isA<OmdbApiException>().having(
            (error) => error.message,
            'message',
            contains('Nenhum título encontrado'),
          ),
        ),
      );
    });

    test('does not send a request when the API key is missing', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount += 1;
        return http.Response('{}', 200);
      });

      await expectLater(
        OmdbService(client: client, apiKey: '').searchMovies('Batman'),
        throwsA(isA<OmdbApiException>()),
      );
      expect(requestCount, 0);
    });
  });
}
