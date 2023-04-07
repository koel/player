import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Song {
  late Album album;
  late Artist artist;
  String id;
  num length;
  String title;
  String lyrics;
  int albumId;
  String albumName;
  int artistId;
  String artistName;
  int albumArtistId;
  String albumArtistName;
  String? albumCoverUrl;
  num track;
  num disc;
  num? year;
  String genre;
  bool liked = false;
  int playCount = 0;
  DateTime createdAt;

  String? _sourceUrl;
  ImageProvider? _image;

  bool playCountRegistered = false;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    required this.length,
    required this.albumId,
    required this.albumName,
    required this.albumCoverUrl,
    required this.artistId,
    required this.artistName,
    required this.albumArtistId,
    required this.albumArtistName,
    required this.track,
    required this.disc,
    required this.year,
    required this.genre,
    required this.liked,
    required this.createdAt,
  });

  ImageProvider get image {
    var image = _image;
    final albumCoverUrl = this.albumCoverUrl;

    if (image == null) {
      image = albumCoverUrl == null
          ? AppImages.defaultImage.image
          : CachedNetworkImageProvider(albumCoverUrl);
    }

    return image;
  }

  String get sourceUrl {
    var src = _sourceUrl;

    if (src == null) {
      var host = AppState.get(['app', 'cdnUrl'], preferences.host)!
          .replaceAll(RegExp(r'/$'), '');

      String rawUrl = AppState.get(['app', 'transcoding'], false)!
          ? '/play/$id/1/128?t=${preferences.audioToken}'
          : '$host/play/$id?t=${preferences.audioToken}';

      _sourceUrl = src = Uri.encodeFull(rawUrl);
    }

    return src;
  }

  Future<MediaItem> asMediaItem() async {
    final albumCoverUrl = this.albumCoverUrl;

    return MediaItem(
      id: id,
      album: albumName,
      title: title,
      artist: artistName,
      duration: Duration(seconds: length.toInt()),
      artUri: albumCoverUrl == null
          ? await AppImages.getDefaultArtUri()
          : Uri.parse(albumCoverUrl),
      genre: genre,
      extras: {'sourceUrl': sourceUrl},
    );
  }

  bool get hasCustomImage {
    return image is CachedNetworkImageProvider &&
        !(image as CachedNetworkImageProvider)
            .url
            .endsWith('/default-image.webp');
  }

  Song merge(Song target) {
    this
      ..liked = target.liked
      ..title = target.title
      ..lyrics = target.lyrics
      ..length = target.length
      ..albumCoverUrl = target.albumCoverUrl
      ..playCount = target.playCount
      ..artistName = target.artistName
      ..albumName = target.albumName
      ..artistId = target.artistId
      ..albumId = target.albumId
      ..albumArtistId = target.albumArtistId
      ..albumArtistName = target.albumArtistName
      ..disc = target.disc
      ..track = target.track
      ..genre = target.genre
      ..year = target.year;

    _image = null;

    return this;
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
      lyrics: json['lyrics'] ?? '',
      length: json['length'],
      track: json['track'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      artistId: json['artist_id'],
      artistName: json['artist_name'],
      albumId: json['album_id'],
      albumName: json['album_name'],
      albumCoverUrl: json['album_cover'],
      albumArtistId: json['album_artist_id'],
      albumArtistName: json['album_artist_name'],
      disc: json['disc'] ?? 1,
      year: json['year'] == null ? null : int.parse(json['year'].toString()),
      genre: json['genre'] ?? '',
      liked: json['liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lyrics': lyrics,
      'length': length,
      'track': track,
      'created_at': createdAt.toIso8601String(),
      'artist_id': artistId,
      'artist_name': artistName,
      'album_id': albumId,
      'album_name': albumName,
      'album_cover': albumCoverUrl,
      'album_artist_id': albumArtistId,
      'album_artist_name': albumArtistName,
      'disc': disc,
      'year': year,
      'genre': genre,
    };
  }

  factory Song.fake({
    String? id,
    String? title,
    String? lyrics,
    int? length,
    int? track,
    int? disc,
    String? genre,
    int? year,
    DateTime? createdAt,
    bool? liked,
    int? playCount,
    Artist? artist,
    Album? album,
    Artist? albumArtist,
  }) {
    Faker faker = Faker();

    artist ??= Artist.fake();
    album ??= Album.fake(artist: artist);
    albumArtist ??= artist;

    return Song(
      id: id ?? Uuid().v4(),
      title: title ?? faker.lorem.sentence(),
      lyrics: lyrics ?? faker.lorem.sentences(10).join(),
      length: faker.randomGenerator.integer(300, min: 60),
      track: faker.randomGenerator.integer(20),
      createdAt: faker.date.dateTime(),
      artistId: artist.id,
      albumId: album.id,
      albumArtistId: albumArtist.id,
      artistName: artist.name,
      albumName: album.name,
      albumArtistName: albumArtist.name,
      albumCoverUrl: album.cover,
      disc: disc ?? faker.randomGenerator.integer(3),
      year: year ?? faker.randomGenerator.integer(2020, min: 1950),
      genre: genre ??
          faker.randomGenerator.element(
            [
              'Rock',
              'Pop',
              'Jazz',
              '',
            ],
          ),
      liked: liked ?? faker.randomGenerator.boolean(),
    )
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
