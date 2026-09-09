import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newsapp/models/article.dart';
import 'package:newsapp/screens/app_shell.dart';
import 'package:newsapp/services/bookmarks_store.dart';
import 'package:newsapp/services/followed_sources.dart';
import 'package:newsapp/services/spaceflight_api.dart';
import 'package:newsapp/theme/app_theme.dart';
import 'package:newsapp/widgets/article_cards.dart';

import 'preview_helper.dart';

/// Generates store screenshots: `flutter test --update-goldens
/// test/preview_test.dart`, then copies test/preview/*.png to screenshots/.
void main() {
  testWidgets('capture app previews', (tester) async {
    usePhoneSurface(tester);
    HttpOverrides.global = StubImageOverrides();
    addTearDown(() => HttpOverrides.global = null);
    SharedPreferences.setMockInitialValues({});

    final api = SpaceflightApi(client: buildMockApiClient());
    addTearDown(api.dispose);
    final bookmarks = await BookmarksStore.load();
    final followed = await FollowedSources.load();
    // Pre-seed one saved story so the Saved tab isn't empty.
    await bookmarks.toggle(Article.fromJson(kCannedArticles[1]));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: AppShell(api: api, bookmarks: bookmarks, followed: followed),
      ),
    );
    await tester.pumpAndSettle();

    // 1 — Home feed.
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/01-home.png'),
    );

    // 2 — Article details.
    final firstCard = find.byType(NewsCard).first;
    await tester.ensureVisible(firstCard);
    await tester.pumpAndSettle();
    await tester.tap(firstCard);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/02-article.png'),
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 3 — Search with live results.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'moon');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/03-search.png'),
    );

    // 4 — Saved list.
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/04-saved.png'),
    );

    // 5 — Topics grid.
    await tester.tap(find.text('Topics'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/05-topics.png'),
    );
  });
}
