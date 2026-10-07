import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

const _omdbApiKey = String.fromEnvironment('OMDB_API_KEY');

class OmdbApiException implements Exception {
  const OmdbApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OmdbService {
  const OmdbService({this.client, String? apiKey})
    : _apiKey = apiKey ?? _omdbApiKey;

  final http.Client? client;
  final String _apiKey;

  Future<MovieSearchResult> searchMovies(
    String query, {
    int page = 1,
    String? type,
    String? year,
  }) async {
    final parameters = <String, String>{
      's': query.trim(),
      'page': page.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (year != null && year.isNotEmpty) 'y': year,
    };
    final data = await _request(parameters);

    final search = data['Search'];
    final movies = search is List
        ? search
              .whereType<Map>()
              .map(
                (item) =>
                    MovieSummary.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <MovieSummary>[];

    return MovieSearchResult(
      movies: movies,
      totalResults:
          int.tryParse(data['totalResults']?.toString() ?? '') ?? movies.length,
    );
  }

  Future<MovieDetails> getMovieDetails(String imdbId) async {
    final data = await _request({'i': imdbId, 'plot': 'full'});
    return MovieDetails.fromJson(data);
  }

  Future<SeasonEpisodes> getSeasonEpisodes(
    String seriesImdbId,
    int season,
  ) async {
    if (season < 1) {
      throw const OmdbApiException('Escolha uma temporada válida.');
    }

    final data = await _request({
      'i': seriesImdbId,
      'Season': season.toString(),
    });
    return SeasonEpisodes.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(Map<String, String> query) async {
    if (_apiKey.trim().isEmpty) {
      throw const OmdbApiException(
        'A chave da OMDb não está configurada. Execute o app com '
        '--dart-define=OMDB_API_KEY=SUA_CHAVE.',
      );
    }

    final uri = Uri.https('www.omdbapi.com', '/', {
      'apikey': _apiKey,
      'r': 'json',
      ...query,
    });

    late final http.Response response;
    try {
      final request = client?.get(uri) ?? http.get(uri);
      response = await request.timeout(const Duration(seconds: 18));
    } on TimeoutException {
      throw const OmdbApiException(
        'A consulta demorou mais que o esperado. Tente novamente.',
      );
    } catch (_) {
      throw const OmdbApiException(
        'Não foi possível acessar a OMDb. Confira sua conexão e tente novamente.',
      );
    }

    if (response.statusCode != 200) {
      throw OmdbApiException(
        'A OMDb respondeu com status HTTP ${response.statusCode}.',
      );
    }

    late final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Resposta JSON inesperada.');
      }
      data = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const OmdbApiException(
        'A resposta da OMDb veio em um formato inválido.',
      );
    } catch (_) {
      throw const OmdbApiException(
        'Não foi possível interpretar a resposta da OMDb.',
      );
    }

    if (data['Response']?.toString() != 'True') {
      final apiError = data['Error']?.toString() ?? '';
      throw OmdbApiException(_translateError(apiError));
    }

    return data;
  }

  String _translateError(String error) {
    switch (error.toLowerCase()) {
      case 'movie not found!':
      case 'series not found!':
      case 'episode not found!':
        return 'Nenhum título encontrado. Confira a busca e tente outro nome.';
      case 'too many results.':
        return 'A busca trouxe muitos resultados. Digite um título mais específico.';
      case 'invalid api key!':
        return 'A chave da OMDb não foi aceita. Confira a configuração local.';
      case 'request limit reached!':
        return 'O limite de consultas da OMDb foi atingido. Tente novamente mais tarde.';
      default:
        return error.isEmpty
            ? 'A OMDb não conseguiu concluir a consulta.'
            : error;
    }
  }
}
