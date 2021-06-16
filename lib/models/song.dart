import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:flutter/material.dart';

class Song {
  Album album;
  Artist artist;
  String id;
  num length;
  String title;
  num track;
  DateTime createdAt;
  bool liked = false;
  int playCount = 0;

  Song(
    this.album,
    this.artist,
    this.id,
    this.title,
    this.length,
    this.track,
    this.createdAt,
  );

  factory Song.fromJson(Map<String, dynamic> json, Album album, Artist artist) {
    return Song(
      album,
      artist,
      json['id'],
      json['title'],
      json['length'],
      json['track'] ?? 0,
      DateTime.parse(json['created_at']),
    );
  }

  ImageProvider get image {
    return this.album.image;
  }
}
