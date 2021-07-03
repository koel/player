import 'package:app/models/artist.dart';
import 'package:flutter/material.dart';

class Album {
  int id;
  bool isCompilation;
  String name;
  String? cover;
  int artistId;
  late Artist artist;
  int playCount = 0;

  ImageProvider? _image;

  Album({
    required this.id,
    required this.name,
    required this.cover,
    required this.isCompilation,
    required this.artistId,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      cover: json['cover'],
      isCompilation: json['is_compilation'],
      artistId: json['artist_id'],
    );
  }

  ImageProvider get image {
    if (_image == null) {
      _image = cover == null ? artist.image : NetworkImage(this.cover!);
    }

    return _image!;
  }

  bool get isStandardAlbum => !isUnknownAlbum;

  bool get isUnknownAlbum => id == 1;
}
