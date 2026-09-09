import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted followed publishers/topics. Drives the Follow buttons in
/// article details and the Following labels on the Topics grid.
class FollowedSources extends ChangeNotifier {
  FollowedSources._(this._prefs, this._sites);

  final SharedPreferences _prefs;
  final Set<String> _sites;

  static const _key = 'followed_sites';

  static Future<FollowedSources> load() async {
    final prefs = await SharedPreferences.getInstance();
    return FollowedSources._(
      prefs,
      prefs.getStringList(_key)?.toSet() ?? {'NASA', 'SpaceX'},
    );
  }

  bool isFollowed(String site) => _sites.contains(site);

  Future<void> toggle(String site) async {
    if (_sites.contains(site)) {
      _sites.remove(site);
    } else {
      _sites.add(site);
    }
    await _prefs.setStringList(_key, _sites.toList());
    notifyListeners();
  }
}
