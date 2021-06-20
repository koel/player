import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/utils/preferences.dart';
import 'package:audio_service/audio_service.dart';
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

  MediaItem? _mediaItem;
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

  Future<MediaItem> asMediaItem() async {
    if (_mediaItem == null) {
      Map<String, dynamic> extras = new Map();
      extras['songId'] = id;

      _mediaItem = MediaItem(
        id: (await getSourceUrl())!,
        album: album.name,
        artist: artist.name,
        title: title,
        artUri: Uri.parse((image as NetworkImage).url),
        extras: extras,
      );
    }

    return _mediaItem!;
  }

  Future<String?> getSourceUrl() async {
    if (_sourceUrl == null) {
      Preferences prefs = Preferences();
      String? hostUrl = await prefs.getHostUrl();
      String? token = await prefs.getApiToken();
      _sourceUrl = "$hostUrl/play/$id?api_token=$token";
    }

    return _sourceUrl;
  }
}
