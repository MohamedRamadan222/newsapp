import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/actions.dart';
import '../services/bookmarks_store.dart';
import '../services/followed_sources.dart';
import '../services/spaceflight_api.dart';
import '../theme/app_theme.dart';
import '../widgets/article_cards.dart';
import '../widgets/common.dart';

class _Topic {
  final String name;
  final String detail;
  final IconData icon;
  const _Topic(this.name, this.detail, this.icon);
}

const _topics = [
  _Topic('NASA', 'Official missions', Icons.rocket_launch_outlined),
  _Topic('SpaceX', 'Launches & tests', Icons.bolt_outlined),
  _Topic('ESA', 'Science & Webb', Icons.public_outlined),
  _Topic('Rocket Lab', 'Smallsats', Icons.satellite_alt_outlined),
  _Topic('Blue Origin', 'Crewed flights', Icons.flight_outlined),
  _Topic('Technology', 'Keyword search', Icons.memory_outlined),
];

Future<List<Article>> _topicFetch(SpaceflightApi api, String topic, int limit) {
  if (topic == 'Technology') return api.search('technology', limit: limit);
  return api.bySite(topic, limit: limit);
}

/// Mirrors `design/categories.html`.
class TopicsScreen extends StatelessWidget {
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final FollowedSources followed;
  final void Function(Article) onOpen;
  const TopicsScreen({
    super.key,
    required this.api,
    required this.bookmarks,
    required this.followed,
    required this.onOpen,
  });

  void _openFeed(BuildContext context, String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedScreen(
          title: topic,
          api: api,
          bookmarks: bookmarks,
          followed: followed,
          onOpen: onOpen,
          fetch: (limit) => _topicFetch(api, topic, limit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 184,
              ),
              itemCount: _topics.length,
              itemBuilder: (_, i) {
                final t = _topics[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openFeed(context, t.name),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.card2,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(t.icon, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            t.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const Spacer(),
                          ListenableBuilder(
                            listenable: followed,
                            builder: (_, _) {
                              final on = followed.isFollowed(t.name);
                              return GestureDetector(
                                onTap: () => followed.toggle(t.name),
                                child: Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: on
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: on
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    on ? 'Following' : 'Follow',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: on
                                              ? AppTheme.onPrimary
                                              : AppTheme.text,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader('How topics work'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Each tile opens a live feed: publishers filter by news site, '
              'Technology runs a keyword search. Follow marks it as yours.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic live feed: used by topic tiles AND article tag chips.
class FeedScreen extends StatefulWidget {
  final String title;
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final FollowedSources followed;
  final void Function(Article) onOpen;
  final Future<List<Article>> Function(int limit) fetch;
  const FeedScreen({
    super.key,
    required this.title,
    required this.api,
    required this.bookmarks,
    required this.followed,
    required this.onOpen,
    required this.fetch,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetch(12);
  }

  void _retry() => setState(() => _future = widget.fetch(12));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ListenableBuilder(
            listenable: widget.followed,
            builder: (_, _) => TextButton(
              onPressed: () => widget.followed.toggle(widget.title),
              child: Text(
                widget.followed.isFollowed(widget.title)
                    ? 'Following'
                    : 'Follow',
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(child: LoadingList());
          }
          if (snap.hasError) {
            return StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Couldn\'t load ${widget.title}',
              subtitle: '${snap.error}',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }
          final items = snap.data ?? const <Article>[];
          if (items.isEmpty) {
            return const StateMessage(
              icon: Icons.newspaper_outlined,
              title: 'No stories',
              subtitle: 'Try another topic.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => ListenableBuilder(
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
          );
        },
      ),
    );
  }
}
