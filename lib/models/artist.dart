import 'package:app/constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:ulid/ulid.dart';

class Artist {
  dynamic id;
  String name;
  String? imageUrl;
  int playCount = 0;
  ImageProvider? _image;

  /// Whether the current user is allowed to edit this artist.
  /// Sourced from the koel >= 9.2.0 `permissions.edit` flag on the JSON
  /// resource. Defaults to `false` when the server didn't include
  /// permissions (older koel) so the UI hides the action.
  bool canEdit;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.canEdit = false,
  });

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

  bool get isStandardArtist => !isUnknownArtist && !isVariousArtists;

  bool get isUnknownArtist => name == 'Unknown Artist';

  bool get isVariousArtists => name == 'Various Artists';

  factory Artist.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];

    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'],
      canEdit: permissions is Map ? permissions['edit'] == true : false,
    );
  }

  factory Artist.fake({
    dynamic id,
    String? name,
    String? imageUrl,
    int? playCount,
    bool canEdit = false,
  }) {
    Faker faker = Faker();

    return Artist(
      id: id ?? Ulid().toString(),
      name: name ?? faker.person.name(),
      imageUrl: imageUrl ?? faker.image.loremPicsum(width: 192, height: 192),
      canEdit: canEdit,
    )..playCount = playCount ?? faker.randomGenerator.integer(1000);
  }

  Artist merge(Artist remote) {
    this
      ..imageUrl = remote.imageUrl
      ..playCount = remote.playCount ?? 0
      ..name = remote.name
      ..canEdit = remote.canEdit;

    _image = null;

    return this;
  }
}
