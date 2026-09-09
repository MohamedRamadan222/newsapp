import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/bookmarks_store.dart';
import '../widgets/article_cards.dart';
import '../widgets/common.dart';

/// Mirrors `design/bookmarks.html`.
/// ONE scrollable, cards in a plain [Column].
class SavedScreen extends StatelessWidget {
  final BookmarksStore bookmarks;
  final void Function(Article) onOpen;
  final VoidCallback onBrowse;
  const SavedScreen({
    super.key,
    required this.bookmarks,
    required this.onOpen,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bookmarks,
      builder: (context, _) {
        final items = bookmarks.items;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  items.isEmpty
                      ? 'Your reading list'
                      : 'Your reading list (${items.length})',
                  action: items.isEmpty ? null : 'Clear all',
                  onAction: items.isEmpty ? null : bookmarks.clear,
                ),
              ),
              if (items.isEmpty)
                StateMessage(
                  icon: Icons.bookmark_border,
                  title: 'Nothing saved yet',
                  subtitle: 'Tap the bookmark on any story to read it later.',
                  actionLabel: 'Browse news',
                  onAction: onBrowse,
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        NewsCard(
                          article: items[i],
                          onTap: () => onOpen(items[i]),
                          saved: true,
                          onSave: () => bookmarks.toggle(items[i]),
                        ),
                        if (i != items.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
