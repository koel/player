import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
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
}
