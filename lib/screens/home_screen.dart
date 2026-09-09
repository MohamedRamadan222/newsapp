import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/actions.dart';
import '../services/bookmarks_store.dart';
import '../services/spaceflight_api.dart';
import '../theme/app_theme.dart';
import '../widgets/article_cards.dart';
import '../widgets/common.dart';

/// Sections mirror `design/index.html`: hero + trending + latest.
///
/// Layout rule: ONE scrollable ([SingleChildScrollView]). Every list
/// inside is either a fixed-height horizontal scroller or a plain
/// [Column] — never a nested vertical [ListView].
///
/// Content rule: sections never repeat each other. Hero + trending come
/// from the head batch; Latest is a separate paged feed with Load more.
class HomeScreen extends StatefulWidget {
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final void Function(Article) onOpen;
  final void Function(int) onSeeAll;
  const HomeScreen({
    super.key,
    required this.api,
    required this.bookmarks,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _filters = [
    'All',
    'NASA',
    'SpaceX',
    'ESA',
    'Rocket Lab',
    'Blue Origin',
  ];
  static const _pageSize = 10;

  String _filter = 'All';
  late Future<List<Article>> _headFuture;
  final List<Article> _latest = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _headFuture = _loadHead();
    _loadLatest(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<List<Article>> _loadHead() {
    if (_filter == 'All') return widget.api.latest(limit: 10);
    return widget.api.bySite(_filter, limit: 10);
  }

  /// Latest is its own feed so it never duplicates hero/trending.
  Future<void> _loadLatest({required bool reset}) async {
    if (_filter != 'All') return; // filtered view: head batch covers it
    if (_loadingMore || (!reset && !_hasMore)) return;
    if (reset) {
      setState(() {
        _latest.clear();
        _offset = 6; // skip hero + trending window
        _hasMore = true;
      });
    }
    setState(() => _loadingMore = true);
    try {
      final page = await widget.api.latest(limit: _pageSize, offset: _offset);
      if (!mounted) return;
      final known = _latest.map((a) => a.id).toSet();
      setState(() {
        _latest.addAll(page.where((a) => known.add(a.id)));
        _offset += _pageSize;
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadLatest(reset: false);
    }
  }

  void _refresh() {
    setState(() => _headFuture = _loadHead());
    _loadLatest(reset: true);
  }

  void _pickFilter(String f) {
    setState(() {
      _filter = f;
      _headFuture = _loadHead();
    });
    _loadLatest(reset: true);
  }

  Article _heroOf(List<Article> items) {
    return items.firstWhere(
      (a) => a.imageUrl.isNotEmpty,
      orElse: () => items.first,
    );
  }

  List<Article> _trendingOf(List<Article> items, Article hero) {
    final rest = items.where((a) => a.id != hero.id).toList();
    final withImage = rest.where((a) => a.imageUrl.isNotEmpty).toList();
    final pool = withImage.length >= 3 ? withImage : rest;
    return pool.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => FilterChipPill(
                  label: _filters[i],
                  selected: _filters[i] == _filter,
                  onTap: () => _pickFilter(_filters[i]),
                ),
              ),
            ),
            FutureBuilder<List<Article>>(
              future: _headFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LoadingList(),
                  );
                }
                if (snap.hasError) {
                  return StateMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Couldn\'t load news',
                    subtitle: '${snap.error}',
                    actionLabel: 'Retry',
                    onAction: _refresh,
                  );
                }
                final items = snap.data ?? const <Article>[];
                if (items.isEmpty) {
                  return const StateMessage(
                    icon: Icons.newspaper_outlined,
                    title: 'No stories yet',
                    subtitle: 'Try another topic.',
                  );
                }
                final hero = _heroOf(items);
                final trending = _trendingOf(items, hero);
                final showPagedLatest = _filter == 'All';
                final filteredLatest = items
                    .where(
                      (a) =>
                          a.id != hero.id && !trending.any((t) => t.id == a.id),
                    )
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: HeroCard(
                        article: hero,
                        onTap: () => widget.onOpen(hero),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        'Trending now',
                        action: 'See all ›',
                        onAction: () => widget.onSeeAll(3),
                      ),
                    ),
                    SizedBox(
                      height: 244,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: trending.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => TrendCard(
                          article: trending[i],
                          onTap: () => widget.onOpen(trending[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        'Latest news',
                        action: 'Search ›',
                        onAction: () => widget.onSeeAll(1),
                      ),
                    ),
                    if (showPagedLatest)
                      _LatestFeed(
                        items: _latest,
                        loadingMore: _loadingMore,
                        hasMore: _hasMore,
                        bookmarks: widget.bookmarks,
                        onOpen: widget.onOpen,
                        onLoadMore: () => _loadLatest(reset: false),
                      )
                    else
                      _LatestFeed(
                        items: filteredLatest,
                        loadingMore: false,
                        hasMore: false,
                        bookmarks: widget.bookmarks,
                        onOpen: widget.onOpen,
                        onLoadMore: () {},
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestFeed extends StatelessWidget {
  final List<Article> items;
  final bool loadingMore;
  final bool hasMore;
  final BookmarksStore bookmarks;
  final void Function(Article) onOpen;
  final VoidCallback onLoadMore;
  const _LatestFeed({
    required this.items,
    required this.loadingMore,
    required this.hasMore,
    required this.bookmarks,
    required this.onOpen,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !loadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(
          'Fresh stories are loading… pull to refresh.',
          style: TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListenableBuilder(
              listenable: bookmarks,
              builder: (_, _) => NewsCard(
                article: items[i],
                onTap: () => onOpen(items[i]),
                saved: bookmarks.isSaved(items[i].id),
                onSave: () =>
                    ArticleActions.toggleSave(context, bookmarks, items[i]),
              ),
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
          if (loadingMore)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (hasMore && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLoadMore,
                  child: const Text('Load more'),
                ),
              ),
            )
          else if (items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                '— You\'re all caught up —',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
        ],
      ),
    );
  }
}
