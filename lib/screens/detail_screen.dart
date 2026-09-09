import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/actions.dart';
import '../services/bookmarks_store.dart';
import '../services/followed_sources.dart';
import '../services/spaceflight_api.dart';
import '../theme/app_theme.dart';
import '../widgets/article_cards.dart';
import '../widgets/common.dart';
import 'topics_screen.dart';

/// Mirrors `design/article.html`: hero + author + body + related.
/// Every button works: share, save (with feedback), follow, tags open
/// a live feed, "Read full story" opens the publisher page.
class DetailScreen extends StatefulWidget {
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final FollowedSources followed;
  final Article article;
  final void Function(Article) onOpen;
  const DetailScreen({
    super.key,
    required this.api,
    required this.bookmarks,
    required this.followed,
    required this.article,
    required this.onOpen,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    try {
      final full = await widget.api.detail(widget.article.id);
      final related = await widget.api.bySite(full.source, limit: 4);
      return _DetailData(
        article: full,
        related: related.where((a) => a.id != full.id).take(2).toList(),
      );
    } catch (_) {
      // Offline fallback: show the tapped card's data.
      return _DetailData(article: widget.article, related: const []);
    }
  }

  void _openTag(String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedScreen(
          title: tag,
          api: widget.api,
          bookmarks: widget.bookmarks,
          followed: widget.followed,
          onOpen: widget.onOpen,
          fetch: (limit) => widget.api.search(tag, limit: limit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          final article = data?.article ?? widget.article;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  ListenableBuilder(
                    listenable: widget.bookmarks,
                    builder: (_, _) {
                      final saved = widget.bookmarks.isSaved(article.id);
                      return Row(
                        children: [
                          _circleBtn(
                            Icons.share_outlined,
                            onTap: () =>
                                ArticleActions.shareArticle(context, article),
                          ),
                          const SizedBox(width: 8),
                          _circleBtn(
                            saved ? Icons.bookmark : Icons.bookmark_border,
                            onTap: () => ArticleActions.toggleSave(
                              context,
                              widget.bookmarks,
                              article,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ArticleImage(url: article.imageUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -20, 0),
                  decoration: const BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NewsBadge(article.source),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${article.source}  •  ${article.timeAgo()}  •  '
                        '${article.readMinutes} min read',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 12),
                      _AuthorRow(
                        source: article.source,
                        followed: widget.followed,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.summary.isEmpty
                            ? 'Full story available on the publisher site.'
                            : article.summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The newsroom will publish updates as the story '
                        'develops. Open the full article for quotes, '
                        'background and the latest timeline.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _tagsFor(article)
                            .map(
                              (t) => FilterChipPill(
                                label: t,
                                selected: false,
                                onTap: () => _openTag(t),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              ArticleActions.openArticle(context, article),
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: const Text('Read full story'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ListenableBuilder(
                          listenable: widget.bookmarks,
                          builder: (_, _) {
                            final saved = widget.bookmarks.isSaved(article.id);
                            return OutlinedButton.icon(
                              onPressed: () => ArticleActions.toggleSave(
                                context,
                                widget.bookmarks,
                                article,
                              ),
                              icon: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_border,
                                size: 20,
                              ),
                              label: Text(saved ? 'Saved' : 'Save article'),
                            );
                          },
                        ),
                      ),
                      if ((data?.related ?? const []).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionHeader('Related stories'),
                        const SizedBox(height: 4),
                        ...data!.related.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListenableBuilder(
                              listenable: widget.bookmarks,
                              builder: (_, _) => NewsCard(
                                article: r,
                                onTap: () => widget.onOpen(r),
                                saved: widget.bookmarks.isSaved(r.id),
                                onSave: () => ArticleActions.toggleSave(
                                  context,
                                  widget.bookmarks,
                                  r,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (snap.connectionState == ConnectionState.waiting)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Loading full story…',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Real tags derived from the article instead of hardcoded dummies.
  static List<String> _tagsFor(Article a) {
    final words = a.title
        .split(RegExp(r'[^A-Za-z]+'))
        .where((w) => w.length > 4)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .toList();
    final tags = <String>[a.source];
    for (final w in words) {
      if (tags.length >= 3) break;
      if (!tags.contains(w)) tags.add(w);
    }
    return tags;
  }

  Widget _circleBtn(IconData icon, {required VoidCallback onTap}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class _DetailData {
  final Article article;
  final List<Article> related;
  const _DetailData({required this.article, required this.related});
}

class _AuthorRow extends StatelessWidget {
  final String source;
  final FollowedSources followed;
  const _AuthorRow({required this.source, required this.followed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.card2,
              border: Border.all(color: AppTheme.border),
              shape: BoxShape.circle,
            ),
            child: Text(
              source.isEmpty ? 'N' : source[0].toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$source Newsroom',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  'Official source',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: followed,
            builder: (_, _) {
              final on = followed.isFollowed(source);
              return FilledButton(
                onPressed: () => followed.toggle(source),
                style: FilledButton.styleFrom(
                  backgroundColor: on ? AppTheme.primary : AppTheme.card2,
                  foregroundColor: on ? AppTheme.onPrimary : AppTheme.text,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(on ? 'Following' : 'Follow'),
              );
            },
          ),
        ],
      ),
    );
  }
}
