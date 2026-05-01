import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:ulid/ulid.dart';

class Album {
  dynamic id;
  String name;
  String? cover;
  dynamic artistId;
  String artistName;
  int? year;
  int playCount = 0;
  ImageProvider? _image;

  /// Whether the current user is allowed to edit this album.
  /// Sourced from the koel >= 9.2.0 `permissions.edit` flag on the
  /// JSON resource. Defaults to `false` when the server didn't include
  /// permissions (older koel) so the UI hides the action.
  bool canEdit;

  Album({
    required this.id,
    required this.name,
    required this.cover,
    required this.artistId,
    required this.artistName,
    this.year,
    this.canEdit = false,
  });

  ImageProvider get image {
    var image = _image;
    final cover = this.cover;

    if (image == null) {
      _image = image = cover == null
          ? AppImages.defaultImage.image
          : CachedNetworkImageProvider(cover);
    }

    return image;
  }

  bool get isStandardAlbum => !isUnknownAlbum;

  bool get isUnknownAlbum => name == 'Unknown Album';

  factory Album.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];

    return Album(
      id: json['id'],
      name: json['name'],
      cover: json['cover'],
      artistId: json['artist_id'],
      artistName: json['artist_name'],
      year: json['year'] == null ? null : int.parse(json['year'].toString()),
      canEdit: permissions is Map ? permissions['edit'] == true : false,
    );
  }

  factory Album.fake({
    dynamic id,
    String? name,
    String? cover,
    int? playCount,
    Artist? artist,
    bool canEdit = false,
  }) {
    Faker faker = Faker();

    artist ??= Artist.fake();

    return Album(
      id: id ?? Ulid().toString(),
      name: name ?? faker.lorem.words(3).join(' '),
      cover: cover ?? faker.image.loremPicsum(width: 192, height: 192),
      artistId: artist.id,
      artistName: artist.name,
      canEdit: canEdit,
    )..playCount = playCount ?? faker.randomGenerator.integer(1000);
  }

  Album merge(Album remote) {
    this
      ..artistName = remote.artistName
      ..artistId = remote.artistId
      ..cover = remote.cover
      ..name = remote.name
      ..year = remote.year
      ..playCount = remote.playCount ?? 0
      ..canEdit = remote.canEdit;

    _image = null;

    return this;
  }
}
