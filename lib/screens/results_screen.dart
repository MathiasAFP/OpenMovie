import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/user_library_store.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster.dart';
import '../widgets/movie_search_input.dart';
import 'details_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.initialQuery,
    this.service,
    this.libraryStore,
  });

  final String initialQuery;
  final OmdbService? service;
  final UserLibraryStore? libraryStore;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final OmdbService _service;
  late final UserLibraryStore _libraryStore;
  late final TextEditingController _controller;
  late final TextEditingController _yearController;
  final _scrollController = ScrollController();
  List<MovieSummary> _movies = const [];
  String? _error;
  String? _loadMoreError;
  String? _filterError;
  String? _selectedType;
  int _totalResults = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const OmdbService();
    _libraryStore = widget.libraryStore ?? UserLibraryStore();
    _controller = TextEditingController(text: widget.initialQuery);
    _yearController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _search(widget.initialQuery),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _yearController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    final year = _yearController.text.trim();
    if (year.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(year)) {
      setState(() => _filterError = 'Digite um ano com quatro dígitos.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _loadMoreError = null;
      _filterError = null;
      _movies = const [];
      _totalResults = 0;
      _page = 0;
      _controller.text = cleanQuery;
    });

    try {
      final result = await _service.searchMovies(
        cleanQuery,
        type: _selectedType,
        year: year.isEmpty ? null : year,
      );
      if (!mounted) return;
      setState(() {
        _movies = result.movies;
        _totalResults = result.totalResults;
        _page = 1;
        _loading = false;
      });
    } on OmdbApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocorreu um erro inesperado. Tente buscar novamente.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_canLoadMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _service.searchMovies(
        _controller.text,
        page: _page + 1,
        type: _selectedType,
        year: _yearController.text.trim().isEmpty
            ? null
            : _yearController.text.trim(),
      );
      if (!mounted) return;
      final existingIds = _movies.map((movie) => movie.imdbId).toSet();
      setState(() {
        _movies = [
          ..._movies,
          ...result.movies.where(
            (movie) => !existingIds.contains(movie.imdbId),
          ),
        ];
        _totalResults = result.totalResults;
        _page += 1;
        _loadingMore = false;
      });
    } on OmdbApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = error.message;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = 'Não foi possível carregar mais resultados.';
        _loadingMore = false;
      });
    }
  }

  bool get _canLoadMore => _movies.length < _totalResults && _page < 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Resultados'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MovieSearchInput(
                    controller: _controller,
                    compact: true,
                    loading: _loading,
                    onSearch: _search,
                  ),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  Text(
                    'Resultados para “${_controller.text}”',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (!_loading && _error == null && _movies.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      _totalResults.toString() +
                          (_totalResults == 1
                              ? ' título encontrado'
                              : ' títulos encontrados'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(_filtersExpanded ? 'Ocultar filtros' : 'Filtros'),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            ),
          ),
          if (_filtersExpanded)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de produção',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      _typeChip('Todos', null),
                      _typeChip('Filmes', 'movie'),
                      _typeChip('Séries', 'series'),
                    ],
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ano (opcional)',
                      hintText: 'Ex.: 2022',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      counterText: '',
                    ),
                  ),
                  if (_filterError != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      _filterError!,
                      style: const TextStyle(
                        color: AppColors.accentSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = null;
                            _yearController.clear();
                            _filterError = null;
                          });
                        },
                        child: const Text('Limpar'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() => _filtersExpanded = false);
                                _search(_controller.text);
                              },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, String? value) {
    final selected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedType = value),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      labelStyle: TextStyle(
        color: selected ? AppColors.text : AppColors.muted,
        fontSize: 12,
      ),
      showCheckmark: false,
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
              'Procurando no catálogo...',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'A busca não foi concluída',
        message: _error!,
        actionLabel: 'Tentar novamente',
        onAction: () => _search(_controller.text),
      );
    }

    if (_movies.isEmpty) {
      return const _MessageState(
        icon: Icons.movie_filter_outlined,
        title: 'Nenhum título encontrado',
        message: 'Tente outro nome ou confira a grafia do título.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount:
          _movies.length + (_canLoadMore || _loadMoreError != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _movies.length) return _buildLoadMore();
        final movie = _movies[index];
        return _MovieResultTile(
          movie: movie,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailsScreen(
                imdbId: movie.imdbId,
                service: _service,
                libraryStore: _libraryStore,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMore() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadMoreError != null) {
      return Column(
        children: [
          Text(
            _loadMoreError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          TextButton(
            onPressed: _loadMore,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: _loadMore,
        icon: const Icon(Icons.expand_more_rounded),
        label: const Text('Carregar mais'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

class _MovieResultTile extends StatelessWidget {
  const _MovieResultTile({required this.movie, required this.onTap});

  final MovieSummary movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              MoviePoster(
                url: movie.posterUrl,
                width: 66,
                height: 92,
                borderRadius: 10,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      movie.year,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        movie.localizedType,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
