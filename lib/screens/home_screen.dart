import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/search_history_store.dart';
import '../services/user_library_store.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_search_input.dart';
import 'details_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.service, this.libraryStore});

  final OmdbService? service;
  final UserLibraryStore? libraryStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _historyStore = SearchHistoryStore();
  late final OmdbService _service;
  late final UserLibraryStore _libraryStore;
  List<String> _history = const [];
  List<MovieSummary> _highlights = const [];
  Map<MovieCollection, List<MovieSummary>> _library = const {};
  MovieCollection _selectedCollection = MovieCollection.favorites;
  bool _historyLoaded = false;
  bool _highlightsLoading = true;
  bool _libraryLoaded = false;

  static const _suggestions = ['Batman', 'Interstellar', 'Breaking Bad'];
  static const _highlightSearches = ['Batman', 'Interstellar', 'Breaking Bad'];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const OmdbService();
    _libraryStore = widget.libraryStore ?? UserLibraryStore();
    _loadHistory();
    _loadHighlights();
    _refreshLibrary();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _historyStore.read();
      if (!mounted) return;
      setState(() {
        _history = history;
        _historyLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _historyLoaded = true);
    }
  }

  Future<void> _loadHighlights() async {
    final results = await Future.wait(
      _highlightSearches.map((query) async {
        try {
          final result = await _service.searchMovies(query);
          return result.movies.isEmpty ? null : result.movies.first;
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    final seen = <String>{};
    setState(() {
      _highlights = results
          .whereType<MovieSummary>()
          .where((movie) => movie.imdbId.isNotEmpty && seen.add(movie.imdbId))
          .toList(growable: false);
      _highlightsLoading = false;
    });
  }

  Future<void> _refreshLibrary() async {
    try {
      final entries = await Future.wait([
        _libraryStore.read(MovieCollection.favorites),
        _libraryStore.read(MovieCollection.watchLater),
        _libraryStore.read(MovieCollection.watched),
      ]);
      if (!mounted) return;
      setState(() {
        _library = {
          MovieCollection.favorites: entries[0],
          MovieCollection.watchLater: entries[1],
          MovieCollection.watched: entries[2],
        };
        _libraryLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _libraryLoaded = true);
    }
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    _controller.text = cleanQuery;

    try {
      final updatedHistory = await _historyStore.record(cleanQuery);
      if (mounted) setState(() => _history = updatedHistory);
    } catch (_) {
      // A temporary local-storage issue should not prevent the search.
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          initialQuery: cleanQuery,
          service: _service,
          libraryStore: _libraryStore,
        ),
      ),
    );
    if (mounted) {
      _loadHistory();
      _refreshLibrary();
    }
  }

  Future<void> _openDetails(String imdbId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          imdbId: imdbId,
          service: _service,
          libraryStore: _libraryStore,
        ),
      ),
    );
    if (mounted) _refreshLibrary();
  }

  Future<void> _clearHistory() async {
    try {
      await _historyStore.clear();
      if (mounted) setState(() => _history = const []);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível limpar o histórico.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  sliver: SliverList.list(
                    children: [
                      _buildBrand(),
                      const SizedBox(height: 28),
                      _buildHero(),
                      const SizedBox(height: 28),
                      MovieSearchInput(
                        controller: _controller,
                        onSearch: _search,
                      ),
                      const SizedBox(height: 30),
                      _buildHighlights(),
                      const SizedBox(height: 28),
                      _buildLibrary(),
                      const SizedBox(height: 28),
                      _buildRecentSearches(),
                      const SizedBox(height: 28),
                      _buildFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 19),
            SizedBox(width: 9),
            Text('Destaques', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        if (_highlightsLoading)
          const LinearProgressIndicator(minHeight: 2)
        else if (_highlights.isEmpty)
          const Text(
            'Os destaques não estão disponíveis agora. Tente novamente mais tarde.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          )
        else
          SizedBox(
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _highlights.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = _highlights[index];
                return _HighlightCard(
                  movie: movie,
                  onTap: () => _openDetails(movie.imdbId),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLibrary() {
    final entries = _library[_selectedCollection] ?? const <MovieSummary>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.video_library_outlined,
              color: AppColors.accent,
              size: 19,
            ),
            SizedBox(width: 9),
            Text(
              'Minha biblioteca',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _collectionChip(MovieCollection.favorites, 'Favoritos'),
            _collectionChip(MovieCollection.watchLater, 'Assistir mais tarde'),
            _collectionChip(MovieCollection.watched, 'Assistidos'),
          ],
        ),
        const SizedBox(height: 12),
        if (!_libraryLoaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (entries.isEmpty)
          Text(
            _selectedCollection == MovieCollection.favorites
                ? 'Seus favoritos aparecem aqui.'
                : _selectedCollection == MovieCollection.watchLater
                ? 'Sua lista para assistir mais tarde está vazia.'
                : 'Os títulos marcados como assistidos aparecem aqui.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          )
        else
          ...entries.map(
            (movie) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _LibraryTile(
                movie: movie,
                onTap: () => _openDetails(movie.imdbId),
              ),
            ),
          ),
      ],
    );
  }

  Widget _collectionChip(MovieCollection collection, String label) {
    final selected = _selectedCollection == collection;
    final count = _library[collection]?.length ?? 0;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCollection = collection),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      labelStyle: TextStyle(
        color: selected ? AppColors.text : AppColors.muted,
        fontSize: 12,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.movie_creation_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'OpenMovie',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, size: 7, color: AppColors.success),
              SizedBox(width: 7),
              Text(
                'CATÁLOGO OMDb',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172A3A), Color(0xFF0E1B28), Color(0xFF101D2A)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'NO SEU PRÓXIMO PLAY',
              style: TextStyle(
                color: AppColors.accentSoft,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Encontre seu\npróximo filme',
            style: TextStyle(
              fontSize: 32,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Busque filmes e séries pelo título e descubra\nhistórias para assistir hoje.',
            style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 168,
              height: 112,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.asset(
                'assets/images/openmovie-pesquisa.png',
                fit: BoxFit.cover,
                semanticLabel: 'Claquete e lupa para encontrar filmes',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final entries = _history.isEmpty ? _suggestions : _history;
    final title = _history.isEmpty ? 'Experimente buscar' : 'Buscas recentes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _history.isEmpty
                  ? Icons.auto_awesome_rounded
                  : Icons.history_rounded,
              color: AppColors.muted,
              size: 19,
            ),
            const SizedBox(width: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_history.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Limpar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 11),
        if (!_historyLoaded && _history.isEmpty)
          const LinearProgressIndicator(minHeight: 2)
        else
          ...entries.map(
            (query) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _HistoryTile(query: query, onTap: () => _search(query)),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 15, color: AppColors.muted),
            const SizedBox(width: 7),
            Text(
              'Dados fornecidos pela OMDb',
              style: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.muted,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(query, style: const TextStyle(fontSize: 14)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.movie, required this.onTap});

  final MovieSummary movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoviePoster(
                  url: movie.posterUrl,
                  width: 106,
                  height: 142,
                  borderRadius: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.movie, required this.onTap});

  final MovieSummary movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              MoviePoster(
                url: movie.posterUrl,
                width: 46,
                height: 64,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${movie.year} • ${movie.localizedType}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
