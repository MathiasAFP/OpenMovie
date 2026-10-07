class MovieSummary {
  const MovieSummary({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.type,
    required this.posterUrl,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) {
    return MovieSummary(
      imdbId: json['imdbID']?.toString() ?? '',
      title: json['Title']?.toString() ?? 'Título indisponível',
      year: json['Year']?.toString() ?? 'Ano indisponível',
      type: json['Type']?.toString() ?? '',
      posterUrl: json['Poster']?.toString() ?? '',
    );
  }

  final String imdbId;
  final String title;
  final String year;
  final String type;
  final String posterUrl;

  String get localizedType => switch (type.toLowerCase()) {
    'movie' => 'Filme',
    'series' => 'Série',
    'episode' => 'Episódio',
    _ => 'Título',
  };

  bool get hasPoster =>
      posterUrl.isNotEmpty && posterUrl.toUpperCase() != 'N/A';
}

class MovieSearchResult {
  const MovieSearchResult({required this.movies, required this.totalResults});

  final List<MovieSummary> movies;
  final int totalResults;
}

class MovieDetails {
  const MovieDetails({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.released,
    required this.runtime,
    required this.rated,
    required this.type,
    required this.posterUrl,
    required this.genre,
    required this.plot,
    required this.director,
    required this.actors,
    required this.imdbRating,
    required this.language,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      imdbId: json['imdbID']?.toString() ?? '',
      title: json['Title']?.toString() ?? 'Título indisponível',
      year: json['Year']?.toString() ?? '',
      released: json['Released']?.toString() ?? '',
      runtime: json['Runtime']?.toString() ?? '',
      rated: json['Rated']?.toString() ?? '',
      type: json['Type']?.toString() ?? '',
      posterUrl: json['Poster']?.toString() ?? '',
      genre: json['Genre']?.toString() ?? '',
      plot: json['Plot']?.toString() ?? '',
      director: json['Director']?.toString() ?? '',
      actors: json['Actors']?.toString() ?? '',
      imdbRating: json['imdbRating']?.toString() ?? '',
      language: json['Language']?.toString() ?? '',
    );
  }

  final String imdbId;
  final String title;
  final String year;
  final String released;
  final String runtime;
  final String rated;
  final String type;
  final String posterUrl;
  final String genre;
  final String plot;
  final String director;
  final String actors;
  final String imdbRating;
  final String language;

  String get localizedType => switch (type.toLowerCase()) {
    'movie' => 'Filme',
    'series' => 'Série',
    'episode' => 'Episódio',
    _ => 'Título',
  };

  List<String> get genres => genre
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && value.toUpperCase() != 'N/A')
      .toList(growable: false);

  bool get hasRating =>
      imdbRating.isNotEmpty && imdbRating.toUpperCase() != 'N/A';
  bool get hasPoster =>
      posterUrl.isNotEmpty && posterUrl.toUpperCase() != 'N/A';
  bool get hasPlot => plot.isNotEmpty && plot.toUpperCase() != 'N/A';
}
