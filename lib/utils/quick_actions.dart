import 'dart:async';

import 'package:quick_actions/quick_actions.dart';

/// Wraps the home-screen quick actions (long-press the app icon) and relays
/// them to the app. Actions received before a listener is ready (e.g. a cold
/// launch opened via a shortcut) are buffered and consumed once the app is up.
class KoelQuickActions {
  static const search = 'koel_action_search';
  static const playFavorites = 'koel_action_play_favorites';
  static const playDownloaded = 'koel_action_play_downloaded';
  static const playRecent = 'koel_action_play_recent';

  final QuickActions _quickActions;
  final _actions = StreamController<String>.broadcast();
  final _searchFocusRequests = StreamController<void>.broadcast();

  String? _pendingAction;
  var _searchFocusPending = false;

  KoelQuickActions({QuickActions quickActions = const QuickActions()})
      : _quickActions = quickActions;

  /// Emits a shortcut type each time the user triggers a quick action while the
  /// app is running.
  Stream<String> get actions => _actions.stream;

  /// Emits whenever the Search field should grab focus.
  Stream<void> get searchFocusRequests => _searchFocusRequests.stream;

  void initialize() {
    _quickActions.initialize((type) {
      _pendingAction = type;
      _actions.add(type);
    });
  }

  /// Returns and clears an action received before a listener attached (a cold
  /// launch via a shortcut), or null if there was none.
  String? consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  void requestSearchFocus() {
    _searchFocusPending = true;
    _searchFocusRequests.add(null);
  }

  /// True once if a focus request arrived before the Search screen was built.
  bool consumePendingSearchFocus() {
    final pending = _searchFocusPending;
    _searchFocusPending = false;
    return pending;
  }

  Future<void> setShortcuts({String? recentSubtitle}) {
    return _quickActions
        .setShortcutItems(shortcutItems(recentSubtitle: recentSubtitle));
  }

  /// The shortcut items to expose. "Play Most Recent" is only offered when
  /// there is a recent track to describe.
  static List<ShortcutItem> shortcutItems({String? recentSubtitle}) {
    return [
      const ShortcutItem(type: search, localizedTitle: 'Search'),
      const ShortcutItem(
        type: playFavorites,
        localizedTitle: 'Play Favorite Songs',
      ),
      const ShortcutItem(
        type: playDownloaded,
        localizedTitle: 'Play Downloaded',
      ),
      if (recentSubtitle != null && recentSubtitle.isNotEmpty)
        ShortcutItem(
          type: playRecent,
          localizedTitle: 'Play Most Recent',
          localizedSubtitle: recentSubtitle,
        ),
    ];
  }

  /// Formats a "Artist - Title" label for the most-recent track, or just the
  /// title when there's no artist.
  static String? recentSubtitle({String? artist, String? title}) {
    if (title == null || title.isEmpty) return null;
    return (artist == null || artist.isEmpty) ? title : '$artist - $title';
  }

  void dispose() {
    _actions.close();
    _searchFocusRequests.close();
  }
}
