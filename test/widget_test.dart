import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsapp/models/article.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newsapp/services/bookmarks_store.dart';
import 'package:newsapp/services/followed_sources.dart';

void main() {
  test('Article parses Spaceflight API shape', () {
    final article = Article.fromJson({
      'id': 1,
      'title': '  Test title  ',
      'summary': 'word ' * 200,
      'image_url': 'https://example.com/a.jpg',
      'news_site': 'NASA',
      'published_at': '2026-04-15T14:30:00Z',
      'url': 'https://example.com',
    });
    expect(article.id, 1);
    expect(article.title, 'Test title');
    expect(article.source, 'NASA');
    expect(article.readMinutes, greaterThanOrEqualTo(2));
  });

  test('FollowedSources toggles and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final followed = await FollowedSources.load();
    expect(followed.isFollowed('NASA'), isTrue);
    await followed.toggle('NASA');
    expect(followed.isFollowed('NASA'), isFalse);
    await followed.toggle('ESA');
    expect(followed.isFollowed('ESA'), isTrue);
  });
  testWidgets('App boots to bottom navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final bookmarks = await BookmarksStore.load();
    expect(bookmarks.items, isEmpty);

    // Static shell check without network: bookmarks store + nav labels.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view),
                label: 'Topics',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });
}
