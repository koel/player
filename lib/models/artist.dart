import 'package:app/constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

class Artist {
  int id;
  String name;
  String? imageUrl;
  int playCount = 0;
  ImageProvider? _image;

  Artist({required this.id, required this.name, required this.imageUrl});

  ImageProvider get image {
    var image = _image;
    final imageUrl = this.imageUrl;

    if (image == null) {
      _image = image = imageUrl == null
          ? AppImages.defaultImage.image
          : CachedNetworkImageProvider(imageUrl);
    }

    return image;
  }

  bool get isStandardArtist => !isUnknownArtist && !isVariousArtist;

  bool get isUnknownArtist => id == 1;

  bool get isVariousArtist => id == 2;

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'],
    );
  }

  factory Artist.fake({
    int? id,
    String? name,
    String? imageUrl,
    int? playCount,
  }) {
    Faker faker = Faker();

    return Artist(
      id: id ?? faker.randomGenerator.integer(1000, min: 1),
      name: name ?? faker.person.name(),
      imageUrl: imageUrl ?? faker.image.image(width: 192, height: 192),
    )..playCount = playCount ?? faker.randomGenerator.integer(1000);
  }

  Artist merge(Artist remote) {
    this
      ..imageUrl = remote.imageUrl
      ..playCount = remote.playCount ?? 0
      ..name = remote.name;

    _image = null;

    return this;
  }
}
