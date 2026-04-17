import 'dart:convert';

import 'package:app/models/models.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart';

class RouteEntry {
  final String name;
  final dynamic argument;

  const RouteEntry({required this.name, this.argument});

  Map<String, dynamic> toJson() => {
        'name': name,
        'argument': _serializeArgument(),
      };

  factory RouteEntry.fromJson(Map<String, dynamic> json) {
    return RouteEntry(
      name: json['name'],
      argument: _deserializeArgument(json['name'], json['argument']),
    );
  }

  dynamic _serializeArgument() {
    if (argument == null) return null;
    if (argument is Playlist) return (argument as Playlist).toJson();
    if (argument is Genre) return (argument as Genre).toJson();
    return argument; // IDs (String, int) are already serializable
  }

  static dynamic _deserializeArgument(String routeName, dynamic data) {
    if (data == null) return null;

    switch (routeName) {
      case PlaylistDetailsScreen.routeName:
        return Playlist.fromJson(Map<String, dynamic>.from(data));
      case GenreDetailsScreen.routeName:
        return Genre.fromJson(Map<String, dynamic>.from(data));
      default:
        return data; // IDs
    }
  }

  Widget? buildScreen() {
    switch (name) {
      case SongsScreen.routeName:
        return const SongsScreen();
      case FavoritesScreen.routeName:
        return const FavoritesScreen();
      case PlaylistsScreen.routeName:
        return const PlaylistsScreen();
      case ArtistsScreen.routeName:
        return const ArtistsScreen();
      case AlbumsScreen.routeName:
        return const AlbumsScreen();
      case GenresScreen.routeName:
        return const GenresScreen();
      case PodcastsScreen.routeName:
        return const PodcastsScreen();
      case RadioStationsScreen.routeName:
        return const RadioStationsScreen();
      case DownloadedScreen.routeName:
        return DownloadedScreen();
      case RecentlyPlayedScreen.routeName:
        return const RecentlyPlayedScreen();
      case AlbumDetailsScreen.routeName:
        return const AlbumDetailsScreen();
      case ArtistDetailsScreen.routeName:
        return const ArtistDetailsScreen();
      case PlaylistDetailsScreen.routeName:
        return const PlaylistDetailsScreen();
      case PodcastDetailsScreen.routeName:
        return const PodcastDetailsScreen();
      case GenreDetailsScreen.routeName:
        return const GenreDetailsScreen();
      default:
        return null;
    }
  }
}

class RouteStateObserver extends NavigatorObserver {
  final int tabIndex;

  RouteStateObserver({required this.tabIndex});

  bool _isTracked(Route? route) =>
      route?.settings.name != null && route!.settings.name != '/';

  @override
  void didPush(Route route, Route? previousRoute) {
    if (_isTracked(route)) {
      RouteState.addEntry(
        tabIndex,
        RouteEntry(name: route.settings.name!, argument: route.settings.arguments),
      );
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (!_isTracked(route)) return;
    final stack = RouteState.stackFor(tabIndex);
    if (stack.isNotEmpty && stack.last.name == route.settings.name) {
      RouteState.removeLastEntry(tabIndex);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (_isTracked(oldRoute)) {
      RouteState.removeLastEntry(tabIndex);
    }
    if (_isTracked(newRoute)) {
      RouteState.addEntry(
        tabIndex,
        RouteEntry(
          name: newRoute!.settings.name!,
          argument: newRoute.settings.arguments,
        ),
      );
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (!_isTracked(route)) return;
    RouteState.removeEntryByName(tabIndex, route.settings.name!);
  }
}

class RouteState {
  static const _storageKey = 'routeState';
  static var _tabIndex = 0;
  static var _stacks = <int, List<RouteEntry>>{0: [], 1: [], 2: []};
  /// Set to false to disable storage persistence (e.g. in tests).
  static set persistEnabled(bool value) => _persistEnabled = value;
  static var _persistEnabled = true;

  static int get tabIndex => _tabIndex;
  static List<RouteEntry> stackFor(int tab) => _stacks[tab] ?? [];

  static void setTabIndex(int index) {
    _tabIndex = index;
    _persist();
  }

  static void addEntry(int tab, RouteEntry entry) {
    _stacks[tab] ??= [];
    _stacks[tab]!.add(entry);
    _persist();
  }

  static void removeLastEntry(int tab) {
    if (_stacks[tab] != null && _stacks[tab]!.isNotEmpty) {
      _stacks[tab]!.removeLast();
      _persist();
    }
  }

  static void removeEntryByName(int tab, String name) {
    if (_stacks[tab] == null) return;
    final idx = _stacks[tab]!.lastIndexWhere((e) => e.name == name);
    if (idx >= 0) {
      _stacks[tab]!.removeAt(idx);
      _persist();
    }
  }

  static void _persist() {
    if (!_persistEnabled) return;
    final data = {
      'tabIndex': _tabIndex,
      'stacks': _stacks.map(
        (tab, entries) => MapEntry(
          tab.toString(),
          entries.map((e) => e.toJson()).toList(),
        ),
      ),
    };
    preferences.storage.write(_storageKey, jsonEncode(data));
  }

  static void load() {
    if (!_persistEnabled) return;
    final raw = preferences.storage.read<String>(_storageKey);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _tabIndex = data['tabIndex'] ?? 0;

      final stacks = data['stacks'] as Map<String, dynamic>? ?? {};
      _stacks = {};
      for (final entry in stacks.entries) {
        final tab = int.parse(entry.key);
        _stacks[tab] = (entry.value as List)
            .map((e) => RouteEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      _tabIndex = 0;
      _stacks = {0: [], 1: [], 2: []};
    }
  }

  static void clear() {
    reset();
    if (_persistEnabled) {
      preferences.storage.remove(_storageKey);
    }
  }

  /// Resets in-memory state without touching storage.
  static void reset() {
    _tabIndex = 0;
    _stacks = {0: [], 1: [], 2: []};
  }
}
