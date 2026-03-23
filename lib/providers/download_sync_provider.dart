import 'dart:async';

import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class DownloadSyncProvider with ChangeNotifier {
  final DownloadProvider _downloadProvider;
  final PlayableProvider _playableProvider;

  static const _syncDelay = Duration(minutes: 5);
  Timer? _timer;
  var _syncing = false;
  var _lastSyncResult = '';

  bool get syncing => _syncing;
  String get lastSyncResult => _lastSyncResult;

  DownloadSyncProvider({
    required DownloadProvider downloadProvider,
    required PlayableProvider playableProvider,
  })  : _downloadProvider = downloadProvider,
        _playableProvider = playableProvider;

  void scheduleSync() {
    _timer?.cancel();
    _timer = Timer(_syncDelay, _attemptSync);
  }

  Future<void> _attemptSync() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    await sync();
  }

  Future<void> sync() async {
    final downloads = _downloadProvider.playables;
    if (downloads.isEmpty || _syncing) return;

    _syncing = true;
    notifyListeners();

    try {
      final ids = downloads.map((p) => p.id).toList();

      final res = await post('songs/by-ids', data: {'ids': ids});
      final serverSongs = (res as List)
          .map<Playable>((json) => Playable.fromJson(json))
          .toList();

      final serverIds = serverSongs.map((s) => s.id).toSet();
      final localIds = ids.toSet();
      final deletedIds = localIds.difference(serverIds);

      var updatedCount = 0;
      var removedCount = 0;

      // Remove songs that no longer exist on the server
      for (final id in deletedIds) {
        final playable = downloads.firstWhere((p) => p.id == id);
        await _downloadProvider.removeForPlayable(playable);
        removedCount++;
      }

      // Update metadata for songs that still exist
      for (final serverSong in serverSongs) {
        final localPlayable = downloads.firstWhere(
          (p) => p.id == serverSong.id,
          orElse: () => serverSong,
        );

        if (localPlayable is Song && serverSong is Song) {
          if (_songNeedsUpdate(localPlayable, serverSong)) {
            localPlayable.merge(serverSong);
            updatedCount++;
          }
        }
      }

      // Persist updated metadata
      if (updatedCount > 0 || removedCount > 0) {
        _downloadProvider.persistMetadata();
        _playableProvider.syncWithVault(
          serverSongs.where((s) => serverIds.contains(s.id)).toList(),
        );
      }

      _lastSyncResult = 'Synced: $updatedCount updated, $removedCount removed';
    } catch (e) {
      _lastSyncResult = 'Sync failed: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  bool _songNeedsUpdate(Song local, Song server) {
    return local.title != server.title ||
        local.lyrics != server.lyrics ||
        local.artistName != server.artistName ||
        local.albumName != server.albumName ||
        local.albumCoverUrl != server.albumCoverUrl ||
        local.track != server.track ||
        local.disc != server.disc ||
        local.genre != server.genre ||
        local.year != server.year;
  }

  void dispose() {
    _timer?.cancel();
  }
}
