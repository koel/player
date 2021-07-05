import 'package:app/models/song.dart';
import 'package:app/utils/api_request.dart';

class Track {
  String title;
  int length;

  Track({required this.title, required this.length});

  factory Track.fromJson(json) {
    return Track(
      title: json['title'],
      length: json['length'],
    );
  }
}

class AlbumInfo {
  String information;
  List<Track> tracks;

  AlbumInfo({required this.information, required this.tracks});

  factory AlbumInfo.fromJson(json) {
    List<Track> tracks = (json['tracks'] as List<dynamic>)
        .map((json) => Track.fromJson(json))
        .toList();

    return AlbumInfo(
      information: json['wiki']['full'],
      tracks: tracks,
    );
  }
}

class ArtistInfo {
  String biography;

  ArtistInfo({required this.biography});

  factory ArtistInfo.fromJson(json) {
    return ArtistInfo(biography: json['bio']['full']);
  }
}

class MediaInfo {
  final String lyrics;
  final AlbumInfo? albumInfo;
  final ArtistInfo? artistInfo;

  MediaInfo({required this.lyrics, this.albumInfo, this.artistInfo});

  factory MediaInfo.fromJson(json) {
    return MediaInfo(
      lyrics: json['lyrics'],
      albumInfo: json['album_info'] == null
          ? null
          : AlbumInfo.fromJson(json['album_info']),
      artistInfo: json['artist_info'] == null
          ? null
          : ArtistInfo.fromJson(json['artist_info']),
    );
  }
}

class MediaInfoProvider {
  Map<String, MediaInfo> _cache = {};

  Future<MediaInfo> fetch({required Song song}) async {
    if (!_cache.containsKey(song.id)) {
      _cache[song.id] = MediaInfo.fromJson(await get('song/${song.id}/info'));
    }

    return _cache[song.id]!;
  }
}
