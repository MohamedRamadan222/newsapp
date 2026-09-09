import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../services/bookmarks_store.dart';

/// Real device actions shared by every screen.
/// Failures always surface as a SnackBar — no dead buttons.
class ArticleActions {
  static Future<void> shareArticle(BuildContext context, Article a) async {
    final text = a.url.isEmpty ? a.title : '${a.title}\n${a.url}';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      if (context.mounted) {
        _note(context, 'Couldn\'t open share sheet.');
      }
    }
  }

  static Future<void> openArticle(BuildContext context, Article a) async {
    final uri = Uri.tryParse(a.url);
    if (uri == null || !uri.hasScheme) {
      _note(context, 'No publisher link for this story.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _note(context, 'Couldn\'t open the link.');
    } catch (_) {
      if (context.mounted) _note(context, 'Couldn\'t open the link.');
    }
  }

  static Future<void> toggleSave(
    BuildContext context,
    BookmarksStore store,
    Article a,
  ) async {
    final wasSaved = store.isSaved(a.id);
    await store.toggle(a);
    if (context.mounted) {
      _note(context, wasSaved ? 'Removed from Saved.' : 'Saved for later.');
    }
  }

  static void _note(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
