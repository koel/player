import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/values/values.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Song extends Playable<Song> {
  late Album album;
  late Artist artist;
  String id;
  num length;
  String title;
  String lyrics;
  dynamic albumId;
  String albumName;
  dynamic artistId;
  String artistName;
  dynamic albumArtistId;
  String albumArtistName;
  String? albumCoverUrl;
  num track;
  num disc;
  num? year;
  String genre;
  bool liked = false;
  int playCount = 0;
  DateTime createdAt;

  ImageProvider? _cachedImage;

  var _cachedSourceUrl;

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

  @override
  ImageProvider get image {
    var image = _cachedImage;
    final albumCoverUrl = this.albumCoverUrl;

    if (image == null) {
      image = albumCoverUrl == null
          ? AppImages.defaultImage.image
          : CachedNetworkImageProvider(albumCoverUrl);
    }

    return image;
  }

  @override
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
      extras: {
        'sourceUrl': sourceUrl,
        'type': 'song',
      },
    );
  }

  @override
  String get sourceUrl {
    var src = _cachedSourceUrl;

    if (src == null) {
      String rawUrl = AppState.get(['app', 'transcoding'], false)!
          ? '$host/play/$id/1/128?t=${preferences.audioToken}'
          : '$host/play/$id?t=${preferences.audioToken}';

      _cachedSourceUrl = src = Uri.encodeFull(rawUrl);
    }

    return src;
  }

  @override
  Song merge(Song other) {
    this
      ..liked = other.liked
      ..title = other.title
      ..lyrics = other.lyrics
      ..length = other.length
      ..albumCoverUrl = other.albumCoverUrl
      ..playCount = other.playCount
      ..artistName = other.artistName
      ..albumName = other.albumName
      ..artistId = other.artistId
      ..albumId = other.albumId
      ..albumArtistId = other.albumArtistId
      ..albumArtistName = other.albumArtistName
      ..disc = other.disc
      ..track = other.track
      ..genre = other.genre
      ..year = other.year;

    _cachedImage = null;

    return this;
  }

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

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'songs',
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

  @override
  bool matchKeywords(String keywords) {
    return title.toLowerCase().contains(keywords) ||
        artistName.toLowerCase().contains(keywords) ||
        albumName.toLowerCase().contains(keywords);
  }

  @override
  Comparable valueToCompare(PlayableSortConfig config) {
    switch (config.field) {
      case 'title':
        return title;
      case 'album_name':
        return '${albumName}${albumId}${track}';
      case 'artist_name':
        return '${artistName}${albumName}${track}';
      case 'created_at':
        return createdAt;
      case 'track':
        return track;
      default:
        return '';
    }
  }
}
