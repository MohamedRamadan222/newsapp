import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'services/bookmarks_store.dart';
import 'services/followed_sources.dart';
import 'services/spaceflight_api.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bookmarks = await BookmarksStore.load();
  final followed = await FollowedSources.load();
  runApp(NewsApp(bookmarks: bookmarks, followed: followed));
}

class NewsApp extends StatefulWidget {
  final BookmarksStore bookmarks;
  final FollowedSources followed;
  const NewsApp({super.key, required this.bookmarks, required this.followed});

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  late final SpaceflightApi _api = SpaceflightApi();

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AppShell(
        api: _api,
        bookmarks: widget.bookmarks,
        followed: widget.followed,
      ),
    );
  }
}
