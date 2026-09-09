import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

/// Persisted reading list. Mirrors the static Saved page in the HTML design.
/// Stored as `article_<id> -> Article JSON` so it survives restarts.
class BookmarksStore extends ChangeNotifier {
  BookmarksStore._(this._prefs);

  final SharedPreferences _prefs;
  final Map<int, Article> _items = {};

  static const _prefix = 'article_';

  static Future<BookmarksStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = BookmarksStore._(prefs);
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final article = Article.tryDecode(raw);
      if (article != null) store._items[article.id] = article;
    }
    return store;
  }

  List<Article> get items {
    final list = _items.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return List.unmodifiable(list);
  }

  bool isSaved(int id) => _items.containsKey(id);

  Future<void> toggle(Article article) async {
    if (_items.containsKey(article.id)) {
      _items.remove(article.id);
      await _prefs.remove('$_prefix${article.id}');
    } else {
      _items[article.id] = article;
      await _prefs.setString('$_prefix${article.id}', article.encode());
    }
    notifyListeners();
  }

  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    _items.clear();
    notifyListeners();
  }
}
