import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Artist {
  int id;
  String name;
  String? imageUrl;
  int playCount = 0;
  ImageProvider? _image;

  Artist({required this.id, required this.name, required this.imageUrl});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'],
    );
  }

  ImageProvider get image {
    if (_image == null) {
      _image = imageUrl == null
          ? Image.asset(imageUrl!).image
          : CachedNetworkImageProvider(this.imageUrl!);
    }

    return _image!;
  }

  bool get isStandardArtist => !isUnknownArtist && !isVariousArtist;

  bool get isUnknownArtist => id == 1;

  bool get isVariousArtist => id == 2;
}
