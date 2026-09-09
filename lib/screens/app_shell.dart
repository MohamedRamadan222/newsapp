import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/bookmarks_store.dart';
import '../services/followed_sources.dart';
import '../services/spaceflight_api.dart';
import 'detail_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'topics_screen.dart';

/// Bottom-nav shell. Mirrors `.bottom-nav` in the HTML design.
/// Tabs: Home / Search / Saved / Topics.
class AppShell extends StatefulWidget {
  final SpaceflightApi api;
  final BookmarksStore bookmarks;
  final FollowedSources followed;
  final int initialIndex;
  final String searchQuery;
  const AppShell({
    super.key,
    required this.api,
    required this.bookmarks,
    required this.followed,
    this.initialIndex = 0,
    this.searchQuery = '',
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _open(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          api: widget.api,
          bookmarks: widget.bookmarks,
          followed: widget.followed,
          article: article,
          onOpen: _open,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        api: widget.api,
        bookmarks: widget.bookmarks,
        onOpen: _open,
        onSeeAll: (i) => setState(() => _index = i),
      ),
      SearchScreen(
        api: widget.api,
        bookmarks: widget.bookmarks,
        onOpen: _open,
        initialQuery: widget.searchQuery,
      ),
      SavedScreen(
        bookmarks: widget.bookmarks,
        onOpen: _open,
        onBrowse: () => setState(() => _index = 0),
      ),
      TopicsScreen(
        api: widget.api,
        bookmarks: widget.bookmarks,
        followed: widget.followed,
        onOpen: _open,
      ),
    ];
    const titles = ['NewsApp', 'Search', 'Saved', 'Topics'];
    const subtitles = [
      'Space & Tech Daily',
      'Find stories, topics, sources',
      'Your reading list',
      'Pick what you follow',
    ];

    return Scaffold(
      appBar: _index == 0
          ? AppBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Center(child: _Logo()),
              ),
              leadingWidth: 52,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[_index],
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitles[_index],
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () => setState(() => _index = 1),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 20),
                  onPressed: () => setState(() => _index = 2),
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Topics',
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'N',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF131315),
        ),
      ),
    );
  }
}
