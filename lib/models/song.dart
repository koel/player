import 'package:app/exceptions/unsupported_type_exception.dart';
import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/utils/preferences.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class Song {
  late Album album;
  late Artist artist;
  String id;
  num length;
  String title;
  num track;
  DateTime createdAt;
  int artistId;
  int albumId;
  bool liked = false;
  int playCount = 0;

  String? _sourceUrl;

  bool playCountRegistered = false;

  Song({
    required this.id,
    required this.title,
    required this.length,
    required this.track,
    required this.createdAt,
    required this.artistId,
    required this.albumId,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      length: json['length'],
      track: json['track'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      artistId: json['artist_id'],
      albumId: json['album_id'],
    );
  }

  ImageProvider get image => this.album.image;

  String get sourceUrl {
    if (_sourceUrl == null) {
      _sourceUrl = Uri.encodeFull(
        '$hostUrl/play/$id?api_token=$apiToken',
      );
    }

    return _sourceUrl!;
  }

  Future<Audio> asAudio() async {
    Metas metas = Metas(
      title: title,
      album: album.name,
      artist: artist.name,
      image: _metaImage,
      extra: {'songId': id},
    );

    FileInfo? cache = await DefaultCacheManager().getFileFromCache(cacheKey);

    return cache == null
        ? Audio.network(sourceUrl, metas: metas)
        : Audio.file(cache.file.path, metas: metas);
  }

  MetasImage get _metaImage {
    if (album.image is CachedNetworkImageProvider) {
      return MetasImage.network(
        (album.image as CachedNetworkImageProvider).url,
      );
    }

    if (album.image is AssetImage) {
      return MetasImage.asset((album.image as AssetImage).assetName);
    }

    throw UnsupportedTypeException.fromObject(album.image);
  }

  Future<FileInfo> cacheSourceFile() async {
    return DefaultCacheManager().downloadFile(
      sourceUrl,
      key: cacheKey,
      force: true,
    );
  }

  String get cacheKey => 'CACHE_$id';

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
