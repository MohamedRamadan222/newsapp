import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';
import '../services/actions.dart';
import '../services/bookmarks_store.dart';
import '../services/spaceflight_api.dart';
import '../theme/app_theme.dart';
import '../widgets/article_cards.dart';
import '../widgets/common.dart';

/// Mirrors `design/search.html`: search bar + tags + recent + results.
///
/// Layout rule: ONE scrollable ([SingleChildScrollView]); results are a
/// plain [Column], never a nested [ListView].
class SearchScreen extends StatefulWidget {
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final void Function(Article) onOpen;
  final String initialQuery;
  const SearchScreen({
    super.key,
    required this.api,
    required this.bookmarks,
    required this.onOpen,
    this.initialQuery = '',
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _tags = ['Moon', 'Starship', 'Webb', 'ISS', 'Mars', 'Artemis'];
  static const _recentsKey = 'recent_searches';
  final _controller = TextEditingController();
  List<String> _recent = [];
  Future<List<Article>>? _results;
  String _label = '';

  @override
  void initState() {
    super.initState();
    _loadRecents();
    if (widget.initialQuery.isNotEmpty) {
      _controller.text = widget.initialQuery;
      // Post-frame: _run touches FocusScope, which isn't ready in initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run(widget.initialQuery);
      });
    }
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recent = List.of(
        prefs.getStringList(_recentsKey) ?? const <String>[],
      );
    });
  }

  Future<void> _persistRecents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentsKey, _recent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(String term) {
    term = term.trim();
    if (term.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _label = term;
      _results = widget.api.search(term, limit: 12);
      _recent.remove(term);
      _recent.insert(0, term);
      if (_recent.length > 5) _recent.removeLast();
    });
    _persistRecents();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _run,
                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Search moon, SpaceX, NASA…',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.faint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.muted,
                      ),
                      filled: true,
                      fillColor: AppTheme.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppTheme.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _run(_controller.text),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader('Trending topics'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (t) => FilterChipPill(
                      label: t,
                      selected: t == _label,
                      onTap: () {
                        _controller.text = t;
                        _run(t);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              'Recent searches',
              action: 'Clear',
              onAction: _recent.isEmpty
                  ? null
                  : () {
                      setState(_recent.clear);
                      _persistRecents();
                    },
            ),
          ),
          ..._recent.map(
            (r) => ListTile(
              leading: const Icon(
                Icons.history,
                size: 20,
                color: AppTheme.faint,
              ),
              title: Text(r, style: textTheme.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.faint),
                onPressed: () {
                  setState(() => _recent.remove(r));
                  _persistRecents();
                },
              ),
              onTap: () {
                _controller.text = r;
                _run(r);
              },
            ),
          ),
          if (_results != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader('Results for “$_label”'),
            ),
            FutureBuilder<List<Article>>(
              future: _results,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingList();
                }
                if (snap.hasError) {
                  return StateMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Search failed',
                    subtitle: '${snap.error}',
                    actionLabel: 'Retry',
                    onAction: () => _run(_label),
                  );
                }
                final items = snap.data ?? const <Article>[];
                if (items.isEmpty) {
                  return const StateMessage(
                    icon: Icons.search_off_outlined,
                    title: 'No results',
                    subtitle: 'Try another keyword.',
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        ListenableBuilder(
                          listenable: widget.bookmarks,
                          builder: (_, _) => NewsCard(
                            article: items[i],
                            onTap: () => widget.onOpen(items[i]),
                            saved: widget.bookmarks.isSaved(items[i].id),
                            onSave: () => ArticleActions.toggleSave(
                              context,
                              widget.bookmarks,
                              items[i],
                            ),
                          ),
                        ),
                        if (i != items.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
