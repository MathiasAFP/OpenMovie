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

  factory MovieSummary.fromLibraryJson(Map<String, dynamic> json) {
    return MovieSummary(
      imdbId: json['imdbId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Título indisponível',
      year: json['year']?.toString() ?? 'Ano indisponível',
      type: json['type']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
    );
  }

  final String imdbId;
  final String title;
  final String year;
  final String type;
  final String posterUrl;

  Map<String, String> toLibraryJson() => {
    'imdbId': imdbId,
    'title': title,
    'year': year,
    'type': type,
    'posterUrl': posterUrl,
  };

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

class MovieRating {
  const MovieRating({required this.source, required this.value});

  factory MovieRating.fromJson(Map<String, dynamic> json) => MovieRating(
    source: json['Source']?.toString() ?? '',
    value: json['Value']?.toString() ?? '',
  );

  final String source;
  final String value;
}

class SeasonEpisode {
  const SeasonEpisode({
    required this.imdbId,
    required this.title,
    required this.released,
    required this.episode,
    required this.imdbRating,
  });

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) => SeasonEpisode(
    imdbId: json['imdbID']?.toString() ?? '',
    title: json['Title']?.toString() ?? 'Título indisponível',
    released: json['Released']?.toString() ?? '',
    episode: json['Episode']?.toString() ?? '',
    imdbRating: json['imdbRating']?.toString() ?? '',
  );

  final String imdbId;
  final String title;
  final String released;
  final String episode;
  final String imdbRating;
}

class SeasonEpisodes {
  const SeasonEpisodes({
    required this.season,
    required this.totalSeasons,
    required this.episodes,
  });

  factory SeasonEpisodes.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['Episodes'];
    final episodes = rawEpisodes is List
        ? rawEpisodes
              .whereType<Map>()
              .map(
                (episode) =>
                    SeasonEpisode.fromJson(Map<String, dynamic>.from(episode)),
              )
              .toList(growable: false)
        : const <SeasonEpisode>[];

    return SeasonEpisodes(
      season: json['Season']?.toString() ?? '',
      totalSeasons: int.tryParse(json['totalSeasons']?.toString() ?? '') ?? 0,
      episodes: episodes,
    );
  }

  final String season;
  final int totalSeasons;
  final List<SeasonEpisode> episodes;
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
    this.writer = '',
    this.country = '',
    this.awards = '',
    this.metascore = '',
    this.imdbVotes = '',
    this.dvd = '',
    this.boxOffice = '',
    this.production = '',
    this.website = '',
    this.totalSeasons,
    this.ratings = const [],
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    final rawRatings = json['Ratings'];
    final ratings = rawRatings is List
        ? rawRatings
              .whereType<Map>()
              .map(
                (rating) =>
                    MovieRating.fromJson(Map<String, dynamic>.from(rating)),
              )
              .toList(growable: false)
        : const <MovieRating>[];

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
      writer: json['Writer']?.toString() ?? '',
      country: json['Country']?.toString() ?? '',
      awards: json['Awards']?.toString() ?? '',
      metascore: json['Metascore']?.toString() ?? '',
      imdbVotes: json['imdbVotes']?.toString() ?? '',
      dvd: json['DVD']?.toString() ?? '',
      boxOffice: json['BoxOffice']?.toString() ?? '',
      production: json['Production']?.toString() ?? '',
      website: json['Website']?.toString() ?? '',
      totalSeasons: int.tryParse(json['totalSeasons']?.toString() ?? ''),
      ratings: ratings,
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
  final String writer;
  final String country;
  final String awards;
  final String metascore;
  final String imdbVotes;
  final String dvd;
  final String boxOffice;
  final String production;
  final String website;
  final int? totalSeasons;
  final List<MovieRating> ratings;

  String get localizedType => switch (type.toLowerCase()) {
    'movie' => 'Filme',
    'series' => 'Série',
    'episode' => 'Episódio',
    _ => 'Título',
  };

  bool get isSeries => type.toLowerCase() == 'series';

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

  MovieSummary get summary => MovieSummary(
    imdbId: imdbId,
    title: title,
    year: year,
    type: type,
    posterUrl: posterUrl,
  );
}
