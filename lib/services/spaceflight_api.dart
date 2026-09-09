import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/article.dart';

/// Thin client for Spaceflight News API v4 (no key required).
/// Docs: https://api.spaceflightnewsapi.net/v4/docs/
class SpaceflightApi {
  SpaceflightApi({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'api.spaceflightnewsapi.net';
  static const _basePath = '/v4/articles/';

  final http.Client _client;

  Future<List<Article>> latest({int limit = 10, int offset = 0}) {
    return _fetch(query: {'limit': '$limit', 'offset': '$offset'});
  }

  Future<List<Article>> bySite(String site, {int limit = 10}) {
    return _fetch(query: {'limit': '$limit', 'news_site': site});
  }

  Future<List<Article>> search(String term, {int limit = 10}) {
    return _fetch(query: {'limit': '$limit', 'search': term});
  }

  Future<Article> detail(int id) async {
    final uri = Uri.https(_host, '$_basePath$id/');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    _throwIfBad(res);
    return Article.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Article>> _fetch({required Map<String, String> query}) async {
    final uri = Uri.https(_host, _basePath, query);
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      _throwIfBad(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (body['results'] as List? ?? const []);
      return results
          .whereType<Map<String, dynamic>>()
          .map(Article.fromJson)
          .where((a) => a.title.isNotEmpty)
          .toList();
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on SocketException {
      throw const ApiException('No internet connection.');
    }
  }

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException('Server error (${res.statusCode}). Try again.');
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
