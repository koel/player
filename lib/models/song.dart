import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/utils/preferences.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

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

  Audio? _audio;
  String? _sourceUrl;

  Song(
    this.id,
    this.title,
    this.length,
    this.track,
    this.createdAt,
    this.artistId,
    this.albumId,
  );

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      json['id'],
      json['title'],
      json['length'],
      json['track'] ?? 0,
      DateTime.parse(json['created_at']),
      json['artist_id'],
      json['album_id'],
    );
  }

  ImageProvider get image {
    return this.album.image;
  }

  Future<String> get sourceUrl async {
    if (_sourceUrl == null) {
      _sourceUrl = Uri.encodeFull(
        '${await hostUrl}/play/$id?api_token=${await apiToken}',
      );
    }

    return _sourceUrl!;
  }

  Future<Audio> asAudio() async {
    if (_audio == null) {
      _audio = Audio.network(
        await sourceUrl,
        metas: Metas(
          title: title,
          album: album.name,
          artist: artist.name,
          image: album.image is NetworkImage
              ? MetasImage.network((album.image as NetworkImage).url)
              : MetasImage.asset((album.image as AssetImage).assetName),
          extra: {'songId': id},
        ),
      );
    }

    return _audio!;
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
