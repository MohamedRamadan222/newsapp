import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// 1x1 transparent PNG — stands in for every network image in tests.
final Uint8List kStubPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Intercepts dart:io image requests so Image.network works in tests.
class StubImageOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _StubHttpClient();
}

class _StubHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _StubRequest();
}

class _StubRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _StubHeaders();

  @override
  Future<HttpClientResponse> close() async => _StubResponse();
}

class _StubHeaders extends Fake implements HttpHeaders {}

class _StubResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => kStubPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kStubPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

Map<String, dynamic> _article(
  int id,
  String site,
  String title,
  String day,
) {
  return {
    'id': id,
    'title': title,
    'summary':
        'After reviewing the flight schedule, $site and its partners are '
        'adjusting launch opportunities for upcoming missions while teams '
        'complete vehicle checks and balance cargo deliveries.',
    'image_url': 'https://picsum.photos/seed/preview$id/800/450',
    'news_site': site,
    'published_at': '2026-0${(id % 9) + 1}-${day}T14:30:00Z',
    'url': 'https://example.com/articles/$id',
  };
}

final List<Map<String, dynamic>> kCannedArticles = [
  _article(1, 'NASA', 'NASA adjusts ISS flight schedule for upcoming missions', '15'),
  _article(2, 'SpaceX', 'Starship completes key test ahead of next launch attempt', '14'),
  _article(3, 'ESA', 'Webb telescope spots distant galaxy in stunning detail', '13'),
  _article(4, 'NASA', 'Artemis crew trains for historic Moon return mission', '12'),
  _article(5, 'Rocket Lab', 'Smallsats launch to boost climate monitoring network', '11'),
  _article(6, 'SpaceX', 'Moon lander design passes review for future missions', '10'),
  _article(7, 'ESA', 'Lunar base concept moves closer with new habitat tests', '09'),
  _article(8, 'Blue Origin', 'Crewed capsule wraps up final safety rehearsal', '08'),
];

/// Mock of Spaceflight News API v4: list filters + single-article fetch.
MockClient buildMockApiClient() {
  return MockClient((http.Request request) async {
    final seg = request.url.pathSegments;
    // GET /v4/articles/{id}/
    if (seg.length >= 3 && int.tryParse(seg[2]) != null) {
      final id = int.parse(seg[2]);
      final found = kCannedArticles.where((a) => a['id'] == id).toList();
      if (found.isEmpty) return http.Response('{"detail":"Not found."}', 404);
      return http.Response(jsonEncode(found.first), 200);
    }
    // GET /v4/articles/?limit=&offset=&search=&news_site=
    final q = request.url.queryParameters;
    var items = List.of(kCannedArticles);
    final site = q['news_site'];
    if (site != null && site.isNotEmpty) {
      items = items.where((a) => a['news_site'] == site).toList();
    }
    final search = q['search'];
    if (search != null && search.isNotEmpty) {
      final term = search.toLowerCase();
      items = items
          .where(
            (a) =>
                (a['title'] as String).toLowerCase().contains(term) ||
                (a['summary'] as String).toLowerCase().contains(term),
          )
          .toList();
    }
    final limit = int.tryParse(q['limit'] ?? '') ?? 10;
    final offset = int.tryParse(q['offset'] ?? '') ?? 0;
    final page = items.skip(offset).take(limit).toList();
    return http.Response(
      jsonEncode({'count': items.length, 'results': page}),
      200,
    );
  });
}

/// Renders tests at phone size (390x844 @3x) for store-ready screenshots.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}
