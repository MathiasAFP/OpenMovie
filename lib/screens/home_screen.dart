import 'package:flutter/material.dart';

import '../services/search_history_store.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_search_input.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _historyStore = SearchHistoryStore();
  List<String> _history = const [];
  bool _historyLoaded = false;

  static const _suggestions = ['Batman', 'Interstellar', 'Breaking Bad'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
        builder: (_) => ResultsScreen(initialQuery: cleanQuery),
      ),
    );
    if (mounted) _loadHistory();
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
            child: SizedBox(
              width: 116,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.16,
                    child: Icon(
                      Icons.movie_filter_rounded,
                      size: 69,
                      color: AppColors.muted.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 0,
                    child: Transform.rotate(
                      angle: 0.18,
                      child: const Icon(
                        Icons.search_rounded,
                        size: 48,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    top: 5,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 17,
                      color: AppColors.gold,
                    ),
                  ),
                ],
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
