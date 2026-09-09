import 'package:flutter/material.dart';

import '../models/article.dart';
import '../theme/app_theme.dart';

/// Small uppercase pill. Mirrors `.badge` in the HTML design.
class NewsBadge extends StatelessWidget {
  final String label;
  const NewsBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// "NASA • 2h ago • 5 min read". Mirrors `.meta`.
class MetaRow extends StatelessWidget {
  final Article article;
  final bool light;
  const MetaRow(this.article, {super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: light ? Colors.white70 : AppTheme.muted);
    return Text(
      '${article.source}  •  ${article.timeAgo()}  •  '
      '${article.readMinutes} min read',
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Network image with neutral fallback. Keeps cards stable offline.
class ArticleImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  const ArticleImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(Icons.image_outlined, color: AppTheme.faint, size: 20)
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_outlined,
                color: AppTheme.faint,
                size: 20,
              ),
            ),
    );
  }
}

/// Featured story. Mirrors `.hero-card`.
class HeroCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final String badge;
  const HeroCard({
    super.key,
    required this.article,
    required this.onTap,
    this.badge = 'Breaking',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ArticleImage(url: article.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NewsBadge(badge),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    MetaRow(article, light: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroller item. Mirrors `.trend-card`.
class TrendCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const TrendCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArticleImage(url: article.imageUrl, height: 128),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetaRow(article),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical list row. Mirrors `.news-card`.
class NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback onSave;
  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArticleImage(
                url: article.imageUrl,
                width: 88,
                height: 88,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetaRow(article),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${article.readMinutes} min read',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            onPressed: onSave,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_border,
                              size: 20,
                              color: saved ? AppTheme.text : AppTheme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
