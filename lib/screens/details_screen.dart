import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/user_library_store.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.imdbId,
    this.service,
    this.libraryStore,
  });

  final String imdbId;
  final OmdbService? service;
  final UserLibraryStore? libraryStore;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final OmdbService _service;
  late final UserLibraryStore _libraryStore;
  MovieDetails? _movie;
  SeasonEpisodes? _seasonEpisodes;
  Set<String> _watchedEpisodeIds = const {};
  String? _error;
  String? _seasonError;
  int? _selectedSeason;
  bool _loading = true;
  bool _loadingSeason = false;
  bool _libraryLoading = true;
  bool _savingLibrary = false;
  bool _isFavorite = false;
  bool _isWatchLater = false;
  bool _isWatched = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const OmdbService();
    _libraryStore = widget.libraryStore ?? UserLibraryStore();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final movie = await _service.getMovieDetails(widget.imdbId);
      if (!mounted) return;
      setState(() {
        _movie = movie;
        _loading = false;
        _selectedSeason = movie.isSeries && (movie.totalSeasons ?? 0) > 0
            ? 1
            : null;
      });
      await _loadLibraryStatus(movie);
      if (_selectedSeason != null) await _loadSeason(_selectedSeason!);
    } on OmdbApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os detalhes deste título.';
        _loading = false;
      });
    }
  }

  Future<void> _loadLibraryStatus(MovieDetails movie) async {
    try {
      final values = await Future.wait([
        _libraryStore.contains(MovieCollection.favorites, movie.imdbId),
        _libraryStore.contains(MovieCollection.watchLater, movie.imdbId),
        _libraryStore.contains(MovieCollection.watched, movie.imdbId),
      ]);
      final watchedEpisodes = movie.isSeries
          ? await _libraryStore.readWatchedEpisodes(movie.imdbId)
          : const <String>{};
      if (!mounted) return;
      setState(() {
        _isFavorite = values[0];
        _isWatchLater = values[1];
        _isWatched = values[2];
        _watchedEpisodeIds = watchedEpisodes;
        _libraryLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _libraryLoading = false);
    }
  }

  Future<void> _toggleCollection(MovieCollection collection) async {
    final movie = _movie;
    if (movie == null || _savingLibrary) return;
    final current = switch (collection) {
      MovieCollection.favorites => _isFavorite,
      MovieCollection.watchLater => _isWatchLater,
      MovieCollection.watched => _isWatched,
    };
    setState(() => _savingLibrary = true);
    try {
      await _libraryStore.set(collection, movie.summary, !current);
      if (!mounted) return;
      setState(() {
        switch (collection) {
          case MovieCollection.favorites:
            _isFavorite = !current;
          case MovieCollection.watchLater:
            _isWatchLater = !current;
          case MovieCollection.watched:
            _isWatched = !current;
        }
        _savingLibrary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingLibrary = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar essa alteração.'),
        ),
      );
    }
  }

  Future<void> _toggleEpisode(SeasonEpisode episode) async {
    if (episode.imdbId.isEmpty || _movie == null) return;
    final previous = _watchedEpisodeIds;
    final currentlyWatched = _watchedEpisodeIds.contains(episode.imdbId);
    final updated = {..._watchedEpisodeIds};
    if (currentlyWatched) {
      updated.remove(episode.imdbId);
    } else {
      updated.add(episode.imdbId);
    }
    setState(() => _watchedEpisodeIds = updated);
    try {
      await _libraryStore.setEpisodeWatched(
        _movie!.imdbId,
        episode.imdbId,
        !currentlyWatched,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _watchedEpisodeIds = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o episódio.')),
      );
    }
  }

  Future<void> _loadSeason(int season) async {
    setState(() {
      _selectedSeason = season;
      _loadingSeason = true;
      _seasonError = null;
    });

    try {
      final result = await _service.getSeasonEpisodes(widget.imdbId, season);
      if (!mounted) return;
      setState(() {
        _seasonEpisodes = result;
        _loadingSeason = false;
      });
    } on OmdbApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _seasonError = error.message;
        _loadingSeason = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _seasonError =
            'Não foi possível carregar os episódios desta temporada.';
        _loadingSeason = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar aos resultados',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Detalhes'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando detalhes...',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_error != null || _movie == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: AppColors.muted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível abrir o título',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Tente novamente em instantes.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final movie = _movie!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(movie),
          const SizedBox(height: 16),
          _buildLibraryActions(),
          const SizedBox(height: 25),
          _buildSection(
            title: 'Sinopse',
            child: Text(
              movie.hasPlot ? movie.plot : 'A sinopse não está disponível.',
              style: const TextStyle(color: AppColors.muted, height: 1.55),
            ),
          ),
          _buildSection(
            title: 'Direção',
            child: _InfoValue(
              value: movie.director,
              emptyText: 'Informação indisponível',
            ),
          ),
          _buildSection(
            title: 'Elenco',
            child: _InfoValue(
              value: movie.actors,
              emptyText: 'Informação indisponível',
            ),
          ),
          if (_valid(movie.writer))
            _buildSection(
              title: 'Roteiro',
              child: Text(
                movie.writer,
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ),
          _buildSection(
            title: 'Informações',
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                if (_valid(movie.released))
                  _FactChip(icon: Icons.event_outlined, label: movie.released),
                if (_valid(movie.runtime))
                  _FactChip(icon: Icons.schedule_rounded, label: movie.runtime),
                if (_valid(movie.language))
                  _FactChip(
                    icon: Icons.language_rounded,
                    label: movie.language,
                  ),
                if (_valid(movie.rated))
                  _FactChip(
                    icon: Icons.confirmation_number_outlined,
                    label: movie.rated,
                  ),
              ],
            ),
          ),
          if (_hasAdditionalInformation(movie))
            _buildSection(
              title: 'Outros dados',
              child: Column(
                children: [
                  _InfoLine(label: 'País', value: movie.country),
                  _InfoLine(label: 'Prêmios', value: movie.awards),
                  _InfoLine(label: 'DVD', value: movie.dvd),
                  _InfoLine(label: 'Bilheteria', value: movie.boxOffice),
                  _InfoLine(label: 'Produção', value: movie.production),
                  _InfoLine(label: 'Site', value: movie.website),
                  _InfoLine(label: 'IMDb ID', value: movie.imdbId),
                ],
              ),
            ),
          if (movie.ratings.isNotEmpty ||
              _valid(movie.metascore) ||
              _valid(movie.imdbVotes))
            _buildSection(
              title: 'Avaliações',
              child: Column(
                children: [
                  for (final rating in movie.ratings)
                    _InfoLine(label: rating.source, value: rating.value),
                  _InfoLine(label: 'Metascore', value: movie.metascore),
                  _InfoLine(label: 'Votos IMDb', value: movie.imdbVotes),
                ],
              ),
            ),
          if (movie.isSeries) _buildSeasonEpisodes(movie),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Dados fornecidos pela OMDb',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _libraryAction(
          label: _isFavorite ? 'Favorito' : 'Favoritar',
          icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          selected: _isFavorite,
          onPressed: () => _toggleCollection(MovieCollection.favorites),
        ),
        _libraryAction(
          label: _isWatchLater ? 'Na lista' : 'Assistir mais tarde',
          icon: _isWatchLater ? Icons.bookmark_rounded : Icons.bookmark_border,
          selected: _isWatchLater,
          onPressed: () => _toggleCollection(MovieCollection.watchLater),
        ),
        _libraryAction(
          label: _isWatched ? 'Assistido' : 'Marcar assistido',
          icon: _isWatched ? Icons.check_circle : Icons.check_circle_outline,
          selected: _isWatched,
          onPressed: () => _toggleCollection(MovieCollection.watched),
        ),
      ],
    );
  }

  Widget _libraryAction({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _libraryLoading || _savingLibrary ? null : onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.accent : AppColors.muted,
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      ),
    );
  }

  bool _hasAdditionalInformation(MovieDetails movie) =>
      _valid(movie.country) ||
      _valid(movie.awards) ||
      _valid(movie.dvd) ||
      _valid(movie.boxOffice) ||
      _valid(movie.production) ||
      _valid(movie.website) ||
      _valid(movie.imdbId);

  Widget _buildSeasonEpisodes(MovieDetails movie) {
    final totalSeasons = movie.totalSeasons ?? 0;
    if (totalSeasons < 1) {
      return _buildSection(
        title: 'Temporadas e episódios',
        child: const Text(
          'A OMDb não informou as temporadas desta série.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return _buildSection(
      title: 'Temporadas e episódios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Temporada',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _selectedSeason,
                isDense: true,
                onChanged: _loadingSeason
                    ? null
                    : (season) {
                        if (season != null && season != _selectedSeason) {
                          _loadSeason(season);
                        }
                      },
                items: List.generate(
                  totalSeasons,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Temporada ${index + 1}'),
                  ),
                ),
              ),
            ],
          ),
          if (_loadingSeason)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_seasonError != null)
            Column(
              children: [
                Text(
                  _seasonError!,
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton.icon(
                  onPressed: () => _loadSeason(_selectedSeason ?? 1),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (_seasonEpisodes?.episodes.isEmpty ?? true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhum episódio informado para esta temporada.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            ..._seasonEpisodes!.episodes.map(_buildEpisodeTile),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(SeasonEpisode episode) {
    final subtitle = [
      if (_valid(episode.released)) episode.released,
      if (_valid(episode.imdbRating)) 'IMDb ${episode.imdbRating}',
    ].join(' • ');

    final isWatched = _watchedEpisodeIds.contains(episode.imdbId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceRaised,
        child: Text(
          _valid(episode.episode) ? episode.episode : '•',
          style: const TextStyle(fontSize: 12, color: AppColors.text),
        ),
      ),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: const TextStyle(color: AppColors.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: isWatched
                ? 'Marcar como não assistido'
                : 'Marcar assistido',
            onPressed: episode.imdbId.isEmpty
                ? null
                : () => _toggleEpisode(episode),
            icon: Icon(
              isWatched
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank,
              color: isWatched ? AppColors.accent : AppColors.muted,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
      onTap: _valid(episode.imdbId)
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DetailsScreen(
                  imdbId: episode.imdbId,
                  service: _service,
                  libraryStore: _libraryStore,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHero(MovieDetails movie) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoviePoster(
          url: movie.posterUrl,
          width: 126,
          height: 184,
          borderRadius: 15,
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    movie.year,
                    movie.runtime,
                    movie.localizedType,
                  ].where(_valid).join(' • '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (movie.hasRating) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'IMDb ${movie.imdbRating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (movie.genres.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: movie.genres
                        .take(4)
                        .map(
                          (genre) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          child,
          const SizedBox(height: 18),
          const Divider(),
        ],
      ),
    );
  }
}

bool _valid(String value) =>
    value.trim().isNotEmpty && value.toUpperCase() != 'N/A';

class _InfoValue extends StatelessWidget {
  const _InfoValue({required this.value, required this.emptyText});

  final String value;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Text(
      _valid(value) ? value : emptyText,
      style: const TextStyle(color: AppColors.muted, height: 1.45),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (!_valid(value)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
