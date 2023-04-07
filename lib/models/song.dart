import 'package:app/exceptions/unsupported_type_exception.dart';
import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/utils/crypto.dart';
import 'package:app/utils/preferences.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:uuid/uuid.dart';

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

  ImageProvider get image => album.image;

  String get sourceUrl {
    if (_sourceUrl == null) {
      _sourceUrl = Uri.encodeFull('$hostUrl/play/$id?api_token=$apiToken');
    }

    return _sourceUrl!;
  }

  String? get imageUrl => album.cover ?? artist.imageUrl;

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

  bool get hasCustomImage {
    return image is CachedNetworkImageProvider &&
        !(image as CachedNetworkImageProvider).url.endsWith(
              '/unknown-album.png',
            );
  }

  String get cacheKey => 'CACHE_$id';

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;

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

  factory Song.fake({
    String? id,
    String? title,
    int? length,
    int? track,
    DateTime? createdAt,
    bool? liked,
    int? playCount,
    Artist? artist,
    Album? album,
  }) {
    Faker faker = Faker();

    artist ??= Artist.fake();
    album ??= Album.fake(artist: artist);

    return Song(
      id: id ?? md5(Uuid().v4()),
      // silly, but we need the md5 format
      title: title ?? faker.lorem.sentence(),
      length: faker.randomGenerator.integer(300, min: 60),
      track: faker.randomGenerator.integer(20),
      createdAt: faker.date.dateTime(),
      artistId: artist.id,
      albumId: album.id,
    )
      ..artist = artist
      ..album = album
      ..liked = liked ?? faker.randomGenerator.boolean()
      ..playCount = playCount ?? faker.randomGenerator.integer(1000);
  }

  static List<Song> fakeMany(
    int count, {
    String? title,
    int? length,
    int? track,
    DateTime? createdAt,
    bool? liked,
    int? playCount,
    Artist? artist,
    Album? album,
  }) {
    assert(count > 1);
    List<Song> songs = [];

    for (int i = 0; i < count; ++i) {
      songs.add(
        Song.fake(
          title: title,
          length: length,
          track: track,
          createdAt: createdAt,
          liked: liked,
          playCount: playCount,
          artist: artist,
          album: album,
        ),
      );
    }

    return songs;
  }
}
