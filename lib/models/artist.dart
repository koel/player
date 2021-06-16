import 'package:flutter/cupertino.dart';

class Artist {
  int id;
  String name;
  String? imageUrl;
  int playCount = 0;
  ImageProvider? _image;

  Artist(this.id, this.name, this.imageUrl);

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      json['id'],
      json['name'],
      json['image'],
    );
  }

  ImageProvider get image {
    if (_image == null) {
      _image = imageUrl == null
          ? AssetImage('assets/images/unknown-album.png')
          : NetworkImage(this.imageUrl!) as ImageProvider;
    }

    return _image!;
  }
}