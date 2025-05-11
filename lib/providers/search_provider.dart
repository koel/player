import 'package:app/app_state.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class SearchResult {
  var playables = <Playable>[];
  var artists = <Artist>[];
  var albums = <Album>[];
  var podcasts = <Podcast>[];

  SearchResult({
    this.playables = const [],
    this.artists = const [],
    this.albums = const [],
    this.podcasts = const [],
  });
}

class SearchProvider with ChangeNotifier {
  final PlayableProvider _playableProvider;
  final AlbumProvider _albumProvider;
  final ArtistProvider _artistProvider;

  SearchProvider({
    required playableProvider,
    required artistProvider,
    required albumProvider,
  })  : _playableProvider = playableProvider,
        _artistProvider = artistProvider,
        _albumProvider = albumProvider;

  Future<SearchResult> searchExcerpts({required String keywords}) async {
    final cacheKey = ['search.excerpts', keywords];
    if (AppState.has(cacheKey)) return AppState.get(cacheKey);

    final res = await get('search?q=$keywords');

    final playables = _playableProvider.syncWithVault(res['songs']
        .map<Playable>((j) => Playable.fromJson(j))
        .toList());
    final artists = _artistProvider.syncWithVault(
        res['artists'].map<Artist>((j) => Artist.fromJson(j)).toList());
    final albums = _albumProvider.syncWithVault(
        res['albums'].map<Album>((j) => Album.fromJson(j)).toList());

    // Since podcast feature is added later, we want to ensure backward compatibility
    final List<Podcast> podcasts = res['podcasts'] == null
        ? []
        : res['podcasts'].map<Podcast>((j) => Podcast.fromJson(j)).toList();

    return AppState.set(
      cacheKey,
      SearchResult(
        playables: playables,
        artists: artists,
        albums: albums,
        podcasts: podcasts,
      ),
    );
  }

  Future<List<Playable>> searchPlayables(String keywords) async {
    final cacheKey = ['search.playables', keywords];

    if (AppState.has(cacheKey)) return AppState.get(cacheKey);

    final res = await get('search/songs?q=$keywords');
    final songs = _playableProvider.syncWithVault(
      res.map<Playable>((j) => Playable.fromJson(j)).toList(),
    );

    return AppState.set(cacheKey, songs);
  }
}
