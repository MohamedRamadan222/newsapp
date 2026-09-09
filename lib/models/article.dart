import 'dart:convert';

/// News article shaped by Spaceflight News API v4.
/// Docs: https://api.spaceflightnewsapi.net/v4/docs/
class Article {
  final int id;
  final String title;
  final String summary;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;
  final String url;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      imageUrl: (json['image_url'] as String? ?? '').trim(),
      source: (json['news_site'] as String? ?? 'Space').trim(),
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      url: (json['url'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'image_url': imageUrl,
    'news_site': source,
    'published_at': publishedAt.toIso8601String(),
    'url': url,
  };

  String encode() => jsonEncode(toJson());

  static Article? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Article.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Rough reading time from summary length (min 2 min).
  int get readMinutes {
    final words = summary.isEmpty ? 120 : summary.split(RegExp(r'\s+')).length;
    return (words / 180).ceil().clamp(2, 12);
  }

  /// Short "2h ago / 3d ago" label. Maps to `.meta` in the HTML design.
  String timeAgo({DateTime? now}) {    final diff = (now ?? DateTime.now().toUtc()).difference(
      publishedAt.toUtc(),
    );
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays.clamp(1, 365)}d ago';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Apr 15, 2026" label for card footers.
  String get dateLabel {
    final d = publishedAt.toLocal();
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
