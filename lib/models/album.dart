import 'package:flutter/material.dart';

import 'artist.dart';

class Album {
  int id;
  bool isCompilation;
  String name;
  String? cover;
  int artistId;
  late Artist artist;
  int playCount = 0;

  ImageProvider? _image;

  Album(this.id, this.name, this.cover, this.isCompilation, this.artistId);

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      json['id'],
      json['name'],
      json['cover'],
      json['is_compilation'],
      json['artist_id'],
    );
  }

  ImageProvider get image {
    if (_image == null) {
      _image = cover == null ? artist.image : NetworkImage(this.cover!);
    }

    return _image!;
  }
}
