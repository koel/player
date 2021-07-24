import 'package:app/models/artist.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
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

  ImageProvider get image {
    if (_image == null) {
      _image =
          cover == null ? artist.image : CachedNetworkImageProvider(cover!);
    }

    return _image!;
  }

  bool get isStandardAlbum => !isUnknownAlbum;

  bool get isUnknownAlbum => id == 1;

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      cover: json['cover'],
      isCompilation: json['is_compilation'],
      artistId: json['artist_id'],
    );
  }

  factory Album.fake({
    int? id,
    String? name,
    String? cover,
    bool? isCompilation,
    int? playCount,
    Artist? artist,
  }) {
    Faker faker = Faker();

    artist ??= Artist.fake();

    return Album(
      id: id ?? faker.randomGenerator.integer(1000, min: 1),
      name: name ?? faker.lorem.words(3).join(' '),
      cover: cover ?? faker.image.image(width: 192, height: 192),
      isCompilation: isCompilation ?? faker.randomGenerator.boolean(),
      artistId: artist.id,
    )
      ..artist = artist
      ..playCount = playCount ?? faker.randomGenerator.integer(1000);
  }
}
